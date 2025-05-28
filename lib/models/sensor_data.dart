class SensorData {
  final double temperature;
  final bool fire;
  final bool gas;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.fire,
    required this.gas,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] ?? 0).toDouble(),
      fire: map['fire'] ?? false,
      gas: map['gas'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
