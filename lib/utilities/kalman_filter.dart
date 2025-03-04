class KalmanFilter {
  double _q; // Covariância do ruído do processo
  double _r; // Covariância do ruído da medição
  double _x; // Valor estimado
  double _p; // Covariância do erro de estimativa
  double _k; // Ganho de Kalman

  KalmanFilter({
    required double initialQ,
    required double initialR,
    required double initialValue,
  })  : _q = initialQ,
        _r = initialR,
        _x = initialValue,
        _p = 1.0,
        _k = 0.0;

  double filter(double measurement) {
    // Predição
    _p = _p + _q;

    // Atualização
    _k = _p / (_p + _r);
    _x = _x + _k * (measurement - _x);
    _p = (1 - _k) * _p;

    // Adaptação: atualizar covariâncias
    _adaptCovariances(measurement);

    return _x;
  }

  void _adaptCovariances(double measurement) {
    double innovation = measurement - _x;
    _q = (1 - _k) * _q + _k * (innovation * innovation);
    _r = (1 - _k) * _r + _k * (innovation * innovation);
  }
}
