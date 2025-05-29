import 'dart:developer';

import 'package:fire_prevent_system/models/sensor_data.dart';
import 'package:fire_prevent_system/services/firebase_service.dart';
import 'package:fire_prevent_system/services/notification_service.dart';
import 'package:fire_prevent_system/widgets/realtime_chart.dart';
import 'package:fire_prevent_system/pages/history_page.dart';
import 'package:flutter/material.dart';

import '../models/control_data.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final FirebaseService _firebase = FirebaseService();
  bool _fanStatus = false;
  bool _pumpStatus = false;
  bool _doorStatus = false;

  @override
  void initState() {
    super.initState();
    NotificationService.requestPermission();
    _firebase.calculateAndUploadDailyAverage();
  }


  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardContent(),
      const HistoryPage(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Fire Prevent System', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold , fontSize: 25),), backgroundColor: Colors.blue.shade100,),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.blue.shade100,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return StreamBuilder<SensorData>(
      stream: _firebase.sensorStream,
      builder: (context, sensorSnapshot) {
        return StreamBuilder<ControlData>(
          stream: _firebase.controlStream,
          builder: (context, controlSnapshot) {
            if (sensorSnapshot.connectionState == ConnectionState.waiting ||
                controlSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (sensorSnapshot.hasError || controlSnapshot.hasError) {
              return Center(child: Text('Có lỗi khi lấy dữ liệu'));
            }

            if (sensorSnapshot.hasData && controlSnapshot.hasData) {
              final data = sensorSnapshot.data!;
              final control = controlSnapshot.data!;
              _checkForAlerts(data);
              _fanStatus = control.fan;
              _pumpStatus = control.pump;
              _doorStatus = control.door;

              return Column(
                children: [
                  _buildCard('🔥 Fire Detected', data.fire),
                  _buildCard('💨 Gas Leak', data.gas),
                  _buildCard('🌡 Temperature: ${data.temperature}°C', false),
                  _buildSwitch('Pump (Water)', _pumpStatus, (val) {
                    _firebase.controlDevice('pump', val);
                  }),
                  _buildSwitch('Fan', _fanStatus, (val) {
                    _firebase.controlDevice('fan', val);
                  }),
                  _buildSwitch('Door', _doorStatus, (val) {
                    _firebase.controlDevice('door', val);
                  }),
                  Expanded(child: RealtimeTemperatureChart(service: _firebase)),
                ],
              );
            }

            return Center(child: Text('Không có dữ liệu'));
          },
        );
      },
    );
  }


  Widget _buildCard(String title, bool active) {
    return Card(
      color: active ? Colors.red.shade100 : Colors.green.shade100,
      margin:  EdgeInsets.all(10),
      child: ListTile(
        title: Text(title),
        trailing: Icon(
          active ? Icons.warning : Icons.check,
          color: active ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  void _checkForAlerts(SensorData data) {
    try {
      if (data.fire) {
        log('Fire detected: ${data.fire}');
        NotificationService.show('🔥 Fire Alert', 'Fire has been detected!');
      } else if (data.gas) {
        NotificationService.show('💨 Gas Leak', 'Gas leak detected!');
      }
    } catch (e) {
      log('Error checking for alerts: $e');
    }
  }
}
