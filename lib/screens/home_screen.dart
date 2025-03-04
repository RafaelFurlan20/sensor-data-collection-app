import 'package:flutter/material.dart';
import 'package:explorer/elements/buttom_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
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
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 60.0,
                        backgroundColor: Colors.transparent,
                        backgroundImage: AssetImage('images/upscalar.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Explorer',
                    style: TextStyle(
                      fontSize: 42.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RobotoSlab',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'STARTING THE FUTURE',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'RobotoSlab',
                      letterSpacing: 5.0,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: 1,
                    width: 100,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 50),
                  _buildActionButton(
                    icon: Icons.play_arrow_rounded,
                    text: 'Executar',
                    onTap: () {
                      Navigator.pushNamed(context, '/calibrate');
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.info_outline_rounded,
                    text: 'Mais informações',
                    onTap: () {
                      Navigator.pushNamed(context, '/more_info'); // Updated with correct route
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.settings_rounded,
                    text: 'Configurações',
                    onTap: () {
                      Navigator.pushNamed(context, '/configurations');
                    },
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
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
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 20),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}