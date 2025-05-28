import 'package:fire_prevent_system/models/temperature_point.dart';
import 'package:fire_prevent_system/services/firebase_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RealtimeTemperatureChart extends StatelessWidget {
  final FirebaseService service;
  const RealtimeTemperatureChart({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TemperaturePoint>>(
      stream: service.temperatureStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: Text('No temperature data today.'));
        }
        final points = snapshot.data!;

        final spots =
            points
                .asMap()
                .entries
                .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
                .toList();

        final colors =
            points.map((e) {
              if (e.value > 40) return Colors.red;
              if (e.value > 30) return Colors.orange;
              return Colors.green;
            }).toList();

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) return Container();
                      final time = points[idx].time;
                      return Text(
                        '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              minY: 0,
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  gradient: LinearGradient(colors: colors),
                  belowBarData: BarAreaData(show: false),
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
