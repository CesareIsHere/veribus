import 'dart:convert';
import 'dart:typed_data';

/// One service day of the network in the shape RAPTOR scans: routes (trips with the same stop sequence, never
/// overtaking each other), their trips sorted by departure, and the walking links between nearby stops.
///
/// Times are seconds from the midnight of the day the file is for. The trips of the previous service day that run
/// past midnight are included from their first stop after midnight, so a query at 00:30 needs only this file.
///
/// Built by tool/journeys/build_timetable.dart; [encode] and [Timetable.decode] are the compact binary format the
/// phone downloads once a day (little-endian, typed arrays aligned to 4 bytes).
class Timetable {
  Timetable({
    required this.date,
    required this.stopIds,
    required this.stopLat,
    required this.stopLon,
    required this.lineIds,
    required this.routeLine,
    required this.routeHeadsign,
    required this.routeStopStart,
    required this.routeTripStart,
    required this.routeStops,
    required this.tripDeparture,
    required this.tripOffsets,
    required this.footStart,
    required this.footTo,
    required this.footSeconds,
  }) {
    _index();
  }

  /// Reads the format written by [encode].
  factory Timetable.decode(Uint8List bytes) => _Reader(bytes).timetable();

  static const _magic = 0x54544256; // "VBTT"
  static const _version = 1;

  /// The day the times refer to, as yyyymmdd.
  final int date;

  final List<String> stopIds;

  /// Stop positions in millionths of a degree.
  final Int32List stopLat;
  final Int32List stopLon;

  /// GTFS route ids (the lines of the app); [routeLine] points into it.
  final List<String> lineIds;
  final Uint16List routeLine;
  final List<String> routeHeadsign;

  /// Route r stops at `routeStops[routeStopStart[r] .. routeStopStart[r + 1]]`.
  final Uint32List routeStopStart;

  /// Route r owns trips `routeTripStart[r] .. routeTripStart[r + 1]`, sorted by departure.
  final Uint32List routeTripStart;
  final Uint16List routeStops;

  /// Departure of each trip from its first stop.
  final Int32List tripDeparture;

  /// Seconds from the trip's departure to each of its stops, trip after trip.
  final Uint16List tripOffsets;

  /// Walking links of stop s: `footTo/footSeconds[footStart[s] .. footStart[s + 1]]`.
  final Uint32List footStart;
  final Uint16List footTo;
  final Uint16List footSeconds;

  /// Absolute time of trip t at its i-th stop: `times[tripTimeStart[t] + i]`.
  late final Int32List times;
  late final Uint32List tripTimeStart;
  late final Uint32List tripRoute;

  /// The routes through stop s, with the stop's position on each: `stopRoutes/stopRoutePos[stopRouteStart[s] ..]`.
  late final Uint32List stopRouteStart;
  late final Uint32List stopRoutes;
  late final Uint16List stopRoutePos;

  late final Map<String, int> stopIndex = {for (var i = 0; i < stopIds.length; i++) stopIds[i]: i};

  int get stopCount => stopIds.length;
  int get routeCount => routeLine.length;
  int get tripCount => tripDeparture.length;

  int routeLength(int r) => routeStopStart[r + 1] - routeStopStart[r];
  int routeStop(int r, int i) => routeStops[routeStopStart[r] + i];
  int time(int trip, int i) => times[tripTimeStart[trip] + i];

  void _index() {
    tripTimeStart = Uint32List(tripCount);
    tripRoute = Uint32List(tripCount);
    times = Int32List(tripOffsets.length);
    var at = 0;
    for (var r = 0; r < routeCount; r++) {
      final length = routeLength(r);
      for (var t = routeTripStart[r]; t < routeTripStart[r + 1]; t++) {
        tripTimeStart[t] = at;
        tripRoute[t] = r;
        for (var i = 0; i < length; i++) {
          times[at + i] = tripDeparture[t] + tripOffsets[at + i];
        }
        at += length;
      }
    }
    final counts = Uint32List(stopCount + 1);
    for (final s in routeStops) {
      counts[s + 1]++;
    }
    for (var s = 0; s < stopCount; s++) {
      counts[s + 1] += counts[s];
    }
    stopRouteStart = Uint32List.fromList(counts);
    stopRoutes = Uint32List(routeStops.length);
    stopRoutePos = Uint16List(routeStops.length);
    final fill = Uint32List.fromList(counts);
    for (var r = 0; r < routeCount; r++) {
      for (var i = 0; i < routeLength(r); i++) {
        final s = routeStop(r, i);
        stopRoutes[fill[s]] = r;
        stopRoutePos[fill[s]++] = i;
      }
    }
  }

