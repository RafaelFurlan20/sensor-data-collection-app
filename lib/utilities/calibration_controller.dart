import 'package:get/get.dart';

class CalibrationController extends GetxController {
  RxDouble calibrateTetaX = 0.0.obs;
  RxDouble calibrateTetaY = 0.0.obs;
  RxDouble calibrateTetaZ = 0.0.obs;

  setTetaX(double value) => calibrateTetaX.value = value;
  setTetaY(double value) => calibrateTetaY.value = value;
  setTetaZ(double value) => calibrateTetaZ.value = value;

  double getTetaX() => calibrateTetaX.value;
  double getTetaY() => calibrateTetaY.value;
  double getTetaZ() => calibrateTetaZ.value;
}
