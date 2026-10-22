import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/features/journeys/components/journey_widgets.dart';

/// About 100 m north or east of a corner in Rome.
LatLng _at(double north, double east) => LatLng(41.9 + north * 0.0009, 12.5 + east * 0.0012);

double _length(List<LatLng> line) =>
    [for (var i = 1; i < line.length; i++) const Distance()(line[i - 1], line[i])].fold(0, (a, b) => a + b);

void main() {
  // A street going north 5 blocks, then east 8 blocks.
  final shape = [_at(-2, 0), _at(5, 0), _at(5, 5), _at(5, 8)];

  test('a ride follows the street around the corner, from its stop to its stop', () {
    final stops = [_at(-2, 0), _at(0, 0), _at(5, 1), _at(5, 4)];
    final line = alongShape(shape, stops, 1, 3);
    expect(line, contains(_at(5, 0))); // the corner, which the straight stops skip
    expect(const Distance()(line.first, stops[1]), lessThan(5));
    expect(const Distance()(line.last, stops[3]), lessThan(5));
  });

  test('a stop off the path (a variant) or no path at all: the stops joined straight', () {
    final variant = [_at(0, 0), _at(2, 3), _at(5, 4)];
    expect(alongShape(shape, variant, 0, 2), variant);
    expect(alongShape(const [], variant, 1, 2), variant.sublist(1));
  });

  test('a line out and back on the same street (the 40 on Via Nazionale) is cut on the right pass', () {
    // East 6 blocks, then back west a few metres away, as the two sides of one street.
    final loop = [_at(0, 0), _at(0, 6), _at(0.1, 6), _at(0.1, 0)];
    final stops = [_at(0, 0), _at(0, 2), _at(0, 4), _at(0, 6), _at(0.1, 5), _at(0.1, 3), _at(0.1, 1)];
    // Getting on at the second stop of the way back, off at the last: two blocks west, not the whole loop.
    final back = alongShape(loop, stops, 5, 6);
    expect(_length(back), closeTo(const Distance()(stops[5], stops[6]), 5));
    expect(back.first.longitude, greaterThan(back.last.longitude));
    // On the way out, across the turn.
    final across = alongShape(loop, stops, 2, 4);
    expect(across, containsAllInOrder([_at(0, 6), _at(0.1, 6)]));
  });
}
