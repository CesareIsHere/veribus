import 'package:veribus/models/transit/network.dart';

/// What a line is for the rider: the color and icon of its chip everywhere. Night lines (`n1`) are told apart from
/// the day bus because that is what matters at 1 a.m.
enum TransitKind {
  bus,
  tram,
  metro,
  night;

  /// A line of the app's network (the metro is not in it).
  static TransitKind ofLine(Line line) => line.night
      ? night
      : switch (line.kind) {
          LineKind.tram => tram,
          LineKind.bus => bus,
        };

  /// The chip of a line that may not be in the network (a removed one): a bus.
  static TransitKind ofLineOrBus(Line? line) => line == null ? bus : ofLine(line);

  /// A line of a journey timetable: [isTram] and [isMetro] come from its GTFS type, the night lines from the name.
  static TransitKind ofTimetable({required String name, required bool isTram, required bool isMetro}) {
    if (isMetro) return metro;
    if (isTram) return tram;
    return RegExp(r'^[nN]\d').hasMatch(name) ? night : bus;
  }
}
