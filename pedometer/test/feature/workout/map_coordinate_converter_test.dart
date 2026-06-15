import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/map_coordinate_converter.dart';

void main() {
  test('keeps coordinates outside mainland China unchanged', () {
    const coordinate = WorkoutMapCoordinate(latitude: 37.7749, longitude: -122.4194);

    final converted = MapCoordinateConverter.wgs84ToGcj02(coordinate);

    expect(converted.latitude, coordinate.latitude);
    expect(converted.longitude, coordinate.longitude);
  });

  test('converts Shenzhen WGS84 coordinates to GCJ02 for China map tiles', () {
    const coordinate = WorkoutMapCoordinate(latitude: 22.543096, longitude: 114.057865);

    final converted = MapCoordinateConverter.wgs84ToGcj02(coordinate);

    expect(converted.latitude, closeTo(22.540379, 0.000001));
    expect(converted.longitude, closeTo(114.062979, 0.000001));
  });
}
