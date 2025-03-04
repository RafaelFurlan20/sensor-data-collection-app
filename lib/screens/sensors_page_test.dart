import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:explorer/main.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:explorer/constants.dart';
import 'package:explorer/elements/dynamic_card.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:camera/camera.dart';
import 'package:explorer/utilities/back_services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:explorer/elements/build_text_field.dart';
import 'package:explorer/elements/build_text_field.dart';
import 'package:explorer/elements/buildNumberField.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:explorer/utilities/calibration_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class SensorsScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SensorsScreen(this.cameras, {super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> with RouteAware {
  late CameraController controller;
  final CalibrationController _calibrationController =
  Get.find<CalibrationController>();

  // Data collection parameters
  String dataIdentification = 'NoRecord';
  double dataFreq = 5;
  Timer? timerPictures;
  Timer? timerSendInfo;
  late Position position;
  int _selectedCameraIndex = 0;
  ResolutionPreset _selectedResolution = ResolutionPreset.high;
  FlashMode _currentFlashMode = FlashMode.auto;

  // Sensor events
  UserAccelerometerEvent? _userAccelerometerEvent;
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  MagnetometerEvent? _magnetometerEvent;

  int indexGraph = 0;

  // Status flags
  bool fileCreated = false;
  late bool cameraStatus;
  late bool videoStatus;
  late bool photoStatus;
  late bool acelerometerStatus;
  late bool acelerometerRawStatus;
  late bool gyroscopeStatus;
  late bool magnometerStatus;
  late bool altimeterStatus;
  late bool coordinatesStatus;
  late bool speedStatus;

  // Sensor values
  double gyroscopeX = 0;
  double gyroscopeY = 0;
  double gyroscopeZ = 0;
  double accelerometeRawX = 0;
  double accelerometeRawY = 0;
  double accelerometeRawZ = 0;
  double accelerometerX = 0;
  double accelerometerY = 0;
  double accelerometerZ = 0;
  double ngraph = 0;
  double secondsPerRad = 0;
  double speed = 0;
  double latitude = 0;
  double longitude = 0;
  double altitude = 0;
  double magnetometerX = 0;
  double magnetometerY = 0;
  double magnetometerZ = 0;
  late double tetaX;
  late double tetaY;
  late double tetaZ;
  double angleX = 0;
  double angleY = 0;
  double angleZ = 0;

  // File handling
  String? selectedDirectory;
  String textButtom = 'Ativar envio de dados';
  String dateOfNow = '';
  String fileName = '';
  bool sendInformation = false;
  List<List<dynamic>> data = [];

  // Graph data
  List<FlSpot> tetaXList = [];
  List<FlSpot> tetaYList = [];
  List<FlSpot> tetaZList = [];

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  late Timer locationTimer;
  late LocationPermission permission;
  Duration sensorInterval = SensorInterval.gameInterval;

  // Camera flags
  bool _isTakingPicture = false;
  bool _isRecording = false;
  XFile? _recordedVideo;
  late String formattedDate;
  late String newPath;

  bool isLoading = true;
  int _currentTabIndex = 0;  // For bottom navigation

  bool stringToBool(String value) => value.toLowerCase() == 'true';

  // Tab information
  List<Map<String, dynamic>> _tabs = [];

  // Toggle Flash Mode
  // Modified _toggleFlashMode method for SensorsScreen class
