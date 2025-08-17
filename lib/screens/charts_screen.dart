import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ExpenseModel>('expenses');

    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    for (int i = 0; i < box.length; i++) {
      final expense = box.getAt(i);
      if (expense != null) {
        categoryTotals.update(
          expense.category,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
    }

    final categories = categoryTotals.keys.toList();
    final totals = categoryTotals.values.toList();

    // Define a list of colors (repeats if categories > colors.length)
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

    return Scaffold(
      appBar: AppBar(title: Text('Expenses Chart')),
      body: categoryTotals.isEmpty
          ? Center(child: Text('No expenses to display'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: totals.isEmpty
                      ? 0
                      : (totals.reduce((a, b) => a > b ? a : b) * 1.2),
                  barTouchData: BarTouchData(enabled: true),
                  gridData: FlGridData(show: true), // keep grid
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();
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
                          toY: totals[i],
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
  }
}
