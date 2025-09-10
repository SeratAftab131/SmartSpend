import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_repository.dart';

class ChartsScreen extends StatelessWidget {
  final DataRepository _dataRepository = DataRepository();

  @override
  Widget build(BuildContext context) {
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
        final double maxY =
            totals.reduce((a, b) => a > b ? a : b) * 1.2; // Add 20% padding
        final double yInterval = maxY / 5.0; // 5 labels on Y-axis

        return Scaffold(
          appBar: AppBar(title: Text('Expenses Chart')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: totals[i].toDouble(),
                        color: barColors[i % barColors.length],
                        width: 20,
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
