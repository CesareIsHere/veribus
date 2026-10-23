import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:veribus/services/location_service.dart';

/// A live device position that survives everything that can take it away: location service switched off, permission
/// denied or revoked, GPS errors. Turning the GPS on (or granting the permission) while the app is open brings the
/// position back by itself, with no restart.
///
/// It looks again when the platform says the service changed, when the app comes back to the foreground
/// ([start]), and every [recheckEvery]: no single missed event can leave it stuck.
class LocationTracker {
  LocationTracker(this._service, {this.recheckEvery = const Duration(seconds: 10)});

  final LocationService _service;
  final Duration recheckEvery;

  final _updates = StreamController<LatLng?>.broadcast();
  // Cancelled in _stopFixes.
  // ignore: cancel_subscriptions
  StreamSubscription<LatLng>? _fixes;
  StreamSubscription<bool>? _serviceEvents;
  Timer? _timer;
  LatLng? _last;
  var _hasValue = false;
  var _askedPermission = false;
  var _checking = false;
  var _again = false;
  var _paused = false;
  var _disposed = false;
  FollowNotice? _notice;
  var _inBackground = false;

  /// The latest position, or null while there is none (service off, permission denied). Replays the current value to
  /// each new listener, then follows the changes.
  Stream<LatLng?> get positions async* {
    if (_hasValue) yield _last;
    yield* _updates.stream;
  }

  /// Starts tracking, or resumes it after [pause]. Safe to call again.
  void start() {
    if (_disposed) return;
    _inBackground = false;
    _paused = false;
    if (_service.mock case final fixed?) {
      _emit(fixed);
      return;
    }
    _serviceEvents ??= _service.serviceEnabled().listen((_) => unawaited(check()), onError: (Object _) {});
    _timer ??= Timer.periodic(recheckEvery, (_) => unawaited(check()));
    unawaited(check());
  }

  /// Stops the GPS and the polling (app in the background); [start] brings them back.
  void pause() {
    _inBackground = true;
    // A followed journey goes on with the screen off: its foreground service is what keeps the app alive.
    if (_notice == null) _suspend();
  }

  void _suspend() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
    unawaited(_stopFixes());
  }

  /// Keeps the GPS in a foreground service with this persistent notification, or back to the plain fixes when null.
  /// The notification can only change by starting the fixes again, which is done here.
  Future<void> follow(FollowNotice? notice) async {
    if (_disposed || notice == _notice) return;
    _notice = notice;
    if (_service.mock != null) return;
    if (notice == null && _inBackground) {
      _suspend();
      return;
    }
    await _stopFixes();
    await check();
  }

  /// Looks at the service and the permission, and starts or stops the live fixes accordingly. [askPermission]: show the
  /// system dialog again if the permission is still undecided (it is asked once on its own, then only on request).
  Future<void> check({bool askPermission = false}) async {
    if (_disposed || _paused) return;
    if (_checking) {
      // A look is under way and may have decided before what changed: look once more when it ends.
      _again = true;
      return;
    }
    _checking = true;
    try {
      var access = await _service.access();
      if (access == LocationAccess.denied && (askPermission || !_askedPermission)) {
        _askedPermission = true;
        await _service.requestPermission();
        access = await _service.access();
      }
      if (_disposed || _paused) return;
      if (access != LocationAccess.granted) {
        await _stopFixes();
        _emit(null);
      } else if (_fixes == null) {
        await _startFixes();
      }
    } finally {
      _checking = false;
    }
    if (_again) {
      _again = false;
      await check();
    }
  }

  /// The "turn on location" button: fixes whatever is missing, then looks again.
  Future<void> enable() async {
    await _service.enable();
    await check(askPermission: true);
  }

  Future<void> _startFixes() async {
    // Paint at once from the last fix the OS knows; the live stream refines it.
    final last = await _service.lastKnown();
    if (_disposed || _paused) return;
    if (last != null) _emit(last);
    _fixes = _service
        .fixes(notice: _notice)
        .listen(
          _emit,
          // The platform gave up (service switched off between two events, GPS failure): the next look restarts it.
          onError: (Object _) => unawaited(_stopFixes()),
        );
  }

  Future<void> _stopFixes() async {
    final fixes = _fixes;
    _fixes = null;
    await fixes?.cancel();
  }

  void _emit(LatLng? position) {
    if (_disposed || (_hasValue && _last == position)) return;
    _hasValue = true;
    _last = position;
    _updates.add(position);
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    await _stopFixes();
    await _serviceEvents?.cancel();
    await _updates.close();
  }
}
