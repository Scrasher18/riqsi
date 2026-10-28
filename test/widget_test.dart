import 'package:flutter_test/flutter_test.dart';
import 'package:lector_vision/core/constants/app_constants.dart';

void main() {
  test('AppConstants tiene configurados los valores requeridos para 1x y 0.5x', () {
    expect(AppConstants.zoomEstandar, equals(1.0));
    expect(AppConstants.zoomGranAngular, equals(0.5));
    expect(AppConstants.mensajeBienvenida, isNotEmpty);
    expect(AppConstants.mensajeZoom05x, contains('Gran Angular'));
  });
}
