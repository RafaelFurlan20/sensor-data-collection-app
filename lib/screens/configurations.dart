import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:explorer/constants.dart';

class Configurations extends StatefulWidget {
  const Configurations({Key? key}) : super(key: key);

  @override
  State<Configurations> createState() => _ConfigurationsState();
}

class _ConfigurationsState extends State<Configurations> {
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
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

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initValues();
  }

  Future<void> initValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

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

    setState(() {
      isLoading = false;
    });
  }

  bool stringToBool(String value) => value.toLowerCase() == 'true';

  String splitByCapsCapitalizeRemoveLast(String inputString) {
    if (inputString.isEmpty) {
      return ''; // Handle empty input
    }

    RegExp regExp = RegExp(r"(?<=[a-z])(?=[A-Z])");
    List<String> splitWords = inputString.split(regExp);

    if (splitWords.length <= 1) {
      return ''; // Handle single word/no split
    }

    splitWords.removeLast(); // Remove last word

    // Capitalize the first letter of each remaining word
    List<String> capitalizedWords = splitWords.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      } else {
        return ''; // Handle empty words (if any)
      }
    }).toList();

    return capitalizedWords.join(' '); // Join with spaces
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            title: const Text(
              'Configurações',
              style: TextStyle(
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
                      // Ação ao pressionar a imagem
                    },
                  ),
                ),
              ),
            ],
          ),
          body: isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
              : SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Câmera e Mídia'),
                    _buildCameraSection(),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Sensores de Movimento'),
                    _buildChoiceSwitch('acelerometerStatus', acelerometerStatus),
                    _buildChoiceSwitch('gyroscopeStatus', gyroscopeStatus),
                    _buildChoiceSwitch('acelerometerRawStatus', acelerometerRawStatus),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Sensores de Localização'),
                    _buildChoiceSwitch('magnometerStatus', magnometerStatus),
                    _buildChoiceSwitch('altimeterStatus', altimeterStatus),
                    _buildChoiceSwitch('coordinatesStatus', coordinatesStatus),
                    _buildChoiceSwitch('speedStatus', speedStatus),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return Column(
      children: [
        _buildChoiceCard(
          title: 'Câmera',
          description: 'Habilitar acesso à câmera',
          value: cameraStatus,
          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            cameraStatus = value;
            await prefs.setBool('cameraStatus', value);
            setState(() {});
          },
        ),
        if (cameraStatus)
          Container(
            margin: const EdgeInsets.only(top: 8, left: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSubOption(
                  title: 'Foto',
                  value: photoStatus,
                  onChanged: (value) async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    photoStatus = value;
                    if (photoStatus == true) {
                      videoStatus = false;
                    } else {
                      videoStatus = true;
                    }
                    await prefs.setBool('videoStatus', videoStatus);
                    await prefs.setBool('photoStatus', value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _buildSubOption(
                  title: 'Vídeo',
                  value: videoStatus,
                  onChanged: (value) async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    videoStatus = value;
                    if (videoStatus == true) {
                      photoStatus = false;
                    } else {
                      photoStatus = true;
                    }
                    await prefs.setBool('photoStatus', photoStatus);
                    await prefs.setBool('videoStatus', value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubOption({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        Switch(
          activeColor: Colors.white,
          activeTrackColor: Colors.deepPurpleAccent,
          inactiveThumbColor: Colors.white70,
          inactiveTrackColor: Colors.grey.withOpacity(0.5),
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              activeColor: Colors.white,
              activeTrackColor: Colors.deepPurpleAccent,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.grey.withOpacity(0.5),
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceSwitch(String string, bool switchValue) {
    String displayName = splitByCapsCapitalizeRemoveLast(string);
    String description = _getDescription(string);

    return _buildChoiceCard(
      title: displayName,
      description: description,
      value: switchValue,
      onChanged: (value) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool(string, value);
        setState(() {
          switch (string) {
            case 'acelerometerStatus':
              acelerometerStatus = value;
              break;
            case 'gyroscopeStatus':
              gyroscopeStatus = value;
              break;
            case 'acelerometerRawStatus':
              acelerometerRawStatus = value;
              break;
            case 'magnometerStatus':
              magnometerStatus = value;
              break;
            case 'altimeterStatus':
              altimeterStatus = value;
              break;
            case 'coordinatesStatus':
              coordinatesStatus = value;
              break;
            case 'speedStatus':
              speedStatus = value;
              break;
          }
        });
      },
    );
  }

  String _getDescription(String sensorType) {
    switch (sensorType) {
      case 'acelerometerStatus':
        return 'Medição de movimentos lineares';
      case 'gyroscopeStatus':
        return 'Medição de rotação do dispositivo';
      case 'acelerometerRawStatus':
        return 'Dados brutos do acelerômetro';
      case 'magnometerStatus':
        return 'Detecção de campos magnéticos';
      case 'altimeterStatus':
        return 'Medição de altitude';
      case 'coordinatesStatus':
        return 'Localização geográfica';
      case 'speedStatus':
        return 'Medição de velocidade';
      default:
        return '';
    }
  }
}