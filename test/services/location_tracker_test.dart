import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/services/location_service.dart';
import 'package:veribus/services/location_tracker.dart';

const _rome = LatLng(41.8986, 12.4768);
const _termini = LatLng(41.9009, 12.5016);

class _FakeLocationService extends Fake implements LocationService {
  LocationAccess accessNow = LocationAccess.granted;
  LocationAccess accessAfterRequest = LocationAccess.granted;
  int permissionRequests = 0;
  int fixesStarted = 0;
  int fixesCancelled = 0;
  LatLng? lastKnownFix;
  late StreamController<LatLng> fixController;
  final serviceEvents = StreamController<bool>.broadcast();

  @override
  LatLng? get mock => null;

  @override
  Future<LocationAccess> access() async => accessNow;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    accessNow = accessAfterRequest;
    return accessNow == LocationAccess.granted;
  }

  @override
  Future<LatLng?> lastKnown() async => lastKnownFix;

  @override
  Stream<LatLng> fixes() {
    fixesStarted++;
    fixController = StreamController<LatLng>(onCancel: () => fixesCancelled++);
    return fixController.stream;
  }

  @override
  Stream<bool> serviceEnabled() => serviceEvents.stream;
}

class _FixedPosition extends _FakeLocationService {
  @override
  LatLng? get mock => _termini;
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  late _FakeLocationService service;
  late LocationTracker tracker;
  late List<LatLng?> seen;
  late StreamSubscription<LatLng?> subscription;

  setUp(() {
    service = _FakeLocationService();
    // A fast re-check stands in for "every 10 s" without waiting.
    tracker = LocationTracker(service, recheckEvery: const Duration(milliseconds: 30));
    seen = [];
    subscription = tracker.positions.listen(seen.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await tracker.dispose();
  });

  test('emits the last known fix at once, then the live ones', () async {
    service.lastKnownFix = _rome;
    tracker.start();
    await _settle();
    service.fixController.add(_termini);
    await _settle();
    expect(seen, [_rome, _termini]);
  });

  test('GPS off at start, turned on later: the position comes back without restarting', () async {
    service.accessNow = LocationAccess.serviceOff;
    tracker.start();
    await _settle();
    expect(seen, [null]);
    expect(service.fixesStarted, 0);

    service.accessNow = LocationAccess.granted;
    service.serviceEvents.add(true);
    await _settle();
    service.fixController.add(_rome);
    await _settle();
    expect(seen, [null, _rome]);
  });

  test('GPS turned on without any platform event: the periodic look finds it', () async {
    service.accessNow = LocationAccess.serviceOff;
    tracker.start();
    await _settle();

    service.accessNow = LocationAccess.granted;
    await _settle();
    expect(service.fixesStarted, 1);
  });

  test('GPS turned off while tracking: the dot goes away, and returns when it is back on', () async {
    tracker.start();
    await _settle();
    service.fixController.add(_rome);
    await _settle();

    service.accessNow = LocationAccess.serviceOff;
    service.serviceEvents.add(false);
    await _settle();
    expect(seen, [_rome, null]);
    expect(service.fixesCancelled, 1);

    service.accessNow = LocationAccess.granted;
    service.serviceEvents.add(true);
    await _settle();
    service.fixController.add(_termini);
    await _settle();
    expect(seen, [_rome, null, _termini]);
  });

  test('permission is asked once on its own, and granted right away it starts tracking', () async {
    service
      ..accessNow = LocationAccess.denied
      ..accessAfterRequest = LocationAccess.granted;
    tracker.start();
    await _settle();
    expect(service.permissionRequests, 1);
    expect(service.fixesStarted, 1);
  });

  test('a denied permission is not asked again by the periodic look, only on request', () async {
    service
      ..accessNow = LocationAccess.denied
      ..accessAfterRequest = LocationAccess.denied;
    tracker.start();
    await _settle();
    await _settle();
    expect(service.permissionRequests, 1);
    expect(seen, [null]);

    await tracker.check(askPermission: true);
    expect(service.permissionRequests, 2);
  });

  test('a GPS error ends the stream, and the next look starts a new one', () async {
    tracker.start();
    await _settle();
    expect(service.fixesStarted, 1);

    service.fixController.addError(Exception('gps failure'));
    await _settle();
    expect(service.fixesStarted, 2);
    // An error with the permission still granted is not "no position": the dot stays.
    expect(seen, isNot(contains(null)));
  });

  test('pause releases the GPS, start takes it back', () async {
    tracker.start();
    await _settle();
    tracker.pause();
    await _settle();
    expect(service.fixesCancelled, 1);
    final startedBefore = service.fixesStarted;
    await _settle(); // paused: the periodic look does nothing
    expect(service.fixesStarted, startedBefore);

    tracker.start();
    await _settle();
    expect(service.fixesStarted, startedBefore + 1);
  });

  test('a late listener gets the current position first', () async {
    service.lastKnownFix = _rome;
    tracker.start();
    await _settle();
    final late = <LatLng?>[];
    final sub = tracker.positions.listen(late.add);
    await _settle();
    await sub.cancel();
    expect(late, [_rome]);
  });

  test('a fixed MOCK_POSITION skips the platform entirely', () async {
    final fixed = _FixedPosition();
    final mocked = LocationTracker(fixed);
    final values = <LatLng?>[];
    final sub = mocked.positions.listen(values.add);
    mocked.start();
    await _settle();
    await sub.cancel();
    await mocked.dispose();
    expect(values, [_termini]);
    expect(fixed.fixesStarted, 0);
  });
}
