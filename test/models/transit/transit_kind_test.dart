import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/models/transit/transit_kind.dart';

void main() {
  test('a line of the network: night buses are told from the day ones, trams from buses', () {
    Line line(LineKind kind, {bool night = false}) =>
        Line(id: 'x', name: 'x', kind: kind, night: night, directions: const []);
    expect(TransitKind.ofLine(line(LineKind.bus)), TransitKind.bus);
    expect(TransitKind.ofLine(line(LineKind.tram)), TransitKind.tram);
    expect(TransitKind.ofLine(line(LineKind.bus, night: true)), TransitKind.night);
    expect(TransitKind.ofLineOrBus(null), TransitKind.bus);
  });

  test('a line of a timetable: by its GTFS type, the night buses by their name', () {
    TransitKind of(String name, int type) =>
        TransitKind.ofTimetable(name: name, isTram: type == Timetable.tram, isMetro: type == Timetable.metro);
    expect(of('A', Timetable.metro), TransitKind.metro);
    expect(of('8', Timetable.tram), TransitKind.tram);
    expect(of('n1', Timetable.bus), TransitKind.night);
    expect(of('N12', Timetable.bus), TransitKind.night);
    expect(of('40', Timetable.bus), TransitKind.bus);
    expect(of('nord', Timetable.bus), TransitKind.bus);
  });
}