// Improved _toggleFlashMode method
  void _toggleFlashMode() async {
    if (!controller.value.isInitialized) return;

    // Store previous mode in case we need to revert
    FlashMode previousMode = _currentFlashMode;

    // Update state
    setState(() {
      if (_currentFlashMode == FlashMode.off) {
        _currentFlashMode = FlashMode.auto;
      } else if (_currentFlashMode == FlashMode.auto) {
        _currentFlashMode = FlashMode.always;
      } else {
        _currentFlashMode = FlashMode.off;
      }
    });

    try {
      // Wait for the mode to be applied
      await controller.setFlashMode(_currentFlashMode);

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flash mode changed to ${_getFlashLabel()}'),
          duration: const Duration(milliseconds: 500),
          backgroundColor: Colors.blue,
        ),
      );

      // Optional: For testing, log the current flash mode
      print('Flash mode set to: $_currentFlashMode');

    } catch (error) {
      print('Error setting flash mode: $error');

      // Revert to previous mode in state
      setState(() {
        _currentFlashMode = previousMode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change flash mode: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Helper methods for flash mode
  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      default:
        return Icons.flash_auto;
    }
  }

  String _getFlashLabel() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return 'Off';
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.always:
        return 'On';
      default:
        return 'Auto';
    }
  }

  Future<void> initValues() async {
    locationGetter();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load all settings from SharedPreferences
    cameraStatus = prefs.getBool('cameraStatus') ?? true;
    videoStatus = prefs.getBool('videoStatus') ?? true;
    photoStatus = prefs.getBool('photoStatus') ?? false;
    acelerometerStatus = prefs.getBool('acelerometerStatus') ?? true;
    acelerometerRawStatus = prefs.getBool('acelerometerRawStatus') ?? true;
    gyroscopeStatus = prefs.getBool('gyroscopeStatus') ?? true;
    magnometerStatus = prefs.getBool('magnometerStatus') ?? true;
    altimeterStatus = prefs.getBool('altimeterStatus') ?? true;
    coordinatesStatus = prefs.getBool('coordinatesStatus') ?? true;
    speedStatus = prefs.getBool('speedStatus') ?? true;

    // Initialize tab structure
    _tabs = [
      {
        'title': 'Dashboard',
        'icon': Icons.dashboard_rounded,
      },
      {
        'title': 'Câmera',
        'icon': Icons.camera_alt_rounded,
        'enabled': cameraStatus,
      },
      {
        'title': 'Gráficos',
        'icon': Icons.area_chart_rounded,
        'enabled': gyroscopeStatus,
      },
      {
        'title': 'Configurações',
        'icon': Icons.settings_rounded,
      },
    ];

    setState(() {
      isLoading = false;
    });

    // Initialize sensor streams
    if (acelerometerStatus) {
      _streamSubscriptions.add(
        userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
              (UserAccelerometerEvent event) {
            setState(() {
              _userAccelerometerEvent = event;
              accelerometeRawX = _userAccelerometerEvent!.x;
              accelerometeRawY = _userAccelerometerEvent!.y;
              accelerometeRawZ = _userAccelerometerEvent!.z;
            });
          },
          onError: (e) {
            _showSensorErrorDialog("User Accelerometer Sensor");
          },
          cancelOnError: true,
        ),
      );
    }

    if (acelerometerRawStatus) {
      _streamSubscriptions.add(
        accelerometerEventStream(samplingPeriod: sensorInterval).listen(
              (AccelerometerEvent event) {
            setState(() {
              _accelerometerEvent = event;

              accelerometerX = _accelerometerEvent!.x;
              accelerometerY = _accelerometerEvent!.y;
              accelerometerZ = _accelerometerEvent!.z;

              double sumOfSquares =
                  pow(accelerometeRawX - accelerometerX, 2).toDouble() +
                      pow(accelerometeRawY - accelerometerY, 2).toDouble() +
                      pow(accelerometeRawZ - accelerometerZ, 2).toDouble();

              double magnitude = sqrt(sumOfSquares);

              // Normalize accelerometer values
              double normX = -(accelerometeRawX - accelerometerX) / magnitude;
              double normY = -(accelerometeRawY - accelerometerY) / magnitude;
              double normZ = -(accelerometeRawZ - accelerometerZ) / magnitude;

              angleY = acos(normX) * (180 / pi); // Convert from radians to degrees
              angleZ = acos(normY) * (180 / pi); // Convert from radians to degrees
              angleX = acos(normZ) * (180 / pi); // Convert from radians to degrees
            });
          },
          onError: (e) {
            _showSensorErrorDialog("Accelerometer Sensor");
          },
          cancelOnError: true,
        ),
      );
    }

    double thresholdGyro(double gyro) {
      if (gyro.abs() > 0.0009) {
        return gyro;
      }
      return 0.0;
    }

    if (gyroscopeStatus) {
      _streamSubscriptions.add(
        gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
              (GyroscopeEvent event) {
            setState(() {
              ngraph += sensorInterval.inMilliseconds / 1000;
              if (tetaXList.length > 1000) {
                tetaXList = tetaXList.sublist(
                    tetaXList.length - 1000, tetaXList.length);
                tetaYList = tetaYList.sublist(
                    tetaYList.length - 1000, tetaYList.length);
                tetaZList = tetaZList.sublist(
                    tetaZList.length - 1000, tetaZList.length);
              }
              _gyroscopeEvent = event;

              gyroscopeX = _gyroscopeEvent!.x;
              gyroscopeY = _gyroscopeEvent!.y;
              gyroscopeZ = _gyroscopeEvent!.z;

              secondsPerRad = (sensorInterval.inMilliseconds) / 1000 * 180 / pi;

              tetaX += secondsPerRad * thresholdGyro(gyroscopeX);
              tetaY += secondsPerRad * thresholdGyro(gyroscopeY);
              tetaZ += secondsPerRad * thresholdGyro(gyroscopeZ);

              tetaX = normalizeAngle(tetaX);
              tetaY = normalizeAngle(tetaY);
              tetaZ = normalizeAngle(tetaZ);

              tetaXList.add(FlSpot(ngraph, tetaX));
              tetaYList.add(FlSpot(ngraph, tetaY));
              tetaZList.add(FlSpot(ngraph, tetaZ));
            });
          },
          onError: (e) {
            _showSensorErrorDialog("Gyroscope Sensor");
          },
          cancelOnError: true,
        ),
      );
    }

    if (magnometerStatus) {
      _streamSubscriptions.add(
        magnetometerEventStream(samplingPeriod: sensorInterval).listen(
              (MagnetometerEvent event) {
            setState(() {
              _magnetometerEvent = event;
              magnetometerX = _magnetometerEvent!.x;
              magnetometerY = _magnetometerEvent!.y;
              magnetometerZ = _magnetometerEvent!.z;
            });
          },
          onError: (e) {
            _showSensorErrorDialog("Magnetometer Sensor");
          },
          cancelOnError: true,
        ),
      );
    }
  }

  void _showSensorErrorDialog(String sensorName) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Sensor Not Found"),
            content: Text(
                "It seems that your device doesn't support $sensorName"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        }
    );
  }

  @override
  void initState() {
    super.initState();
    tetaX = _calibrationController.calibrateTetaX.value;
    tetaY = _calibrationController.calibrateTetaY.value;
    tetaZ = _calibrationController.calibrateTetaZ.value;

    initValues();
    startConfigs();

    startService();
    _initializeCameraController();
    controller.initialize().then((value) {
      if (!mounted) {
        return;
      }
      // Set initial flash mode after camera is initialized
      controller.setFlashMode(_currentFlashMode);
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    initValues();
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.didPopNext();
  }

  @override
  void dispose() {
    super.dispose();
    timerPictures?.cancel();
    timerSendInfo?.cancel();
    locationTimer?.cancel();

    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }

    FlutterBackgroundService().invoke('stopService');
    controller.dispose();
  }

  void startService() async {
    await initializeService();
    FlutterBackgroundService().invoke('setAsForeground');
  }

  void startConfigs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    fileName = prefs.getString('fileName') ??
        "data_${DateTime.now()}".replaceAll(':', '_');

    await prefs.setString('fileName', fileName);

    selectedDirectory = prefs.getString('path');
  }

  void locationGetter() async {
    await checkAndRequestLocationPermission();

    if (permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever) {

      locationTimer = Timer.periodic(sensorInterval, (timer) async {
        if (!mounted) return;

        Position newPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation);
        if (!mounted) return;
        setState(() {
          speed = newPosition.speed;
          latitude = newPosition.latitude;
          longitude = newPosition.longitude;
          altitude = newPosition.altitude;
        });
      });
    }
  }

  Future<void> checkAndRequestLocationPermission() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Permissão de localização negada'),
            content: const Text(
                'Para utilizar este recurso, por favor, conceda permissão de localização.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _startRecording() async {
    if (!controller.value.isInitialized || controller.value.isRecordingVideo) {
      return;
    }

    try {
      await controller.startVideoRecording();
      final now = DateTime.now();
      formattedDate = DateFormat('yyyy.MM.dd_HH.mm.ss').format(now);
      setState(() => _isRecording = true);
    } catch (e) {
      _showErrorDialog('Error starting video recording', e.toString());
    }
  }

  void _stopRecording() async {
    if (!controller.value.isRecordingVideo) {
      return;
    }

    try {
      XFile? recordedVideo = await controller.stopVideoRecording();
      setState(() => _isRecording = false);
      if (recordedVideo != null) {
        _recordedVideo = recordedVideo;
        _saveVideo();
      }
    } catch (e) {
      _showErrorDialog('Error stopping video recording', e.toString());
    }
  }

  void _saveVideo() async {
    if (_recordedVideo != null) {
      try {
        final now = DateTime.now();
        final newFileName = '$formattedDate.mp4';
        if (selectedDirectory == null) {
          final directory = await path_provider.getExternalStorageDirectory();
          if (directory == null) {
            _showErrorDialog('Error', 'Não foi possível obter o diretório de downloads');
            return;
          }

          selectedDirectory = directory.path;
        }
        newPath = '${selectedDirectory}/$newFileName';

        // Copy the file contents
        final newFile = await File(newPath).create();
        await newFile.writeAsBytes(await File(_recordedVideo!.path).readAsBytes());

        // Delete the original file
        await File(_recordedVideo!.path).delete();

        await GallerySaver.saveVideo(newPath);
        _showSuccessDialog('Video saved successfully', 'Path: $newPath');

      } catch (e) {
        _showErrorDialog('Error saving video', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String description) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      headerAnimationLoop: false,
      title: title,
      desc: description,
      btnOkOnPress: () {},
      btnOkIcon: Icons.cancel,
      btnOkColor: Colors.red,
    ).show();
  }

  void _showSuccessDialog(String title, String description) {
    AwesomeDialog(
      context: context,
      animType: AnimType.leftSlide,
      headerAnimationLoop: false,
      dialogType: DialogType.success,
      showCloseIcon: true,
      title: title,
      desc: description,
      btnOkOnPress: () {},
      btnOkIcon: Icons.check_circle,
      onDismissCallback: (type) {},
    ).show();
  }

  void capturePictures() async {
    if (!controller.value.isInitialized || _isTakingPicture) {
      return;
    }
    _isTakingPicture = true;

    try {
      final XFile capturedImage = await controller.takePicture();
      String imagePath = capturedImage.path;
      final fileName = path.basename(imagePath);

      if (selectedDirectory == null) {
        final directory = await path_provider.getExternalStorageDirectory();
        if (directory == null) {
          _showErrorDialog('Error', 'Não foi possível obter o diretório de downloads');
          return;
        }

        selectedDirectory = directory.path;
      }
      final newPath = path.join(selectedDirectory!, fileName);

      final savedImagePath = await File(imagePath).copy(newPath);
      await GallerySaver.saveImage(savedImagePath.path);
    } catch (e) {
      _showErrorDialog('Error', 'Não foi possível salvar a imagem: $e');
    } finally {
      _isTakingPicture = false;
    }
  }

  void startTimer() {
    if (sendInformation) {
      timerSendInfo = Timer.periodic(sensorInterval, (timer) {
        data.add([
          dataIdentification,
          sensorInterval.inMilliseconds,
          DateFormat('HH:mm:ss.SSS').format(DateTime.now()),
          if (magnometerStatus) magnetometerZ.toStringAsFixed(10),
          if (magnometerStatus) magnetometerY.toStringAsFixed(10),
          if (magnometerStatus) magnetometerX.toStringAsFixed(10),
          if (gyroscopeStatus) gyroscopeZ.toStringAsFixed(10),
          if (gyroscopeStatus) gyroscopeY.toStringAsFixed(10),
          if (gyroscopeStatus) gyroscopeX.toStringAsFixed(10),
          if (gyroscopeStatus) tetaX.toStringAsFixed(10),
          if (gyroscopeStatus) tetaY.toStringAsFixed(10),
          if (gyroscopeStatus) tetaZ.toStringAsFixed(10),
          if (acelerometerRawStatus) accelerometerZ.toStringAsFixed(10),
          if (acelerometerRawStatus) accelerometerY.toStringAsFixed(10),
          if (acelerometerRawStatus) accelerometerX.toStringAsFixed(10),
          if (acelerometerStatus) angleX.toStringAsFixed(10),
          if (acelerometerStatus) angleY.toStringAsFixed(10),
          if (acelerometerStatus) angleZ.toStringAsFixed(10),
          if (acelerometerStatus) accelerometeRawZ.toStringAsFixed(10),
          if (acelerometerStatus) accelerometeRawY.toStringAsFixed(10),
          if (acelerometerStatus) accelerometeRawX.toStringAsFixed(10),
          if (altimeterStatus) altitude,
          if (coordinatesStatus) longitude,
          if (coordinatesStatus) latitude,
          if (speedStatus) speed,
        ]);
      });

      if (cameraStatus) {
        if (photoStatus) {
          timerPictures = Timer.periodic(Duration(seconds: dataFreq.toInt()), (timer) {
            capturePictures();
          });
        } else if (videoStatus) {
          _startRecording();
        }
      }
    } else {
      timerSendInfo?.cancel();
      timerPictures?.cancel();
      if (videoStatus) {
        _stopRecording();
      }
    }
  }

  double normalizeAngle(angle) {
    while (angle > 180) {
      angle -= 360;
    }
    while (angle <= -180) {
      angle += 360;
    }
    return angle;
  }

  void _initializeCameraController() {
    controller = CameraController(
      widget.cameras[_selectedCameraIndex],
      _selectedResolution,
    );
  }

  void pickDirectory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? choosen = await FilePicker.platform.getDirectoryPath();
    if (choosen != null) {
      selectedDirectory = choosen;
      await prefs.setString('path', choosen);
    }
  }

  void saveFile() async {
    String csv = const ListToCsvConverter().convert(data);

    if (selectedDirectory == null) {
      final directory = await path_provider.getExternalStorageDirectory();
      if (directory == null) {
        _showErrorDialog('Error', 'Não foi possível obter o diretório de downloads');
        return;
      }

      selectedDirectory = directory.path;
    }

    final file = File("$selectedDirectory/$fileName.csv");
    String existingData = '';

    if (await file.exists()) {
      try {
        existingData = await file.readAsString();
      } catch (e) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          headerAnimationLoop: false,
          animType: AnimType.bottomSlide,
          title: 'Aviso',
          desc: 'O erro a seguir foi obtido ao inicializar o arquivo $e',
          buttonsTextStyle: const TextStyle(color: Colors.black),
          showCloseIcon: true,
          btnCancelOnPress: () {},
          btnOkOnPress: () {},
        ).show();
      }
    } else {
      existingData = const ListToCsvConverter().convert([
        [
          'identification',
          'sensorInterval',
          'date',
          if (magnometerStatus) 'magnetometerZ',
          if (magnometerStatus) 'magnetometerY',
          if (magnometerStatus) 'magnetometerX',
          if (gyroscopeStatus) 'gyroscopeZ',
          if (gyroscopeStatus) 'gyroscopeY',
          if (gyroscopeStatus) 'gyroscopeX',
          if (gyroscopeStatus) 'tetaX',
          if (gyroscopeStatus) 'tetaY',
          if (gyroscopeStatus) 'tetaZ',
          if (acelerometerRawStatus) 'acelerometer_raw_z',
          if (acelerometerRawStatus) 'acelerometer_raw_y',
          if (acelerometerRawStatus) 'acelerometer_raw_x',
          if (acelerometerStatus) 'tetaX accelerometer',
          if (acelerometerStatus) 'tetaY accelerometer',
          if (acelerometerStatus) 'tetaZ accelerometer',
          if (acelerometerStatus) 'acelerometer_z',
          if (acelerometerStatus) 'acelerometer_y',
          if (acelerometerStatus) 'acelerometer_x',
          if (altimeterStatus) 'altitude',
          if (coordinatesStatus) 'longitude',
          if (coordinatesStatus) 'latitude',
          if (speedStatus) 'speed'
        ]
      ]);
    }

    try {
      String newData = '$existingData\n$csv';
      await file.writeAsString(newData);
      _showSuccessDialog(
          'Salvo com Sucesso',
          'Arquivo salvo em: $selectedDirectory, nome: $fileName.csv'
      );
    } catch (e, stackTrace) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      fileName = "data_${DateTime.now()}".replaceAll(':', '_');
      await prefs.setString('fileName', fileName);
      saveFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: const [0.1, 0.4, 0.7, 0.9],
          colors: [
            Colors.indigo[400]!,
            Colors.indigo[300]!,
            Colors.blue[300]!,
            Colors.blue[200]!,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            _tabs.isNotEmpty ? _tabs[_currentTabIndex]['title'] : 'Explorer',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 22,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_alt_rounded, color: Colors.white),
              onPressed: () {
                if (data.isNotEmpty) {
                  saveFile();
                } else {
                  _showErrorDialog('Erro', 'Não há dados para salvar');
                }
              },
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Image.asset(
                  'images/upscalar.png',
                  color: Colors.white,
                  width: 32,
                  height: 32,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _buildCurrentTab(),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white10,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentTabIndex,
          onTap: (index) {
            // Don't navigate to disabled tabs
            if (_tabs[index].containsKey('enabled') && _tabs[index]['enabled'] == false) {
              return;
            }
            setState(() {
              _currentTabIndex = index;
            });
          },
          items: _tabs.map((tab) {
            bool isEnabled = !tab.containsKey('enabled') || tab['enabled'];
            return BottomNavigationBarItem(
              icon: Icon(
                tab['icon'],
                color: isEnabled ? null : Colors.grey,
              ),
              label: tab['title'],
              backgroundColor: Colors.transparent,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return cameraStatus ? _buildCameraTab() : _buildDisabledTab('Câmera');
      case 2:
        return gyroscopeStatus ? _buildGraphTab() : _buildDisabledTab('Gráficos');
      case 3:
        return _buildSettingsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDisabledTab(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensors_off,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '$feature Desativado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ative $feature nas configurações para visualizar esta página',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.settings),
            label: const Text('Ir para Configurações'),
            onPressed: () {
              Navigator.pushNamed(context, '/configurations');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataCollectionSection(),
            const SizedBox(height: 16),

            // Data recording control
            _buildRecordingControl(),
            const SizedBox(height: 24),

            // Sensor data section
            const Text(
              'Dados dos Sensores',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Sensor data cards in grid layout
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.0, // Ajustado para tornar os cards mais altos
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                if (coordinatesStatus || altimeterStatus)
                  _buildSensorCard(
                    title: 'Localização',
                    icon: Icons.location_on_rounded,
                    values: [
                      if (coordinatesStatus) 'Lat: ${latitude.toStringAsFixed(5)}',
                      if (coordinatesStatus) 'Long: ${longitude.toStringAsFixed(5)}',
                      if (altimeterStatus) 'Alt: ${altitude.toStringAsFixed(1)}m',
                      if (speedStatus) 'Vel: ${speed.toStringAsFixed(1)}m/s',
                    ],
                  ),

                if (acelerometerRawStatus)
                  _buildSensorCard(
                    title: 'Acelerômetro',
                    icon: Icons.speed_rounded,
                    values: [
                      'X: ${accelerometerX.toStringAsFixed(4)}',
                      'Y: ${accelerometerY.toStringAsFixed(4)}',
                      'Z: ${accelerometerZ.toStringAsFixed(4)}',
                    ],
                  ),

                if (gyroscopeStatus)
                  _buildSensorCard(
                    title: 'Giroscópio',
                    icon: Icons.rotate_90_degrees_ccw_rounded,
                    values: [
                      'X: ${gyroscopeX.toStringAsFixed(4)}',
                      'Y: ${gyroscopeY.toStringAsFixed(4)}',
                      'Z: ${gyroscopeZ.toStringAsFixed(4)}',
                    ],
                  ),

                if (magnometerStatus)
                  _buildSensorCard(
                    title: 'Magnetômetro',
                    icon: Icons.compass_calibration_rounded,
                    values: [
                      'X: ${magnetometerX.toStringAsFixed(4)}',
                      'Y: ${magnetometerY.toStringAsFixed(4)}',
                      'Z: ${magnetometerZ.toStringAsFixed(4)}',
                    ],
                  ),

                if (gyroscopeStatus)
                  _buildSensorCard(
                    title: 'Orientação',
                    icon: Icons.screen_rotation_rounded,
                    values: [
                      'Θx: ${tetaX.toStringAsFixed(1)}°',
                      'Θy: ${tetaY.toStringAsFixed(1)}°',
                      'Θz: ${tetaZ.toStringAsFixed(1)}°',
                    ],
                  ),

                if (acelerometerStatus)
                  _buildSensorCard(
                    title: 'Acelerômetro Raw',
                    icon: Icons.vibration_rounded,
                    values: [
                      'X: ${accelerometeRawX.toStringAsFixed(4)}',
                      'Y: ${accelerometeRawY.toStringAsFixed(4)}',
                      'Z: ${accelerometeRawZ.toStringAsFixed(4)}',
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSamplingRateSelector(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required IconData icon,
    required List<String> values,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 12),

          // Values - using more height for content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuir valores uniformemente
              children: values.map((value) => Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCollectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuração da Coleta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // ID field
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: buildTextField(
            hText: 'Identificação dos dados...',
            function: (value) {
              dataIdentification = value;
            },
          ),
        ),
        const SizedBox(height: 12),

        // Frequency field
        if (cameraStatus)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: buildNumberField(
              hText: 'Frequência de captura em segundos...',
              function: (value) {
                try {
                  dataFreq = double.parse(value!);
                  setState(() {});
                } catch (e) {
                  print("Invalid input: $e");
                }
              },
            ),
          ),
        const SizedBox(height: 12),

        // Storage location
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Local de Armazenamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedDirectory ?? 'Não selecionado',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  pickDirectory();
                },
                child: const Text('Escolher'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingControl() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: sendInformation ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sendInformation ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                sendInformation ? Icons.fiber_manual_record : Icons.play_arrow_rounded,
                color: sendInformation ? Colors.red : Colors.green,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sendInformation ? 'Registrando Dados' : 'Iniciar Coleta',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      sendInformation
                          ? 'Coleta em andamento'
                          : 'Pressione o botão para iniciar a coleta',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: sendInformation ? Colors.red.withOpacity(0.6) : Colors.green.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      if (sendInformation) {
                        textButtom = 'Ativar envio de dados';
                        fileCreated = true;
                        sendInformation = false;
                        startTimer();
                        saveFile();
                      } else {
                        textButtom = 'Desativar envio de dados';
                        sendInformation = true;
                        startTimer();
                      }
                    });
                  },
                  child: Text(
                    sendInformation ? 'Parar Coleta' : 'Iniciar Coleta',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (fileCreated)
                const SizedBox(width: 12),
              if (fileCreated)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    setState(() {
                      Share.shareXFiles([XFile('$selectedDirectory/$fileName.csv')]);
                      if (videoStatus && newPath.isNotEmpty) {
                        Share.shareXFiles([XFile(newPath)]);
                      }
                    });
                  },
                  label: const Text('Compartilhar'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSamplingRateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Taxa de Amostragem',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSamplingRateOption(SensorInterval.gameInterval, 'Game'),
                _buildSamplingRateOption(SensorInterval.uiInterval, 'UI'),
                _buildSamplingRateOption(SensorInterval.normalInterval, 'Normal'),
                _buildSamplingRateOption(const Duration(milliseconds: 500), '500ms'),
                _buildSamplingRateOption(const Duration(seconds: 1), '1s'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSamplingRateOption(Duration interval, String label) {
    bool isSelected = sensorInterval == interval;

    return GestureDetector(
      onTap: () {
        setState(() {
          sensorInterval = interval;
          userAccelerometerEventStream(samplingPeriod: sensorInterval);
          accelerometerEventStream(samplingPeriod: sensorInterval);
          gyroscopeEventStream(samplingPeriod: sensorInterval);
          magnetometerEventStream(samplingPeriod: sensorInterval);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${interval.inMilliseconds}ms',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera preview
            Center( // Centraliza o preview da câmera na tela
              child: Container(
                height: 160,
                width: 90, // Define uma largura fixa para o preview
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 4 / 3, // Proporção padrão de 4:3 para câmeras
                    child: controller.value.isInitialized
                        ? CameraPreview(controller) // Remove o Row desnecessário
                        : Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Camera controls with Flash
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCameraControlButton(
                    icon: Icons.switch_camera_rounded,
                    label: 'Alternar',
                    onTap: () {
                      if (widget.cameras.length > 1) {
                        setState(() {
                          _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
                          _initializeCameraController();
                          controller.initialize().then((value) {
                            if (!mounted) return;
                            controller.setFlashMode(_currentFlashMode);
                            setState(() {});
                          });
                        });
                      }
                    },
                  ),
                  _buildCameraControlButton(
                    icon: Icons.photo_camera_rounded,
                    label: 'Capturar',
                    onTap: () {
                      if (!_isTakingPicture) {
                        capturePictures();
                      }
                    },
                  ),
                  _buildCameraControlButton(
                    icon: _isRecording ? Icons.stop_rounded : Icons.videocam_rounded,
                    label: _isRecording ? 'Parar' : 'Gravar',
                    color: _isRecording ? Colors.red : null,
                    onTap: () {
                      if (_isRecording) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
                  ),
                  _buildCameraControlButton(
                    icon: _getFlashIcon(),
                    label: _getFlashLabel(),
                    onTap: _toggleFlashMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Camera settings
            const Text(
              'Configurações da Câmera',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Resolution selector
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resolução',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (ResolutionPreset resolution in [
                          ResolutionPreset.max,
                          ResolutionPreset.high,
                          ResolutionPreset.medium,
                          ResolutionPreset.low,
                        ])
                          _buildResolutionOption(resolution),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Camera selector
            if (widget.cameras.length > 1)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Câmera',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < widget.cameras.length; i++)
                            _buildCameraOption(i),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16), // Add padding at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color ?? Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionOption(ResolutionPreset resolution) {
    bool isSelected = _selectedResolution == resolution;
    String label = resolution.toString().split('.').last;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedResolution = resolution;
          _initializeCameraController();
          controller.initialize().then((value) {
            if (!mounted) return;
            controller.setFlashMode(_currentFlashMode);
            setState(() {});
          });
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOption(int index) {
    bool isSelected = _selectedCameraIndex == index;
    String label = 'Câmera ${index + 1}';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCameraIndex = index;
          _initializeCameraController();
          controller.initialize().then((value) {
            if (!mounted) return;
            controller.setFlashMode(_currentFlashMode);
            setState(() {});
          });
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGraphTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orientação do Dispositivo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Graph legend
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Eixo X', Colors.blue),
                _buildLegendItem('Eixo Y', Colors.red),
                _buildLegendItem('Eixo Z', Colors.green),
              ],
            ),
          ),

          // Graph container
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: LineChart(
                LineChartData(
                  minY: -180,
                  maxY: 180,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          String axis = "";
                          Color color;

                          if (spot.barIndex == 0) {
                            axis = "X";
                            color = Colors.blue;
                          } else if (spot.barIndex == 1) {
                            axis = "Y";
                            color = Colors.red;
                          } else {
                            axis = "Z";
                            color = Colors.green;
                          }

                          return LineTooltipItem(
                            'Eixo $axis: ${spot.y.toStringAsFixed(1)}°',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == -180 || value == -90 || value == 0 || value == 90 || value == 180) {
                            return Text(
                              '${value.toInt()}°',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return Text(
                              '${value.toInt()}s',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.white24),
                  ),
                  lineBarsData: [
                    _buildLineChartBarData(tetaXList, Colors.blue),
                    _buildLineChartBarData(tetaYList, Colors.red),
                    _buildLineChartBarData(tetaZList, Colors.green),
                  ],
                ),
              ),
            ),
          ),

          // Current values
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Valores Atuais',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildValueDisplay('Θx', '${tetaX.toStringAsFixed(1)}°', Colors.blue),
                    _buildValueDisplay('Θy', '${tetaY.toStringAsFixed(1)}°', Colors.red),
                    _buildValueDisplay('Θz', '${tetaZ.toStringAsFixed(1)}°', Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildValueDisplay(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.settings),
              label: const Text('Configurações Completas'),
              onPressed: () {
                Navigator.pushNamed(context, '/configurations');
              },
            ),
            const SizedBox(height: 24),

            // Sampling rate
            const Text(
              'Taxa de Amostragem',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSamplingRateSelector(),
            const SizedBox(height: 24),

            // Storage location
            const Text(
              'Armazenamento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Diretório de Arquivos',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          pickDirectory();
                        },
                        child: const Text('Escolher'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedDirectory ?? 'Não selecionado',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nome do Arquivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$fileName.csv',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Export section
            if (fileCreated)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exportar Dados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.share),
                          label: const Text('Compartilhar Arquivo CSV'),
                          onPressed: () {
                            Share.shareXFiles([XFile('$selectedDirectory/$fileName.csv')]);
                          },
                        ),
                        if (videoStatus && newPath.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.videocam),
                              label: const Text('Compartilhar Arquivo de Vídeo'),
                              onPressed: () {
                                Share.shareXFiles([XFile(newPath)]);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}