import 'package:fire_prevent_system/models/sensor_data.dart';
import 'package:fire_prevent_system/services/firebase_service.dart';
import 'package:fire_prevent_system/services/notification_service.dart';
import 'package:fire_prevent_system/widgets/realtime_chart.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseService _firebase = FirebaseService();
  bool _fanStatus = false;
  bool _pumpStatus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fire Alert Dashboard')),
      body: StreamBuilder<SensorData>(
        stream: _firebase.sensorStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            _checkForAlerts(data);
            return Column(
              children: [
                _buildCard('🔥 Fire Detected', data.fire),
                _buildCard('💨 Gas Leak', data.gas),
                _buildCard('🌡 Temperature: ${data.temperature}°C', false),
                _buildSwitch('Pump (Water)', _pumpStatus, (val) {
                  setState(() => _pumpStatus = val);
                  _firebase.controlDevice('pump', val);
                }),
                _buildSwitch('Fan', _fanStatus, (val) {
                  setState(() => _fanStatus = val);
                  _firebase.controlDevice('fan', val);
                }),
                Expanded(child: RealtimeTemperatureChart(service: _firebase)),
              ],
            );
          } else {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return Center(child: Text('No data available'));
            }
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildCard(String title, bool active) {
    return Card(
      color: active ? Colors.red.shade100 : Colors.green.shade100,
      margin: EdgeInsets.all(10),
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
    if (data.fire) {
      NotificationService.show('🔥 Fire Alert', 'Fire has been detected!');
    } else if (data.gas) {
      NotificationService.show('💨 Gas Leak', 'Gas leak detected!');
    }
  }
}
