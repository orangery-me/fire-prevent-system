import 'dart:developer';

import 'package:fire_prevent_system/models/sensor_data.dart';
import 'package:fire_prevent_system/models/temperature_point.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference ref = FirebaseDatabase.instance.ref('sensors');

  Stream<SensorData> get sensorStream {
    return ref.limitToLast(1).onValue.map((event) {
      final value = event.snapshot.value;
      log('Sensor data received: $value');
      final dataMap = Map<String, dynamic>.from(value as Map);

      final entry = dataMap.entries.first;
      final id = entry.key;

      final data = Map<String, dynamic>.from(entry.value as Map);
      return SensorData.fromMap(data..['timestamp'] = id);
    });
  }

  Stream<List<TemperaturePoint>> get temperatureStream {
    return ref.orderByKey().startAt(_todayStart()).limitToLast(10).onValue.map((
      event,
    ) {
      final raw = event.snapshot.value;
      if (raw == null) return [];

      final Map<String, dynamic> map = Map<String, dynamic>.from(raw as Map);

      return map.entries.map((e) {
          final time = DateTime.parse(e.key);
          final data = Map<String, dynamic>.from(e.value);
          return TemperaturePoint(
            time: time,
            value: data['temperature']?.toDouble() ?? 0,
          );
        }).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
    });
  }

  String _todayStart() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T00:00:00';
  }

  Future<void> controlDevice(String device, bool status) async {
    await FirebaseDatabase.instance.ref('controls/$device').set(status);
  }
}
