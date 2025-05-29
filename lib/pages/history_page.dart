import 'dart:developer';
import 'package:fire_prevent_system/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirebaseService _firebase = FirebaseService();

  Map<String, double> _averages7Days = {};
  Map<String, double> _averagesHourly = {};

  DateTime? _selectedDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load7DaysData();
    _loadHourlyData(DateTime.now());
  }

  Future<void> _load7DaysData() async {
    setState(() {
      _loading = true;
      _selectedDate = null;
      _averagesHourly.clear();
    });
    final data = await _firebase.getLast7DaysAverages();

    final now = DateTime.now();
    final List<String> last7Days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    });

    final Map<String, double> filledData = {
      for (var day in last7Days) day: data[day] ?? 0,
    };

    setState(() {
      _averages7Days = filledData;
      _loading = false;
    });
  }
  Future<void> _loadHourlyData(DateTime date) async {
    setState(() {
      _loading = true;
      _averagesHourly.clear();
      _selectedDate = date;
    });

    final fetchedData = await _firebase.get4HourAverages(date);

    final fixedOrderKeys = [
      "00-04", "04-08", "08-12", "12-16", "16-20", "20-24"
    ];

    Map<String, double> filledHourlyData = {};
    for (var key in fixedOrderKeys) {
      filledHourlyData[key] = fetchedData[key] ?? 0.0;
      log("[$date | $key]: ${fetchedData[key] != null ? '${fetchedData[key]} °C' : 'Không có dữ liệu'}");
    }

    log("Dữ liệu 4 tiếng trung bình của ngày ${DateFormat('yyyy-MM-dd').format(date)}:");
    filledHourlyData.forEach((key, value) {
      log("$key: ${value.toStringAsFixed(2)} °C");
    });

    setState(() {
      _averagesHourly = filledHourlyData;
      _loading = false;
    });

    log("đã chạy xong hàm loadHourlyData");
  }


  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(Duration(days: 30)),
      lastDate: now,
    );
    if (picked != null) {
      log("Ngày đã chọn: ${picked.toIso8601String()}");

      // Tính và lưu nhiệt độ trung bình 3 tiếng một lần cho ngày đã chọn
      await _firebase.calculate4HourAveragesForDay(picked);
      // Sau khi tính xong, tải dữ liệu để hiển thị
      await _loadHourlyData(picked);
    }
  }


  Widget _build7DaysChart() {
    final barWidth = 16.0;
    final maxTemp = (_averages7Days.values.isEmpty)
        ? 0
        : _averages7Days.values.reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            BarChart(
              BarChartData(
                maxY: maxTemp + 5,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _averages7Days.length)
                          return SizedBox();
                        return Text(
                          _averages7Days.keys.elementAt(index).substring(5),
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: _averages7Days.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final temp = entry.value.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                          toY: temp, color: Colors.orange, width: barWidth),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: LayoutBuilder(builder: (context, constraints) {
                  final barCount = _averages7Days.length;
                  final spacePerBar = constraints.maxWidth / barCount;

                  return Row(
                    children: _averages7Days.entries.map((entry) {
                      final index =
                      _averages7Days.keys.toList().indexOf(entry.key);
                      final temp = entry.value;
                      final yPos = (1 - temp / (maxTemp + 5)) *
                          (constraints.maxHeight - 20);
                      return Container(
                        width: spacePerBar,
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: yPos),
                          child: Text(
                            temp.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHourlyChart() {
    final barWidth = 12.0;
    final maxTemp = (_averagesHourly.values.isEmpty)
        ? 0
        : _averagesHourly.values.reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            BarChart(
              BarChartData(
                maxY: maxTemp + 5,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _averagesHourly.length)
                          return SizedBox();
                        // Hiện giờ: vd "00h", "01h", ...
                        return Text(
                          '${_averagesHourly.keys.elementAt(index)}h',
                          style: TextStyle(fontSize: 9),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: _averagesHourly.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final temp = entry.value.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                          toY: temp, color: Colors.green, width: barWidth),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: LayoutBuilder(builder: (context, constraints) {
                  final barCount = _averagesHourly.length;
                  final spacePerBar = constraints.maxWidth / barCount;

                  return Row(
                    children: _averagesHourly.entries.map((entry) {
                      final index =
                      _averagesHourly.keys.toList().indexOf(entry.key);
                      final temp = entry.value;
                      final yPos = (1 - temp / (maxTemp + 5)) *
                          (constraints.maxHeight - 20);
                      return Container(
                        width: spacePerBar,
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: yPos),
                          child: Text(
                            temp.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lịch sử nhiệt độ',
          style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 20
          ),
        ),
        backgroundColor: Colors.blue.shade100,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0), // Clề phải
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: _pickDate,
              child: Text('Xem lịch sử'),
            ),
          ),
        ],
      ),

      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhiệt độ trung bình 7 ngày qua',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            SizedBox(height: 300, child: _build7DaysChart()),

            SizedBox(height: 24),
            if (_selectedDate != null) ...[
              Text(
                'Nhiệt độ trung bình theo khung giờ ngày ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              SizedBox(height: 300, child: _buildHourlyChart()),
            ]
          ],
        ),
      ),

    );
  }
}
