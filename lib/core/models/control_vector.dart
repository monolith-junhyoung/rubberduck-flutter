class ControlVector {
  const ControlVector({
    required this.x,
    required this.y,
    required this.active,
  });

  final double x;
  final double y;
  final bool active;

  double get magnitude {
    final value = (x * x) + (y * y);
    return value <= 0 ? 0 : value.sqrt();
  }

  bool get isIdle => !active || magnitude == 0;

  ControlVector copyWith({
    double? x,
    double? y,
    bool? active,
  }) {
    return ControlVector(
      x: x ?? this.x,
      y: y ?? this.y,
      active: active ?? this.active,
    );
  }
}

extension on num {
  double sqrt() => this < 0 ? 0 : (this as double).pow(0.5);

  double pow(double exponent) {
    return exponent == 0.5 ? _sqrt(toDouble()) : toDouble();
  }

  static double _sqrt(double value) {
    if (value <= 0) {
      return 0;
    }

    var guess = value;
    for (var i = 0; i < 8; i++) {
      guess = 0.5 * (guess + (value / guess));
    }
    return guess;
  }
}
