enum HomeTextSize {
  compact,
  standard,
  large,
}

extension HomeTextSizeX on HomeTextSize {
  String get label {
    switch (this) {
      case HomeTextSize.compact:
        return 'Compact';
      case HomeTextSize.standard:
        return 'Standard';
      case HomeTextSize.large:
        return 'Large';
    }
  }

  String get shortLabel {
    switch (this) {
      case HomeTextSize.compact:
        return 'Small';
      case HomeTextSize.standard:
        return 'Medium';
      case HomeTextSize.large:
        return 'Large';
    }
  }

  double get scale {
    switch (this) {
      case HomeTextSize.compact:
        return 1.0;
      case HomeTextSize.standard:
        return 1.12;
      case HomeTextSize.large:
        return 1.26;
    }
  }
}
