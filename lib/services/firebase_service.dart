import 'dart:developer';

import 'package:fire_prevent_system/models/control_data.dart';
import 'package:fire_prevent_system/models/sensor_data.dart';
import 'package:fire_prevent_system/models/temperature_point.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  final DatabaseReference sensorRef = FirebaseDatabase.instance.ref('sensors');
  final DatabaseReference controlRef = FirebaseDatabase.instance.ref(
    'controls',
  );

  Stream<SensorData> get sensorStream {
    return sensorRef.limitToLast(1).onValue.map((event) {
      final value = event.snapshot.value;
      log('Sensor data received: $value');
      final dataMap = Map<String, dynamic>.from(value as Map);

      final entry = dataMap.entries.first;
      final id = entry.key.replaceAll('_', ':');

      final data = Map<String, dynamic>.from(entry.value as Map);
      return SensorData.fromMap(data..['timestamp'] = id);
    });
  }

  Stream<List<TemperaturePoint>> get temperatureStream {
    return sensorRef
        .orderByKey()
        .startAt(_todayStart())
        .limitToLast(10)
        .onValue
        .map((event) {
          final raw = event.snapshot.value;
          if (raw == null) return [];

          final Map<String, dynamic> map = Map<String, dynamic>.from(
            raw as Map,
          );

          return map.entries.map((e) {
              final rawKey = e.key.replaceAll('_', ':');
              log('Raw key: $rawKey');
              final time = DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(rawKey);
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

  Stream<ControlData> get controlStream {
    return controlRef.onValue.map((event) {
      final value = event.snapshot.value;
      log('Control data received: $value');

      if (value == null) {
        return ControlData(fan: false, pump: false, door: false);
      }

      final dataMap = Map<String, dynamic>.from(value as Map);
      return ControlData.fromMap(dataMap);
    });
  }

  Future<void> controlDevice(String device, bool status) async {
    await FirebaseDatabase.instance.ref('controls/$device').set(status);
  }
}
