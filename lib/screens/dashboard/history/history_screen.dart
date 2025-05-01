import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  late final DateTime _firstDate;
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _firstDate = DateTime.now().subtract(const Duration(days: 6));
    _dates = List.generate(
      7,
      (index) => _firstDate.add(Duration(days: index)),
    );
    // Fetch workout history when screen is loaded
    Future.microtask(() => 
      Provider.of<WorkoutHistoryProvider>(context, listen: false).fetchWorkoutHistory()
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutHistory = Provider.of<WorkoutHistoryProvider>(context);
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Activity',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (workoutHistory.workoutHistory.isNotEmpty)
                      IconButton(
                        onPressed: () => _showClearHistoryDialog(context),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        tooltip: 'Clear History',
                      ),
                  ],
                ),
              ),
            ),
            // Calendar Strip
            SliverToBoxAdapter(
              child: Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  itemBuilder: (context, index) {
                    final date = _dates[index];
                    final isSelected = date.day == _selectedDate.day;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GlassmorphicContainer(
                          width: 60,
                          height: 80,
                          borderRadius: 16,
                          blur: 20,
                          alignment: Alignment.center,
                          border: 2,
                          linearGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                              isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.2),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(date).substring(0, 1),
                                style:
                                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date.day.toString(),
                                style:
                                    Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        context,
                        'Calories',
                        workoutHistory.getWorkoutStatsForDate(_selectedDate)['calories'].toString(),
                        Icons.local_fire_department_outlined,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatsCard(
                        context,
                        'Time',
                        _formatTime(workoutHistory.getWorkoutStatsForDate(_selectedDate)['time']),
                        Icons.timer_outlined,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Activity Graph
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 240,
                  borderRadius: 20,
                  blur: 20,
                  alignment: Alignment.bottomCenter,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.5),
                      Colors.white.withOpacity(0.2),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Activity',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
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
                                    getTitlesWidget: (value, meta) {
                                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                      if (value >= 0 && value < days.length) {
                                        return Text(
                                          days[value.toInt()],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _generateWeeklySpots(workoutHistory),
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateWeeklySpots(WorkoutHistoryProvider workoutHistory) {
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      final date = _firstDate.add(Duration(days: i));
      final stats = workoutHistory.getWorkoutStatsForDate(date);
      final totalExercises = stats['exercises'].values.fold(0, (sum, count) => sum + count);
      spots.add(FlSpot(i.toDouble(), totalExercises.toDouble()));
    }
    return spots;
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all workout history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<WorkoutHistoryProvider>(context, listen: false).clearHistory();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes < 60) {
      return '$minutes min ${remainingSeconds > 0 ? '$remainingSeconds sec' : ''}';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours hr ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
  }

  Widget _buildStatsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.bottomCenter,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.1),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 