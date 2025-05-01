import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WorkoutHistoryProvider with ChangeNotifier {
  List<Map<String, dynamic>> _workoutHistory = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get workoutHistory => _workoutHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Update these URLs to match your server configuration
  final String baseUrl = 'http://192.168.222.27:5000/api'; // Replace with your server IP

  Future<void> fetchWorkoutHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_workout_history?user_name=flutter_user'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _workoutHistory = List<Map<String, dynamic>>.from(data['history']);
        } else {
          _error = 'Failed to fetch workout history: ${data['message']}';
        }
      } else {
        _error = 'Failed to fetch workout history: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clear_history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_name': 'flutter_user'}),
      );

      if (response.statusCode == 200) {
        _workoutHistory = [];
      } else {
        _error = 'Failed to clear history: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> getWorkoutStatsForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final workouts = _workoutHistory.where((workout) => workout['date'] == dateStr).toList();

    if (workouts.isEmpty) {
      return {
        'calories': 0,
        'time': 0,
        'exercises': {
          'right_curl': 0,
          'left_curl': 0,
          'squat': 0,
          'pushup': 0,
          'lunge': 0,
          'plank': 0,
        }
      };
    }

    int totalCalories = 0;
    int totalTime = 0;
    Map<String, int> exerciseCounts = {
      'right_curl': 0,
      'left_curl': 0,
      'squat': 0,
      'pushup': 0,
      'lunge': 0,
      'plank': 0,
    };

    for (var workout in workouts) {
      // Calculate calories based on time and intensity
      final timeInMinutes = (workout['total_time_sec'] as num?)?.toInt() ?? 0 / 60;
      // Assuming moderate intensity workout burns 5 calories per minute
      totalCalories += (timeInMinutes * 5).round();
      totalTime += (workout['total_time_sec'] as num?)?.toInt() ?? 0;
      
      final exercises = workout['data'] ?? {};
      exerciseCounts['right_curl'] = (exerciseCounts['right_curl'] ?? 0) + ((exercises['right_curl'] as num?)?.toInt() ?? 0);
      exerciseCounts['left_curl'] = (exerciseCounts['left_curl'] ?? 0) + ((exercises['left_curl'] as num?)?.toInt() ?? 0);
      exerciseCounts['squat'] = (exerciseCounts['squat'] ?? 0) + ((exercises['squat'] as num?)?.toInt() ?? 0);
      exerciseCounts['pushup'] = (exerciseCounts['pushup'] ?? 0) + ((exercises['pushup'] as num?)?.toInt() ?? 0);
      exerciseCounts['lunge'] = (exerciseCounts['lunge'] ?? 0) + ((exercises['lunge'] as num?)?.toInt() ?? 0);
      exerciseCounts['plank'] = (exerciseCounts['plank'] ?? 0) + ((exercises['plank'] as num?)?.toInt() ?? 0);
    }

    return {
      'calories': totalCalories,
      'time': totalTime,
      'exercises': exerciseCounts,
    };
  }
} 