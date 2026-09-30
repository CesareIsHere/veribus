import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/widgets/transit_map.dart';

void main() {
  final shape = [for (var i = 0; i < 5; i++) LatLng(41.9, 12.48 + i * 0.01)];

  test('pathBetween cuts the shape from the vehicle to the stop', () {
    const vehicle = LatLng(41.9001, 12.4902);
    const stop = LatLng(41.8999, 12.5098);
    expect(pathBetween(shape, vehicle, stop), [vehicle, shape[1], shape[2], shape[3], stop]);
  });

  test('pathBetween keeps the whole shape when the stop comes first', () {
    expect(pathBetween(shape, shape[3], shape[1]), shape);
  });

  test('pathBetween with no shape draws nothing', () {
    expect(pathBetween(const [], shape[0], shape[1]), isEmpty);
  });
}
