import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:explorer/main.dart';
import 'package:get/get.dart';
import 'package:explorer/utilities/calibration_controller.dart';

class Calibrate extends StatefulWidget {
  const Calibrate({super.key});

  @override
  State<Calibrate> createState() => _CalibrateState();
}

class _CalibrateState extends State<Calibrate> with RouteAware {
  final CalibrationController _calibrationController =
  Get.find<CalibrationController>();

  // Calibration states
  bool ini_calibration = false;
  bool calibration = false;
  late bool acelerometerStatus;
  late bool acelerometerRawStatus;
  late bool gyroscopeStatus;
  bool popNext = false;
  bool isLoading = true;
  int count_down = 5;

  // Angle values
  double angleY = 0;
  double angleZ = 0;
  double angleX = 0;

  // Accelerometer values
  double accelerometerX = 0;
  double accelerometerY = 0;
  double accelerometerZ = 0;

  // Lists to store angle data
  List<double> angleXList = [];
  List<double> angleYList = [];
  List<double> angleZList = [];

  // Countdown timer
  int countdown = 4; // Initial countdown time
  late Timer timer;
  Duration sensorInterval = SensorInterval.gameInterval;

  // Sensor events
  UserAccelerometerEvent? _userAccelerometerEvent;
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  bool stringToBool(String value) => value.toLowerCase() == 'true';

  Future<void> initValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    acelerometerStatus = prefs.getBool('acelerometerStatus') ?? true;
    acelerometerRawStatus = prefs.getBool('acelerometerRawStatus') ?? true;
    gyroscopeStatus = prefs.getBool('gyroscopeStatus') ?? true;

    if (acelerometerStatus == false ||
        acelerometerRawStatus == false ||
        gyroscopeStatus == false) {
      for (var subscription in _streamSubscriptions) {
        subscription.cancel();
      }
      if(!popNext){
        Navigator.pushNamed(context, '/sensors');
      }
    }

    setState(() {
      isLoading = false;
    });

