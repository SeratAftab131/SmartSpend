import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_repository.dart';
import '../models/settings_model.dart';

class ChartsScreen extends StatelessWidget {
  final DataRepository _dataRepository = DataRepository();

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box<SettingsModel>('settings');
    final SettingsModel? settings =
        settingsBox.isNotEmpty ? settingsBox.getAt(0) : null;

    return FutureBuilder<Map<String, double>>(
      future: _dataRepository.getCategoryTotals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No expenses to display'));
        }

        final categoryTotals = snapshot.data!;
        final categories = categoryTotals.keys.toList();
        final totals = categoryTotals.values.toList();

        // Define a list of colors
        final List<Color> barColors = [
          Colors.indigo,
          Colors.teal,
          Colors.orange,
          Colors.pink,
          Colors.green,
          Colors.blueGrey,
          Colors.deepPurple,
          Colors.redAccent,
          Colors.amber,
          Colors.cyan,
        ];

        // Determine max Y and interval for neat spacing
        double maxY =
            totals.reduce((a, b) => a > b ? a : b) * 1.2; // Add 20% padding

        // Include budget limits in maxY calculation if they exist
        if (settings != null) {
          for (var category in categories) {
            final limit = settings.getCategoryLimit(category);
            if (limit > maxY) {
              maxY = limit * 1.2;
            }
          }
        }

        final double yInterval = maxY / 5.0; // 5 labels on Y-axis

        return Scaffold(
          appBar: AppBar(title: Text('Expenses Chart')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (settings != null)
                  _buildBudgetLegend(settings, categoryTotals),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: true),
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: yInterval,
                            getTitlesWidget: (value, meta) {
                              return Text('\$${value.toInt()}');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double index, _) {
                              if (index.toInt() >= categories.length)
                                return const SizedBox();
                              return Text(categories[index.toInt()]);
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(categories.length, (i) {
                        final category = categories[i];
                        final total = totals[i];
                        final limit = settings?.getCategoryLimit(category) ?? 0;

                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: total.toDouble(),
                              color: barColors[i % barColors.length],
                              width: 20,
                            ),
                            // Add budget limit line
                            if (settings != null && limit > 0)
                              BarChartRodData(
                                toY: limit.toDouble(),
                                color: Colors.red.withOpacity(0.3),
                                width: 22,
                                borderRadius: BorderRadius.zero,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetLegend(
      SettingsModel settings, Map<String, double> categoryTotals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...categoryTotals.entries.map((entry) {
              final category = entry.key;
              final total = entry.value;
              final limit = settings.getCategoryLimit(category);
              final percentage = (total / limit * 100).clamp(0, 100);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(category),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 100
                              ? Colors.red
                              : percentage > 75
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '\$${total.toStringAsFixed(0)}/\$${limit.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
