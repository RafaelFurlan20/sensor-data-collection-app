import 'package:explorer/screens/calibrate.dart';
import 'package:flutter/material.dart';
import 'screens/sensors_page_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:explorer/screens/home_screen.dart';
import 'package:explorer/screens/configurations.dart';
import 'package:explorer/screens/calibrate.dart';
import 'package:explorer/screens/more_information_screen.dart'; // Add this import
import 'package:get/get.dart';
import 'utilities/calibration_controller.dart';

late List<CameraDescription> cameras;
final routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyCwG93y8zjhJNJ_v02cdQQ4ah_6DCq3g68",
          appId: "1:458532455372:android:8f184d7059776d5ddbd369",
          messagingSenderId: "458532455372",
          projectId: "explorer-d2f9d"));
  cameras = await availableCameras();

  Get.put(CalibrationController());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: '/',
      navigatorObservers: [routeObserver],
      getPages: [
        GetPage(name: '/', page: () => HomeScreen()),
        GetPage(name: '/calibrate', page: () => Calibrate()),
        GetPage(name: '/sensors', page: () => cameras != null
            ? SensorsScreen(cameras!)
            : CircularProgressIndicator()),
        GetPage(name: '/configurations', page: () => Configurations()),
        GetPage(name: '/more_info', page: () => MoreInfoScreen()), // Add this route
      ],
    );
  }
}