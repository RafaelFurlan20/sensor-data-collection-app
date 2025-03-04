
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';


@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance){
    service.on('setAsForeground').listen((event) {
      service.setForegroundNotificationInfo(title: 'Aplicativo operando', content: 'Os dados estão sendo enviados para a nuvem.');
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if(service is AndroidServiceInstance){
        if(await service.isForegroundService()){
          service.setForegroundNotificationInfo(title: 'Aplicativo operando', content: 'Os dados estão sendo enviados para a nuvem.');
        }
      }
      print('background service running');
      service.invoke('update');

    });
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground (ServiceInstance service) async{
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
        onStart: onStart, isForegroundMode: true, autoStart: true),
  );
}
