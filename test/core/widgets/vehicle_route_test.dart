import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/widgets/vehicle_route.dart';

void main() {
  // Five points on a line going east.
  final shape = [for (var i = 0; i < 5; i++) LatLng(41.9, 12.48 + i * 0.01)];

  test('splits the route where the vehicle is: travelled behind, still to go ahead', () {
    const bus = LatLng(41.9001, 12.4902); // a little north of the road, between the 2nd and 3rd point
    final (:behind, :ahead) = splitRoute(shape, bus);
    expect(behind.sublist(0, 2), [shape[0], shape[1]]);
    expect(ahead.sublist(1), [shape[2], shape[3], shape[4]]);
    // Both halves meet at the cut, which is on the road, level with the bus.
    expect(behind.last, ahead.first);
    expect(behind.last.latitude, closeTo(41.9, 1e-9));
    expect(behind.last.longitude, closeTo(12.4902, 1e-6));
  });

  test('a vehicle at the start has nothing behind it but the cut; at the end nothing ahead', () {
    expect(splitRoute(shape, shape.first).behind.length, 2);
    final end = splitRoute(shape, shape.last);
    expect(end.ahead.length, 2);
    expect(end.ahead.first, end.ahead.last);
  });

  test('without a route there is nothing to split', () {
    final (:behind, :ahead) = splitRoute(const <LatLng>[], shape[0]);
    expect(behind, isEmpty);
    expect(ahead, isEmpty);
  });
}
