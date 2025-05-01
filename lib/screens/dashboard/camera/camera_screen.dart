import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_history_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isSessionActive = false;
  bool _isConnected = false;
  late CameraController _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;
  int _selectedCameraIndex = 0;

  // Update these URLs to match your server configuration
  final String httpUrl = 'http://192.168.222.27:5000/api'; // Replace with your server IP
  final String wsUrl = 'http://192.168.222.27:5000'; // Replace with your server IP

  // Create socket instance
  late io.Socket socket;

  Map<String, dynamic> _workoutStats = {
    'workout_time': 0,
    'exercises': {
      'right_curls': 0,
      'left_curls': 0,
      'squats': 0,
      'pushups': 0,
      'lunges': 0,
      'plank_seconds': 0,
    }
  };

  String? _processedImageBase64;
  Timer? _frameProcessingTimer;
  Timer? _workoutTimeUpdateTimer;
  DateTime? _workoutStartTime;

  @override
  void initState() {
    super.initState();
    _initializeSocketConnection();
    _initializeCamera();
  }

  void _initializeSocketConnection() {
    socket = io.io(wsUrl, OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    socket.on('connect', (_) {
      print('Socket connected: ${socket.id}');
      setState(() {
        _isConnected = true;
      });
    });

    socket.on('disconnect', (_) {
      print('Socket disconnected');
      setState(() {
        _isConnected = false;
        if (_isSessionActive) {
          _isSessionActive = false;
          _resetWorkoutStats();
          _stopTimers();
        }
      });
    });

    socket.on('workout_update', (data) {
      if (mounted) {
        setState(() {
          _workoutStats = {
            'workout_time': data['workout_time'],
            'exercises': data['exercises'],
          };
          _processedImageBase64 = data['processed_image'];
        });
      }
    });

    socket.on('session_started', (data) {
      print('Session started: $data');
      if (mounted) {
        setState(() {
          _isSessionActive = true;
          _workoutStartTime = DateTime.now();
        });
        _startWorkoutTimeUpdate();
      }
    });

    socket.on('session_ended', (data) {
      print('Session ended: $data');
      if (mounted) {
        setState(() {
          _isSessionActive = false;
          _processedImageBase64 = null;
        });
        _stopTimers();
        _showWorkoutSummary(data['summary']);
      }
    });

    socket.on('error', (data) {
      print('Socket error: $data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${data['message']}')),
      );
    });

    socket.connect();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print('No cameras found');
        return;
      }

      // Default to front camera if available
      _selectedCameraIndex = _findCameraIndex(true);

      await _initCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  int _findCameraIndex(bool frontCamera) {
    return _cameras.indexWhere((camera) =>
    frontCamera ? camera.lensDirection == CameraLensDirection.front
        : camera.lensDirection == CameraLensDirection.back);
  }

  Future<void> _initCameraController(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isFrontCamera = cameraDescription.lensDirection == CameraLensDirection.front;
        });
      }
    } catch (e) {
      print('Error initializing camera controller: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other camera available')),
      );
      return;
    }

    if (_isCameraInitialized) {
      await _cameraController.dispose();
    }

    // Toggle between front and back camera
    _isFrontCamera = !_isFrontCamera;
    _selectedCameraIndex = _findCameraIndex(_isFrontCamera);

    // Initialize the new camera
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  void _resetWorkoutStats() {
    setState(() {
      _workoutStats = {
        'workout_time': 0,
        'exercises': {
          'right_curls': 0,
          'left_curls': 0,
          'squats': 0,
          'pushups': 0,
          'lunges': 0,
          'plank_seconds': 0,
        }
      };
      _processedImageBase64 = null;
      _workoutStartTime = null;
    });
  }

  Future<void> _startWorkoutSession() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to server. Trying to reconnect...')),
      );
      socket.connect();
      return;
    }

    try {
      // Start session via WebSocket
      socket.emit('start_session', {'user_name': 'flutter_user'});

      // Start sending frames for processing
      _startFrameProcessing();
    } catch (e) {
      print('Error starting workout session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start workout session: $e')),
      );
    }
  }

  Future<void> _endWorkoutSession() async {
    if (!_isSessionActive) return;

    try {
      // Stop timers
      _stopTimers();

      // End session via WebSocket
      socket.emit('end_session', {});

      setState(() {
        _isSessionActive = false;
        _processedImageBase64 = null;
      });

      // Save workout data to history
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final workoutData = {
        'date': dateStr,
        'total_time_sec': _workoutStats['workout_time'],
        'data': {
          'right_curl': _workoutStats['exercises']['right_curls'],
          'left_curl': _workoutStats['exercises']['left_curls'],
          'squat': _workoutStats['exercises']['squats'],
          'pushup': _workoutStats['exercises']['pushups'],
          'lunge': _workoutStats['exercises']['lunges'],
          'plank': _workoutStats['exercises']['plank_seconds'],
        }
      };

      // Save to server
      try {
        final response = await http.post(
          Uri.parse('$httpUrl/save_workout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_name': 'flutter_user',
            'workout_data': workoutData,
          }),
        );

        if (response.statusCode == 200) {
          // Refresh workout history
          Provider.of<WorkoutHistoryProvider>(context, listen: false).fetchWorkoutHistory();
        } else {
          print('Failed to save workout data: ${response.statusCode}');
        }
      } catch (e) {
        print('Error saving workout data: $e');
      }

      // Show workout summary
      _showWorkoutSummary(workoutData);
    } catch (e) {
      print('Error ending workout session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end workout session: $e')),
      );
    }
  }

  void _startFrameProcessing() {
    _frameProcessingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isSessionActive || !_isCameraInitialized) return;

      try {
        // Take picture
        final XFile image = await _cameraController.takePicture();

        // Read file as bytes
        final bytes = await File(image.path).readAsBytes();

        // Convert to base64
        final base64Image = base64Encode(bytes);

        // Send to server via WebSocket
        socket.emit('process_frame', {'image': base64Image});

        // Delete temporary file
        await File(image.path).delete();
      } catch (e) {
        print('Error capturing frame: $e');
      }
    });
  }

  void _startWorkoutTimeUpdate() {
    // Update the workout time based on the start time rather than relying on server
    _workoutTimeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSessionActive || _workoutStartTime == null) return;

      final elapsed = DateTime.now().difference(_workoutStartTime!).inSeconds;
      setState(() {
        // Only update the timer locally
        _workoutStats['workout_time'] = elapsed;
      });
    });
  }

  void _stopTimers() {
    _frameProcessingTimer?.cancel();
    _workoutTimeUpdateTimer?.cancel();
  }

  void _showWorkoutSummary([Map<String, dynamic>? summary]) {
    final totalTime = summary != null ? summary['total_time_sec'] : _workoutStats['workout_time'];
    final totalCalories = (totalTime / 60 * 5).round(); // 5 calories per minute
    final totalExercises = summary != null 
        ? (summary['data'] as Map<String, dynamic>).values.fold(0, (sum, count) => sum + (count as num).toInt())
        : _workoutStats['exercises'].values.fold(0, (sum, count) => sum + count);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary != null) ...[
                Text('Date: ${summary['date']}'),
                const SizedBox(height: 8),
              ],
              Text('Total Time: ${_formatTime(totalTime)}'),
              const SizedBox(height: 8),
              Text('Calories Burned: $totalCalories'),
              const SizedBox(height: 8),
              Text('Total Exercises: $totalExercises'),
              const SizedBox(height: 16),
              const Text('Exercise Breakdown:'),
              const SizedBox(height: 8),
              ...(summary != null 
                  ? (summary['data'] as Map<String, dynamic>).entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${entry.key}: ${entry.value}'),
                    ))
                  : _workoutStats['exercises'].entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${entry.key}: ${entry.value}'),
                    ))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset workout stats
              setState(() {
                _workoutStats = {
                  'workout_time': 0,
                  'exercises': {
                    'right_curls': 0,
                    'left_curls': 0,
                    'squats': 0,
                    'pushups': 0,
                    'lunges': 0,
                    'plank_seconds': 0,
                  }
                };
              });
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopTimers();
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('AI Fitness Tracker'),
        ),
        actions: [
          if (_isCameraInitialized) ...[
            IconButton(
              icon: Icon(
                _isSessionActive ? Icons.stop : Icons.play_arrow,
                color: _isSessionActive ? Colors.red : Colors.green,
              ),
              onPressed: _isCameraInitialized
                  ? (_isSessionActive ? _endWorkoutSession : _startWorkoutSession)
                  : null,
              tooltip: _isSessionActive ? 'End Workout' : 'Start Workout',
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              onPressed: _isSessionActive ? null : _switchCamera,
              tooltip: 'Switch Camera',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildCameraPreview(),
          ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black87
                    : Colors.blue.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Workout Time',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatTime(_workoutStats['workout_time']),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        _buildConnectionStatus(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildExerciseCard('Right Curls', _workoutStats['exercises']['right_curls'], Icons.fitness_center),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildExerciseCard('Left Curls', _workoutStats['exercises']['left_curls'], Icons.fitness_center),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildExerciseCard('Squats', _workoutStats['exercises']['squats'], Icons.accessibility_new),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildExerciseCard('Push-ups', _workoutStats['exercises']['pushups'], Icons.accessibility_new),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildExerciseCard('Lunges', _workoutStats['exercises']['lunges'], Icons.directions_walk),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildExerciseCard('Plank', _workoutStats['exercises']['plank_seconds'], Icons.hourglass_bottom, isTime: true),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            _isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: _isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (!_isConnected) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                socket.connect();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attempting to reconnect...')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_processedImageBase64 != null && _isSessionActive) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            base64Decode(_processedImageBase64!),
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'AI Mode Active',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CameraPreview(_cameraController);
  }

  Widget _buildExerciseCard(String title, int value, IconData icon, {bool isTime = false}) {
    return Card(
      elevation: 4,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isTime ? _formatTime(value) : value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
} 