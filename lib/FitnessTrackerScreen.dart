import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

class FitnessTrackerScreen extends StatefulWidget {
  const FitnessTrackerScreen({Key? key}) : super(key: key);

  @override
  _FitnessTrackerScreenState createState() => _FitnessTrackerScreenState();
}

class _FitnessTrackerScreenState extends State<FitnessTrackerScreen> {
  bool _isSessionActive = false;
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  // API URL - Change this to your API's address
  // final String apiUrl = 'http://localhost:5000/api';
  // For Android emulator
  final String apiUrl = 'http://YOUR_SERVER_IP:5000/api';
  // final String apiUrl = 'http://localhost:5000/api';  // For iOS simulator
  // final String apiUrl = 'http://your-server-ip:5000/api';  // For real device

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
  Timer? _statsUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[0],  // Use front camera if available
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _startWorkoutSession() async {
    try {
      final url = '$apiUrl/start_session';
      print('Attempting to connect to: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_name': 'flutter_user'}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _isSessionActive = true;
        });
        _startWorkoutTimer();
      }
    } catch (e) {
      print('Detailed error info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start workout session: $e')),
      );
    }
  }

  Future<void> _endWorkoutSession() async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/end_session'),
      );

      if (response.statusCode == 200) {
        // Cancel timers
        _frameProcessingTimer?.cancel();
        _statsUpdateTimer?.cancel();

        setState(() {
          _isSessionActive = false;
          _processedImageBase64 = null;
        });

        // Show workout summary
        final data = jsonDecode(response.body);
        _showWorkoutSummary(data['summary']);
      } else {
        throw Exception('Failed to end workout session');
      }
    } catch (e) {
      print('Error ending workout session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end workout session')),
      );
    }
  }

  Future<void> _processFrame() async {
    if (!_isSessionActive || !_isCameraInitialized) return;

    try {
      // Take picture
      final XFile image = await _cameraController.takePicture();

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/process_frame'));

      // Add file to request
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _workoutStats = {
            'workout_time': data['workout_time'],
            'exercises': data['exercises'],
          };
          _processedImageBase64 = data['processed_image'];
        });

        // Delete temporary image file
        File(image.path).delete();
      } else {
        print('Error processing frame: ${response.body}');
      }
    } catch (e) {
      print('Error in frame processing: $e');
    }
  }

  Future<void> _updateWorkoutStats() async {
    if (!_isSessionActive) return;

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/get_workout_stats'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _workoutStats = {
            'workout_time': data['workout_time'],
            'exercises': data['exercises'],
          };
        });
      }
    } catch (e) {
      print('Error updating workout stats: $e');
    }
  }

  void _startWorkoutTimer() {
    _frameProcessingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _processFrame();
    });

    _statsUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _updateWorkoutStats();
    });
  }

  void _showWorkoutSummary(Map<String, dynamic> summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Workout Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${summary['date']}'),
              Text('Total Time: ${summary['total_time_sec']} seconds'),
              Text('Calories Burned: ${summary['calories_burned'].toStringAsFixed(1)}'),
              SizedBox(height: 10),
              Text('Exercises:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Right Curls: ${summary['data']['right_curl']}'),
              Text('Left Curls: ${summary['data']['left_curl']}'),
              Text('Squats: ${summary['data']['squat']}'),
              Text('Push-ups: ${summary['data']['pushup']}'),
              Text('Lunges: ${summary['data']['lunge']}'),
              Text('Plank: ${summary['data']['plank']} seconds'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _frameProcessingTimer?.cancel();
    _statsUpdateTimer?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fitness Tracker'),
      ),
      body: _isCameraInitialized ? Column(
        children: [
          Expanded(
            flex: 3,
            child: _processedImageBase64 != null && _isSessionActive
                ? Image.memory(
              base64Decode(_processedImageBase64!),
              fit: BoxFit.contain,
            )
                : CameraPreview(_cameraController),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Time: ${_formatTime(_workoutStats['workout_time'])}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          _buildExerciseCard('Right Curls', _workoutStats['exercises']['right_curls']),
                          _buildExerciseCard('Left Curls', _workoutStats['exercises']['left_curls']),
                          _buildExerciseCard('Squats', _workoutStats['exercises']['squats']),
                          _buildExerciseCard('Push-ups', _workoutStats['exercises']['pushups']),
                          _buildExerciseCard('Lunges', _workoutStats['exercises']['lunges']),
                          _buildExerciseCard('Plank', _workoutStats['exercises']['plank_seconds'], isTime: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ) : Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isSessionActive) {
            _endWorkoutSession();
          } else {
            _startWorkoutSession();
          }
        },
        child: Icon(_isSessionActive ? Icons.stop : Icons.play_arrow),
      ),
    );
  }

  Widget _buildExerciseCard(String title, int value, {bool isTime = false}) {
    return Card(
      color: Colors.blueAccent,
      child: Center(
        child: Text(
          '$title: ${isTime ? _formatTime(value) : value}',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
