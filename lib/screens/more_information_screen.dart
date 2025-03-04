import 'package:flutter/material.dart';

class MoreInfoScreen extends StatelessWidget {
  const MoreInfoScreen({Key? key}) : super(key: key);

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Sobre o Explorer',
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
                    // Ação ao pressionar a imagem
                  },
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroductionSection(),
                  const SizedBox(height: 24),
                  _buildFeaturesSection(),
                  const SizedBox(height: 24),
                  _buildSensorsSection(),
                  const SizedBox(height: 24),
                  _buildHowToUseSection(),
                  const SizedBox(height: 24),
                  _buildDataExportSection(),
                  const SizedBox(height: 40),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroductionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'O que é o Explorer?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Uma plataforma avançada de coleta e análise de dados sensoriais',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'O Explorer é um aplicativo projetado para cientistas, engenheiros, pesquisadores e entusiastas que necessitam capturar, monitorar e analisar dados de sensores com precisão. Combinando dados de movimento, orientação e localização com recursos de mídia, o Explorer oferece uma solução completa para aquisição de dados em campo.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recursos Principais',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.sensors_rounded,
          title: 'Coleta de Dados Multissensor',
          description: 'Capture dados simultâneos de acelerômetro, giroscópio, magnetômetro e sensores de localização com alta precisão.',
        ),
        _buildFeatureCard(
          icon: Icons.camera_alt_rounded,
          title: 'Captura de Mídia Sincronizada',
          description: 'Registre fotos ou vídeos em sincronia com a coleta de dados sensoriais para análise contextual completa.',
        ),
        _buildFeatureCard(
          icon: Icons.area_chart_rounded,
          title: 'Visualização em Tempo Real',
          description: 'Acompanhe as leituras dos sensores e orientação do dispositivo em gráficos dinâmicos para análise instantânea.',
        ),
        _buildFeatureCard(
          icon: Icons.settings_rounded,
          title: 'Calibração Avançada',
          description: 'Ferramentas de calibração que garantem a precisão das medições, compensando variações do dispositivo e ambiente.',
        ),
        _buildFeatureCard(
          icon: Icons.save_alt_rounded,
          title: 'Exportação Flexível',
          description: 'Exporte dados em formato CSV para análise posterior, compatível com ferramentas como Excel, Python e MATLAB.',
        ),
      ],
    );
  }

  Widget _buildSensorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sensores Utilizados',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSensorItem(
                icon: Icons.speed_rounded,
                title: 'Acelerômetro',
                description: 'Mede aceleração linear, gravidade e detecção de movimento em três eixos (X, Y, Z).',
              ),
              const Divider(height: 24, color: Colors.white24),
              _buildSensorItem(
                icon: Icons.rotate_90_degrees_ccw_rounded,
                title: 'Giroscópio',
                description: 'Captura rotação e orientação angular do dispositivo para análise precisa de movimentos complexos.',
              ),
              const Divider(height: 24, color: Colors.white24),
              _buildSensorItem(
                icon: Icons.compass_calibration_rounded,
                title: 'Magnetômetro',
                description: 'Funciona como bússola digital, medindo campos magnéticos para determinar direção e orientação.',
              ),
              const Divider(height: 24, color: Colors.white24),
              _buildSensorItem(
                icon: Icons.location_on_rounded,
                title: 'GPS e Altímetro',
                description: 'Fornecem dados de localização geográfica, altitude e velocidade para contextualização espacial.',
              ),
              const Divider(height: 24, color: Colors.white24),
              _buildSensorItem(
                icon: Icons.camera_alt_rounded,
                title: 'Câmera',
                description: 'Captura imagens e vídeos sincronizados com os dados dos sensores para validação visual.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowToUseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como Utilizar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildStepItem(
                number: '1',
                title: 'Calibração',
                description: 'Inicie o aplicativo e calibre os sensores colocando o dispositivo em uma superfície plana estável.',
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                number: '2',
                title: 'Configuração',
                description: 'Personalize quais sensores você deseja utilizar e ajuste a frequência de amostragem nas configurações.',
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                number: '3',
                title: 'Coleta',
                description: 'Defina a identificação para sua sessão de dados, selecione o local de armazenamento e inicie a coleta.',
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                number: '4',
                title: 'Monitoramento',
                description: 'Acompanhe os dados em tempo real no painel principal ou nos gráficos dinâmicos durante a coleta.',
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                number: '5',
                title: 'Exportação',
                description: 'Ao finalizar, salve e exporte os dados para análise posterior em seu computador ou compartilhe-os diretamente.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataExportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre os Dados Coletados',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O Explorer gera arquivos CSV estruturados contendo todos os dados sensoriais capturados, incluindo:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildBulletPoint('Timestamp preciso para cada amostra de dados'),
              _buildBulletPoint('Leituras completas de acelerômetro, giroscópio e magnetômetro (X, Y, Z)'),
              _buildBulletPoint('Ângulos de orientação do dispositivo (Θx, Θy, Θz)'),
              _buildBulletPoint('Coordenadas geográficas, altitude e velocidade'),
              _buildBulletPoint('Referências a arquivos de mídia associados (fotos/vídeos)'),
              const SizedBox(height: 16),
              Text(
                'Os dados exportados são compatíveis com ferramentas de análise como Excel, Python (pandas), MATLAB e outras plataformas de análise científica de dados.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.deepPurpleAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/calibrate');
            },
            child: const Text(
              'Começar a usar o Explorer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Desenvolvido por Rafael Furlan',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}