  Uint8List encode() {
    final w = _Writer()
      ..u32(_magic)
      ..u32(_version)
      ..u32(date)
      ..strings(stopIds)
      ..i32s(stopLat)
      ..i32s(stopLon)
      ..strings(lineIds)
      ..strings(routeHeadsign)
      ..u16s(routeLine)
      ..u32s(routeStopStart)
      ..u32s(routeTripStart)
      ..u16s(routeStops)
      ..i32s(tripDeparture)
      ..u16s(tripOffsets)
      ..u32s(footStart)
      ..u16s(footTo)
      ..u16s(footSeconds);
    return w.bytes();
  }
}

class _Writer {
  final _out = BytesBuilder(copy: false);
  var _length = 0;

  void _add(List<int> bytes) {
    _out.add(bytes);
    _length += bytes.length;
  }

  void _align() {
    if (_length % 4 != 0) _add(Uint8List(4 - _length % 4));
  }

  void u32(int v) => _add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());

  void strings(List<String> values) {
    final encoded = utf8.encode(values.join('\n'));
    u32(values.length);
    u32(encoded.length);
    _add(encoded);
    _align();
  }

  // Typed arrays are written in the platform's byte order, which is little-endian on every phone and desktop we run.
  void u16s(Uint16List v) => _typed(v.length, v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes));
  void u32s(Uint32List v) => _typed(v.length, v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes));
  void i32s(Int32List v) => _typed(v.length, v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes));

  void _typed(int count, Uint8List bytes) {
    u32(count);
    _add(bytes);
    _align();
  }

  Uint8List bytes() => _out.takeBytes();
}

class _Reader {
  _Reader(this._bytes) : _data = ByteData.sublistView(_bytes);

  final Uint8List _bytes;
  final ByteData _data;
  var _at = 0;

  int _u32() {
    final v = _data.getUint32(_at, Endian.little);
    _at += 4;
    return v;
  }

  void _align() => _at = (_at + 3) & ~3;

  List<String> _strings() {
    final count = _u32();
    final length = _u32();
    final text = utf8.decode(Uint8List.sublistView(_bytes, _at, _at + length));
    _at += length;
    _align();
    return count == 0 ? const [] : text.split('\n');
  }

  Uint16List _u16s() => _copy(_u32(), 2, Uint16List.sublistView);
  Uint32List _u32s() => _copy(_u32(), 4, Uint32List.sublistView);
  Int32List _i32s() => _copy(_u32(), 4, Int32List.sublistView);

  // A copy is aligned whatever the offset of the downloaded buffer.
  T _copy<T>(int n, int size, T Function(Uint8List) view) {
    final bytes = Uint8List.fromList(Uint8List.sublistView(_bytes, _at, _at + n * size));
    _at += n * size;
    _align();
    return view(bytes);
  }

  Timetable timetable() {
    if (_u32() != Timetable._magic) throw const FormatException('Not a Veribus timetable');
    final version = _u32();
    if (version != Timetable._version) throw FormatException('Unsupported timetable version $version');
    return Timetable(
      date: _u32(),
      stopIds: _strings(),
      stopLat: _i32s(),
      stopLon: _i32s(),
      lineIds: _strings(),
      routeHeadsign: _strings(),
      routeLine: _u16s(),
      routeStopStart: _u32s(),
      routeTripStart: _u32s(),
      routeStops: _u16s(),
      tripDeparture: _i32s(),
      tripOffsets: _u16s(),
      footStart: _u32s(),
      footTo: _u16s(),
      footSeconds: _u16s(),
    );
  }
}
