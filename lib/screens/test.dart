import 'dart:math';

class ExponentialSmoothing {
  double _alpha;
  double _lastValue;

  ExponentialSmoothing({double alpha = 0.2}) :
        _alpha = alpha,
        _lastValue = double.nan; // Valor padrão que indica que _lastValue ainda não foi definido

  // Função para suavizar os dados
  double smooth(double observation) {
    if (_lastValue.isNaN) {
      _lastValue = observation;
      return observation;
    } else {
      // Aplica a fórmula da suavização exponencial
      double smoothedValue = (_alpha * observation) + ((1 - _alpha) * _lastValue);
      _lastValue = smoothedValue;
      return smoothedValue;
    }
  }
}

void main() {
  // Exemplo de uso:
  List<double> gyroData = [1.2, 1.5, 1.8, 2.1, 1.9, 2.4]; // Dados brutos do giroscópio

  ExponentialSmoothing smoother = ExponentialSmoothing(alpha: 0.85); // Escolha um valor para alpha

  // Suaviza os dados do giroscópio
  List<double> smoothedData = [];
  for (double observation in gyroData) {
    double smoothedValue = smoother.smooth(observation);
    smoothedData.add(smoothedValue);
  }

  // Imprime os dados suavizados
  print("Dados brutos: $gyroData");
  print("Dados suavizados: $smoothedData");
}
