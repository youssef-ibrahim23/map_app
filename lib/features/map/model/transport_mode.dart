enum TransportMode {
  driving,
  walking,
}

extension TransportModeExtension on TransportMode {
  String get osrmProfile {
    switch (this) {
      case TransportMode.driving:
        return 'driving';
      case TransportMode.walking:
        return 'walking';
    }
  }
}
