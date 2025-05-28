import 'dart:developer';
import 'package:fire_prevent_system/models/control_data.dart';
import 'package:fire_prevent_system/models/sensor_data.dart';
import 'package:fire_prevent_system/models/temperature_point.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  final DatabaseReference sensorRef = FirebaseDatabase.instance.ref('sensors');
  final _dateFormat = DateFormat("yyyy-MM-dd'T'HH_mm_ss");
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

  // Lấy dữ liệu trung bình 7 ngày gần nhất từ Firebase
  Future<Map<String, double>> getLast7DaysAverages() async {
    final today = DateTime.now();
    final past7Days = List.generate(7, (i) {
      return DateFormat('yyyy-MM-dd').format(today.subtract(Duration(days: i)));
    });

    final snapshot = await FirebaseDatabase.instance.ref('averages').get();
    if (!snapshot.exists) return {};

    final Map data = snapshot.value as Map;
    final Map<String, double> result = {};

    for (final date in past7Days) {
      if (data.containsKey(date)) {
        result[date] = double.tryParse(data[date].toString()) ?? 0;
      }
    }
    return result;
  }
  Future<Map<String, double>> get4HourAverages(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final snapshot = await FirebaseDatabase.instance.ref('daily_4hour_avg/$dateKey').get();

    if (!snapshot.exists) {
      log(" Không có dữ liệu cho ngày $dateKey");
      return {};
    }

    final Map data = snapshot.value as Map;
    final Map<String, double> fourHourAverages = {};

    data.forEach((key, value) {
      if (key is String && value != null) {
        final doubleVal = double.tryParse(value.toString());
        if (doubleVal != null) {
          fourHourAverages[key] = doubleVal;
        }
      }
    });

    for (int start = 0; start < 24; start += 4) {
      final key = '${start.toString().padLeft(2, '0')}-${(start + 4).toString().padLeft(2, '0')}';
      fourHourAverages.putIfAbsent(key, () => 0.0);
    }

    return fourHourAverages;
  }

// Tính nhiệt độ trung bình từng ngày và lưu lên Firebase
  Future<void> calculateAndUploadDailyAverage() async {
    final snapshot = await FirebaseDatabase.instance.ref('sensors').get();
    if (!snapshot.exists) return;

    final Map<String, dynamic> allData = Map<String, dynamic>.from(snapshot.value as Map);
    final Map<String, List<double>> groupedTemps = {};

    allData.forEach((key, value) {
      final date = _dateFormat.parse(key);
      final dateKey = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final sensor = Map<String, dynamic>.from(value);
      final temp = sensor['temperature']?.toDouble();
      if (temp != null) {
        groupedTemps.putIfAbsent(dateKey, () => []).add(temp);
      }
    });

    final averagesRef = FirebaseDatabase.instance.ref('averages');

    for (var entry in groupedTemps.entries) {
      final temps = entry.value;
      final avg = temps.reduce((a, b) => a + b) / temps.length;

      log(' Ngày: ${entry.key}');
      log(' Nhiệt độ: $temps');
      log(' Trung bình: $avg');

      await averagesRef.child(entry.key).set(avg);
    }
  }

  Future<void> calculate4HourAveragesForDay(DateTime selectedDate) async {
    final snapshot = await FirebaseDatabase.instance.ref('sensors').get();
    if (!snapshot.exists) return;

    final Map<String, dynamic> allData = Map<String, dynamic>.from(snapshot.value as Map);
    final Map<int, List<double>> fourHourGroups = {};

    allData.forEach((key, value) {
      final date = _dateFormat.parse(key);

      if (date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day) {

        final sensor = Map<String, dynamic>.from(value);
        final temp = sensor['temperature']?.toDouble();

        if (temp != null) {
          int block = date.hour ~/ 4; //  chia theo block 4 tiếng
          fourHourGroups.putIfAbsent(block, () => []).add(temp);
        }
      }
    });

    final String dayKey = "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final averagesRef = FirebaseDatabase.instance.ref('daily_4hour_avg/$dayKey');

    for (int block = 0; block < 6; block++) {
      final temps = fourHourGroups[block];
      final startHour = block * 4;
      final endHour = startHour + 4;
      final timeRange = "${startHour.toString().padLeft(2, '0')}-${endHour.toString().padLeft(2, '0')}";

      if (temps != null && temps.isNotEmpty) {
        final avg = temps.reduce((a, b) => a + b) / temps.length;

        print("[$dayKey | $timeRange]: $avg °C");
        await averagesRef.child(timeRange).set(avg);
      } else {
        print("[$dayKey | $timeRange]: Không có dữ liệu");
      }
    }
  }
}