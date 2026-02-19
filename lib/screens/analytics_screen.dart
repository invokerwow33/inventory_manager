import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика и отчеты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AnalyticsProvider>().loadAllStats(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Export analytics
            },
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analytics, _) {
          if (analytics.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                _buildSummaryCards(context, analytics),
                const SizedBox(height: 24),

                // Charts row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildStatusChart(context, analytics),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCategoryChart(context, analytics),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Monthly trends
                _buildMonthlyTrendsChart(context, analytics),
                const SizedBox(height: 24),

                // Department stats
                _buildDepartmentStats(context, analytics),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AnalyticsProvider analytics) {
    final stats = analytics.equipmentStats;
    final consumableStats = analytics.consumableStats;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Всего оборудования',
          value: '${stats['total'] ?? 0}',
          icon: Icons.devices,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'В использовании',
          value: '${stats['in_use'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'На складе',
          value: '${stats['in_stock'] ?? 0}',
          icon: Icons.warehouse,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'Общая стоимость',
          value: '${(stats['totalValue'] ?? 0).toStringAsFixed(0)} ₽',
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
        _SummaryCard(
          title: 'Расходники',
          value: '${consumableStats['total'] ?? 0}',
          icon: Icons.inventory_2,
          color: Colors.teal,
        ),
        _SummaryCard(
          title: 'Критический запас',
          value: '${consumableStats['lowStock'] ?? 0}',
          icon: Icons.warning,
          color: consumableStats['lowStock'] > 0 ? Colors.red : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatusChart(BuildContext context, AnalyticsProvider analytics) {
    final data = analytics.getEquipmentStatusChartData();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статус оборудования',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: data,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: data.map((section) => _LegendItem(
                color: section.color,
                title: section.title,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, AnalyticsProvider analytics) {
    final data = analytics.categoryData;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'По категориям',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...data.take(5).map((item) => _CategoryBar(
              category: item['category'],
              count: item['count'],
              total: data.fold(0, (sum, d) => sum + (d['count'] as int)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendsChart(BuildContext context, AnalyticsProvider analytics) {
    final data = analytics.getMonthlyMovementsChartData();
    final maxY = analytics.monthlyData.isEmpty
        ? 10.0
        : analytics.monthlyData
            .map((d) => (d['movements'] as int).toDouble())
            .reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Динамика за последние 12 месяцев',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barGroups: data,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= analytics.monthlyData.length) {
                            return const SizedBox.shrink();
                          }
                          final month = analytics.monthlyData[index]['month'] as String;
                          return Text(
                            month.substring(5),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.blue, title: 'Все перемещения'),
                SizedBox(width: 16),
                _LegendItem(color: Colors.orange, title: 'Выдачи'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentStats(BuildContext context, AnalyticsProvider analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика по отделам',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Отдел')),
                  DataColumn(label: Text('Оборудование'), numeric: true),
                  DataColumn(label: Text('Сотрудники'), numeric: true),
                  DataColumn(label: Text('Стоимость'), numeric: true),
                ],
                rows: analytics.departmentData.map((dept) => DataRow(
                  cells: [
                    DataCell(Text(dept['department'])),
                    DataCell(Text('${dept['equipment']}')),
                    DataCell(Text('${dept['employees']}')),
                    DataCell(Text('${(dept['value'] as double).toStringAsFixed(0)} ₽')),
                  ],
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String title;

  const _LegendItem({required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String category;
  final int count;
  final int total;

  const _CategoryBar({
    required this.category,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: Theme.of(context).textTheme.bodyMedium),
              Text('$count', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
