import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_history_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutHistoryProvider()),
      ],
      child: MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}



// import 'package:fitnessapp/FitnessTrackerScreen.dart';
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const FitnessTrackerScreen(),
//     );
//   }
// }



//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:socket_io_client/socket_io_client.dart' as io;
// import 'package:socket_io_client/socket_io_client.dart';
// import 'package:intl/intl.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Fitness App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         primarySwatch: Colors.grey,
//         brightness: Brightness.dark,
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.black,
//           elevation: 0,
//         ),
//         cardTheme: CardTheme(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(30),
//             ),
//           ),
//         ),
//       ),
//       darkTheme: ThemeData(
//         primarySwatch: Colors.grey,
//         brightness: Brightness.dark,
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.black,
//           elevation: 0,
//         ),
//         cardTheme: CardTheme(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(30),
//             ),
//           ),
//         ),
//       ),
//       themeMode: ThemeMode.system,
//       home: const FitnessTrackerScreen(),
//     );
//   }
// }
//
// class FitnessTrackerScreen extends StatefulWidget {
//   const FitnessTrackerScreen({Key? key}) : super(key: key);
//
//   @override
//   _FitnessTrackerScreenState createState() => _FitnessTrackerScreenState();
// }
//
// class _FitnessTrackerScreenState extends State<FitnessTrackerScreen> with WidgetsBindingObserver {
//   bool _isSessionActive = false;
//   bool _isConnected = false;
//   late CameraController _cameraController;
//   List<CameraDescription> _cameras = [];
//   bool _isCameraInitialized = false;
//   bool _isFrontCamera = true;
//   int _selectedCameraIndex = 0;
//
//   // Update these URLs to match your server configuration
//   final String httpUrl = 'http://Server-IP:5000/api'; // Replace with your server IP
//   final String wsUrl = 'http://Server-IP:5000'; // Replace with your server IP
//
//   // Create socket instance
//   late io.Socket socket;
//
//   Map<String, dynamic> _workoutStats = {
//     'workout_time': 0,
//     'exercises': {
//       'right_curls': 0,
//       'left_curls': 0,
//       'squats': 0,
//       'pushups': 0,
//       'lunges': 0,
//       'plank_seconds': 0,
//     }
//   };
//
//   String? _processedImageBase64;
//   Timer? _frameProcessingTimer;
//   Timer? _workoutTimeUpdateTimer;
//   DateTime? _workoutStartTime;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeSocketConnection();
//     _initializeCamera();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // App state changed - handle camera appropriately
//     if (state == AppLifecycleState.inactive) {
//       // App inactive: dispose of camera
//       if (_isCameraInitialized) {
//         _cameraController.dispose();
//         _isCameraInitialized = false;
//       }
//
//       // End session if active
//       if (_isSessionActive) {
//         _endWorkoutSession();
//       }
//     } else if (state == AppLifecycleState.resumed) {
//       // App resumed: reinitialize camera
//       if (!_isCameraInitialized) {
//         _initializeCamera();
//       }
//     }
//   }
//
//   void _initializeSocketConnection() {
//     socket = io.io(wsUrl, OptionBuilder()
//         .setTransports(['websocket'])
//         .disableAutoConnect()
//         .build());
//
//     socket.on('connect', (_) {
//       print('Socket connected: ${socket.id}');
//       setState(() {
//         _isConnected = true;
//       });
//     });
//
//     socket.on('disconnect', (_) {
//       print('Socket disconnected');
//       setState(() {
//         _isConnected = false;
//         if (_isSessionActive) {
//           _isSessionActive = false;
//           _resetWorkoutStats();
//           _stopTimers();
//         }
//       });
//     });
//
//     socket.on('workout_update', (data) {
//       if (mounted) {
//         setState(() {
//           _workoutStats = {
//             'workout_time': data['workout_time'],
//             'exercises': data['exercises'],
//           };
//           _processedImageBase64 = data['processed_image'];
//         });
//       }
//     });
//
//     socket.on('session_started', (data) {
//       print('Session started: $data');
//       if (mounted) {
//         setState(() {
//           _isSessionActive = true;
//           _workoutStartTime = DateTime.now();
//         });
//         _startWorkoutTimeUpdate();
//       }
//     });
//
//     socket.on('session_ended', (data) {
//       print('Session ended: $data');
//       if (mounted) {
//         setState(() {
//           _isSessionActive = false;
//           _processedImageBase64 = null;
//         });
//         _stopTimers();
//         _showWorkoutSummary(data['summary']);
//       }
//     });
//
//     socket.on('error', (data) {
//       print('Socket error: $data');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${data['message']}')),
//       );
//     });
//
//     socket.connect();
//   }
//
//   Future<void> _initializeCamera() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras.isEmpty) {
//         print('No cameras found');
//         return;
//       }
//
//       // Default to front camera if available
//       _selectedCameraIndex = _findCameraIndex(true);
//
//       await _initCameraController(_cameras[_selectedCameraIndex]);
//     } catch (e) {
//       print('Error initializing camera: $e');
//     }
//   }
//
//   int _findCameraIndex(bool frontCamera) {
//     // Find the index of front or back camera
//     return _cameras.indexWhere((camera) =>
//     frontCamera ? camera.lensDirection == CameraLensDirection.front
//         : camera.lensDirection == CameraLensDirection.back);
//   }
//
//   Future<void> _initCameraController(CameraDescription cameraDescription) async {
//     _cameraController = CameraController(
//       cameraDescription,
//       ResolutionPreset.medium,
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.jpeg,
//     );
//
//     try {
//       await _cameraController.initialize();
//
//       if (mounted) {
//         setState(() {
//           _isCameraInitialized = true;
//           _isFrontCamera = cameraDescription.lensDirection == CameraLensDirection.front;
//         });
//       }
//     } catch (e) {
//       print('Error initializing camera controller: $e');
//     }
//   }
//
//   Future<void> _switchCamera() async {
//     if (_cameras.length <= 1) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No other camera available')),
//       );
//       return;
//     }
//
//     if (_isCameraInitialized) {
//       await _cameraController.dispose();
//     }
//
//     // Toggle between front and back camera
//     _isFrontCamera = !_isFrontCamera;
//     _selectedCameraIndex = _findCameraIndex(_isFrontCamera);
//
//     // Initialize the new camera
//     await _initCameraController(_cameras[_selectedCameraIndex]);
//   }
//
//   void _resetWorkoutStats() {
//     setState(() {
//       _workoutStats = {
//         'workout_time': 0,
//         'exercises': {
//           'right_curls': 0,
//           'left_curls': 0,
//           'squats': 0,
//           'pushups': 0,
//           'lunges': 0,
//           'plank_seconds': 0,
//         }
//       };
//       _processedImageBase64 = null;
//       _workoutStartTime = null;
//     });
//   }
//
//   Future<void> _startWorkoutSession() async {
//     if (!_isConnected) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Not connected to server. Trying to reconnect...')),
//       );
//       socket.connect();
//       return;
//     }
//
//     try {
//       // Start session via WebSocket
//       socket.emit('start_session', {'user_name': 'flutter_user'});
//
//       // Start sending frames for processing
//       _startFrameProcessing();
//     } catch (e) {
//       print('Error starting workout session: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to start workout session: $e')),
//       );
//     }
//   }
//
//   Future<void> _endWorkoutSession() async {
//     if (!_isSessionActive) return;
//
//     try {
//       // Stop timers
//       _stopTimers();
//
//       // End session via WebSocket
//       socket.emit('end_session', {});
//
//       setState(() {
//         _isSessionActive = false;
//         _processedImageBase64 = null;
//       });
//     } catch (e) {
//       print('Error ending workout session: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to end workout session: $e')),
//       );
//     }
//   }
//
//   void _startFrameProcessing() {
//     _frameProcessingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
//       if (!_isSessionActive || !_isCameraInitialized) return;
//
//       try {
//         // Take picture
//         final XFile image = await _cameraController.takePicture();
//
//         // Read file as bytes
//         final bytes = await File(image.path).readAsBytes();
//
//         // Convert to base64
//         final base64Image = base64Encode(bytes);
//
//         // Send to server via WebSocket
//         socket.emit('process_frame', {'image': base64Image});
//
//         // Delete temporary file
//         await File(image.path).delete();
//       } catch (e) {
//         print('Error capturing frame: $e');
//       }
//     });
//   }
//
//   void _startWorkoutTimeUpdate() {
//     // Update the workout time based on the start time rather than relying on server
//     _workoutTimeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!_isSessionActive || _workoutStartTime == null) return;
//
//       final elapsed = DateTime.now().difference(_workoutStartTime!).inSeconds;
//       setState(() {
//         // Only update the timer locally
//         _workoutStats['workout_time'] = elapsed;
//       });
//     });
//   }
//
//   void _stopTimers() {
//     _frameProcessingTimer?.cancel();
//     _workoutTimeUpdateTimer?.cancel();
//   }
//
//   void _showWorkoutSummary(Map<String, dynamic> summary) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Workout Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Date: ${summary['date']}'),
//               const SizedBox(height: 8),
//               Text('Total Time: ${_formatTime(summary['total_time_sec'])}'),
//               const SizedBox(height: 8),
//               Text('Calories Burned: ${summary['calories_burned'].toStringAsFixed(1)}'),
//               const SizedBox(height: 16),
//               const Text('Exercises:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//               const SizedBox(height: 8),
//               _buildSummaryItem('Right Curls', summary['data']['right_curl']),
//               _buildSummaryItem('Left Curls', summary['data']['left_curl']),
//               _buildSummaryItem('Squats', summary['data']['squat']),
//               _buildSummaryItem('Push-ups', summary['data']['pushup']),
//               _buildSummaryItem('Lunges', summary['data']['lunge']),
//               _buildSummaryItem('Plank', summary['data']['plank'], isTime: true),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Close'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _navigateToHistory();
//             },
//             child: const Text('View History'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSummaryItem(String title, int value, {bool isTime = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title, style: const TextStyle(fontSize: 16)),
//           Text(
//             isTime ? _formatTime(value) : value.toString(),
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _navigateToHistory() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => WorkoutHistoryScreen(apiUrl: httpUrl),
//       ),
//     );
//   }
//
//   String _formatTime(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _stopTimers();
//     if (_isCameraInitialized) {
//       _cameraController.dispose();
//     }
//     socket.disconnect();
//     socket.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('AI Fitness Tracker'),
//         actions: [
//           if (_isCameraInitialized)
//             IconButton(
//               icon: const Icon(Icons.flip_camera_android),
//               onPressed: _isSessionActive ? null : _switchCamera,
//               tooltip: 'Switch Camera',
//             ),
//           IconButton(
//             icon: const Icon(Icons.history),
//             onPressed: _navigateToHistory,
//             tooltip: 'Workout History',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 3,
//             child: _buildCameraPreview(),
//           ),
//           Expanded(
//             flex: 2,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Theme.of(context).brightness == Brightness.dark
//                     ? Colors.black87
//                     : Colors.blue.shade100,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(24),
//                   topRight: Radius.circular(24),
//                 ),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Workout Time',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             Text(
//                               _formatTime(_workoutStats['workout_time']),
//                               style: const TextStyle(
//                                 fontSize: 26,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                         _buildConnectionStatus(),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Expanded(
//                       child: GridView.count(
//                         crossAxisCount: 2,
//                         childAspectRatio: 2.0,
//                         mainAxisSpacing: 12,
//                         crossAxisSpacing: 12,
//                         children: [
//                           _buildExerciseCard('Right Curls', _workoutStats['exercises']['right_curls'], Icons.fitness_center),
//                           _buildExerciseCard('Left Curls', _workoutStats['exercises']['left_curls'], Icons.fitness_center),
//                           _buildExerciseCard('Squats', _workoutStats['exercises']['squats'], Icons.accessibility_new),
//                           _buildExerciseCard('Push-ups', _workoutStats['exercises']['pushups'], Icons.accessibility_new),
//                           _buildExerciseCard('Lunges', _workoutStats['exercises']['lunges'], Icons.directions_walk),
//                           _buildExerciseCard('Plank', _workoutStats['exercises']['plank_seconds'], Icons.hourglass_bottom, isTime: true),
//                           SizedBox(
//                             height: 50,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _isCameraInitialized
//             ? (_isSessionActive ? _endWorkoutSession : _startWorkoutSession)
//             : null,
//         icon: Icon(_isSessionActive ? Icons.stop : Icons.play_arrow),
//         label: Text(_isSessionActive ? 'End Workout' : 'Start Workout'),
//         backgroundColor: _isSessionActive ? Colors.red : Colors.green,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
//
//   Widget _buildConnectionStatus() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: _isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             _isConnected ? Icons.wifi : Icons.wifi_off,
//             size: 16,
//             color: _isConnected ? Colors.green : Colors.red,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             _isConnected ? 'Connected' : 'Disconnected',
//             style: TextStyle(
//               color: _isConnected ? Colors.green : Colors.red,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCameraPreview() {
//     if (!_isCameraInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (_processedImageBase64 != null && _isSessionActive) {
//       return Stack(
//         fit: StackFit.expand,
//         children: [
//           Image.memory(
//             base64Decode(_processedImageBase64!),
//             fit: BoxFit.contain,
//           ),
//           Positioned(
//             top: 16,
//             right: 16,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.black54,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Text(
//                 'AI Mode Active',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     }
//
//     return CameraPreview(_cameraController);
//   }
//
//   Widget _buildExerciseCard(String title, int value, IconData icon, {bool isTime = false}) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(icon, size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             FittedBox(
//               fit: BoxFit.scaleDown,
//               child: Text(
//                 isTime ? _formatTime(value) : value.toString(),
//                 style: const TextStyle(
//                   fontSize: 12, // You can increase this
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class WorkoutHistoryScreen extends StatefulWidget {
//   final String apiUrl;
//
//   const WorkoutHistoryScreen({Key? key, required this.apiUrl}) : super(key: key);
//
//   @override
//   _WorkoutHistoryScreenState createState() => _WorkoutHistoryScreenState();
// }
//
// class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
//   List<dynamic> _workoutHistory = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchWorkoutHistory();
//   }
//
//   Future<void> _fetchWorkoutHistory() async {
//     try {
//       final response = await http.get(
//         Uri.parse('${widget.apiUrl}/get_workout_history?user_name=flutter_user'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _workoutHistory = data['history'];
//           _isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load workout history');
//       }
//     } catch (e) {
//       print('Error fetching workout history: $e');
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load workout history: $e')),
//       );
//     }
//   }
//
//   String _formatDate(String dateStr) {
//     try {
//       final date = DateTime.parse(dateStr);
//       return DateFormat('MMM d, yyyy').format(date);
//     } catch (e) {
//       return dateStr;
//     }
//   }
//
//   String _formatTime(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Workout History'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _workoutHistory.isEmpty
//           ? const Center(child: Text('No workout history found'))
//           : ListView.builder(
//         itemCount: _workoutHistory.length,
//         itemBuilder: (context, index) {
//           final workout = _workoutHistory[_workoutHistory.length - 1 - index];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ExpansionTile(
//               title: Text(
//                 'Workout on ${_formatDate(workout['date'])}',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text(
//                 'Duration: ${_formatTime(workout['total_time_sec'])} • Calories: ${workout['calories_burned'].toStringAsFixed(1)}',
//               ),
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Exercise Summary',
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 8),
//                       _buildHistoryItem('Right Curls', workout['data']['right_curl']),
//                       _buildHistoryItem('Left Curls', workout['data']['left_curl']),
//                       _buildHistoryItem('Squats', workout['data']['squat']),
//                       _buildHistoryItem('Push-ups', workout['data']['pushup']),
//                       _buildHistoryItem('Lunges', workout['data']['lunge']),
//                       _buildHistoryItem('Plank', workout['data']['plank'], isTime: true),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildHistoryItem(String title, int value, {bool isTime = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title),
//           Text(
//             isTime ? _formatTime(value) : value.toString(),
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
// }