    if (acelerometerStatus) {
      _streamSubscriptions.add(
        userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
              (UserAccelerometerEvent event) {
            setState(() {
              _userAccelerometerEvent = event;
            });
          },
          onError: (e) {
            showDialog(
                context: context,
                builder: (context) {
                  return const AlertDialog(
                    title: Text("Sensor Not Found"),
                    content: Text(
                        "It seems that your device doesn't support User Accelerometer Sensor"),
                  );
                });
          },
          cancelOnError: true,
        ),
      );
    }

    if (acelerometerRawStatus) {
      _streamSubscriptions.add(
        accelerometerEventStream(samplingPeriod: sensorInterval).listen(
              (AccelerometerEvent event) {
            if(ini_calibration) {
              setState(() {
                _accelerometerEvent = event;
                accelerometerX = _accelerometerEvent!.x;
                accelerometerY = _accelerometerEvent!.y;
                accelerometerZ = _accelerometerEvent!.z;

                // Calculate resultant magnitude
                double sumOfSquares = pow(accelerometerX, 2).toDouble() +
                    pow(accelerometerY, 2).toDouble() +
                    pow(accelerometerZ, 2).toDouble();

                double magnitude = sqrt(sumOfSquares);

                // Normalize accelerometer values
                double normX = accelerometerX / magnitude;
                double normY = accelerometerY / magnitude;
                double normZ = accelerometerZ / magnitude;

                // Calculate angles for each axis
                angleY = acos(normX) * (180 / pi); // Convert from radians to degrees
                angleZ = acos(normY) * (180 / pi); // Convert from radians to degrees
                angleX = acos(normZ) * (180 / pi); // Convert from radians to degrees

                angleXList.add(angleX);
                angleYList.add(angleY);
                angleZList.add(angleZ);
              });
            }
          },
          onError: (e) {
            showDialog(
                context: context,
                builder: (context) {
                  return const AlertDialog(
                    title: Text("Sensor Not Found"),
                    content: Text(
                        "It seems that your device doesn't support Accelerometer Sensor"),
                  );
                });
          },
          cancelOnError: true,
        ),
      );
    }

    if (gyroscopeStatus) {
      _streamSubscriptions.add(
        gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
              (GyroscopeEvent event) {
            setState(() {
              _gyroscopeEvent = event;
            });
          },
          onError: (e) {
            showDialog(
                context: context,
                builder: (context) {
                  return const AlertDialog(
                    title: Text("Sensor Not Found"),
                    content: Text(
                        "It seems that your device doesn't support Gyroscope Sensor"),
                  );
                });
          },
          cancelOnError: true,
        ),
      );
    }
  }

  void dispose() {
    super.dispose();

    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    routeObserver.unsubscribe(this);
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    super.didChangeDependencies();
  }

  @override
  void didPushNext() {
    super.didPushNext();
  }

  @override
  void didPopNext() {
    setState(() {
      calibration = false;
      countdown = 0;
    });
    popNext = true;
    initValues();
    super.didPopNext();
  }

  @override
  void initState() {
    super.initState();
    initValues();
  }

  void startCalibration() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        if (countdown > 0) {
          countdown -= 1;
        } else {
          timer.cancel();
          calibration = true;
          _calibrationController.setTetaX(calculateFinalAccelerometerValue(angleXList));
          _calibrationController.setTetaY(calculateFinalAccelerometerValue(angleYList));
          _calibrationController.setTetaZ(calculateFinalAccelerometerValue(angleZList));
          setState(() {
            angleXList = [];
            angleYList = [];
            angleZList = [];
          });
        }
      });
    });
  }

  double calculateFinalAccelerometerValue(List<double> data, {double threshold = 0.5}) {
    List<double> filteredData = [];

    for (int i = 0; i < data.length; i++) {
      if (i == 0 || i == data.length - 1) {
        filteredData.add(data[i]);
        continue;
      }

      // Calculate the average of the neighboring values
      double average = (data[i - 1] + data[i] + data[i + 1]) / 3.0;

      // If the difference between the current value and the average is greater than the threshold, replace with the average value
      if ((data[i] - average).abs() > threshold) {
        filteredData.add(average);
      } else {
        filteredData.add(data[i]);
      }
    }

    // Calculate the average of the filtered values
    double sum = filteredData.reduce((a, b) => a + b);
    double finalAverage = sum / filteredData.length;

    return finalAverage;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
      child: CircularProgressIndicator(),
    )
        : Container(
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Calibração',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 22,
            ),
          ),
          actions: [
            Hero(
              tag: 'logo',
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Image.asset(
                    'images/upscalar.png',
                    color: Colors.white,
                    width: 32,
                    height: 32,
                  ),
                  onPressed: () {
                    // Action when pressing the image
                  },
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                _buildCalibrationInfo(),
                const SizedBox(height: 40),

                // Fixed width container to prevent layout shifts
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: !ini_calibration
                        ? _buildStartCalibrationButton()
                        : countdown > 0
                        ? _buildCalibrationInProgress()
                        : _buildExecuteButton(),
                  ),
                ),

                const Spacer(),

                // Always maintain the same height for the bottom section
                SizedBox(
                  width: double.infinity,
                  child: !ini_calibration
                      ? _buildInstructionsCard()
                      : const SizedBox(), // Empty SizedBox with same constraint
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalibrationInfo() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            ini_calibration ? Icons.sensors : Icons.sensors_outlined,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          ini_calibration
              ? (countdown > 0
              ? 'Calibrando...'
              : 'Calibração Concluída')
              : 'Calibração do Dispositivo',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ini_calibration
              ? (countdown > 0
              ? 'Mantenha o dispositivo imóvel'
              : 'Os sensores foram calibrados com sucesso')
              : 'Posicione o dispositivo em uma superfície plana',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStartCalibrationButton() {
    return SizedBox(
      width: double.infinity, // Ensure consistent width
      child: _buildActionButton(
        icon: Icons.play_arrow_rounded,
        text: 'Iniciar Calibração',
        onTap: () {
          setState(() {
            ini_calibration = true;
            startCalibration();
          });
        },
      ),
    );
  }

  Widget _buildExecuteButton() {
    return SizedBox(
      width: double.infinity, // Ensure consistent width
      child: _buildActionButton(
        icon: Icons.check_circle_outline_rounded,
        text: 'Continuar',
        onTap: () {
          for (var subscription in _streamSubscriptions) {
            subscription.cancel();
          }
          ini_calibration = false;
          Navigator.pushNamed(context, '/sensors');
        },
      ),
    );
  }

  Widget _buildCalibrationInProgress() {
    return SizedBox(
      width: double.infinity, // Ensure consistent width
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: (4 - countdown) / 4,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text(
                  '$countdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Não mova o dispositivo',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Por que calibrar?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A calibração ajusta os sensores do dispositivo para garantir medições precisas de orientação e movimento.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white.withOpacity(0.8), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coloque o dispositivo em uma superfície plana e estável durante a calibração.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}