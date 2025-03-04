import 'dart:math';

class RotationCalculator {
  double deltaTime; // Delta de tempo entre as amostras do giroscópio

  RotationCalculator(this.deltaTime);

  List<List<double>> calculateRotationMatrix(List<List<double>> gyroData) {
    List<List<double>> rotationMatrix = [
      [1.0, 0.0, 0.0],
      [0.0, 1.0, 0.0],
      [0.0, 0.0, 1.0],
    ];

    for (int i = 1; i < gyroData.length; i++) {
      List<double> deltaOrientation = gyroData[i].map((e) => e * deltaTime).toList();
      List<List<double>> rotationMatrixDelta = _calculateRotationMatrixDelta(deltaOrientation);
      rotationMatrix = _multiplyMatrices(rotationMatrix, rotationMatrixDelta);
    }

    return rotationMatrix;
  }

  List<List<double>> _calculateRotationMatrixDelta(List<double> deltaOrientation) {
    double angle = deltaOrientation.reduce((a, b) => a + b);
    List<double> axis = deltaOrientation.map((e) => e / angle).toList();

    double x = axis[0];
    double y = axis[1];
    double z = axis[2];

    double c = cos(angle);
    double s = sin(angle);
    double t = 1 - c;

    return [
      [t * x * x + c, t * x * y - s * z, t * x * z + s * y],
      [t * x * y + s * z, t * y * y + c, t * y * z - s * x],
      [t * x * z - s * y, t * y * z + s * x, t * z * z + c],
    ];
  }

  List<List<double>> _multiplyMatrices(List<List<double>> a, List<List<double>> b) {
    int rowsA = a.length;
    int colsA = a[0].length;
    int colsB = b[0].length;

    List<List<double>> result = List.generate(rowsA, (_) => List.filled(colsB, 0.0));
    for (int i = 0; i < rowsA; i++) {
      for (int j = 0; j < colsB; j++) {
        double sum = 0.0;
        for (int k = 0; k < colsA; k++) {
          sum += a[i][k] * b[k][j];
        }
        result[i][j] = sum;
      }
    }
    return result;
  }

  List<List<double>> applyRotationMatrix(List<List<double>> rotationMatrix, List<List<double>> accelData) {
    List<List<double>> alignedAccelData = [];

    for (int i = 0; i < accelData.length; i++) {
      List<double> accelVector = accelData[i];
      List<double> alignedAccelVector = _multiplyMatrixVector(rotationMatrix, accelVector);
      alignedAccelData.add(alignedAccelVector);
    }

    return alignedAccelData;
  }

  List<double> _multiplyMatrixVector(List<List<double>> matrix, List<double> vector) {
    List<double> result = List.filled(matrix.length, 0.0);

    for (int i = 0; i < matrix.length; i++) {
      double sum = 0.0;
      for (int j = 0; j < vector.length; j++) {
        sum += matrix[i][j] * vector[j];
      }
      result[i] = sum;
    }

    return result;
  }
}
