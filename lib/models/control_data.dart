class ControlData {
  final bool fan;
  final bool pump;
  final bool door;

  ControlData({required this.fan, required this.pump, required this.door});

  factory ControlData.fromMap(Map<String, dynamic> map) {
    return ControlData(
      fan: map['fan'] as bool,
      pump: map['pump'] as bool,
      door: map['door'] as bool,
    );
  }
}
