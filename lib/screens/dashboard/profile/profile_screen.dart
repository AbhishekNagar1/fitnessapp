import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_history_provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../auth/start_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final workoutHistory = Provider.of<WorkoutHistoryProvider>(context);
    final username = authProvider.username ?? 'User';
    final email = authProvider.email ?? 'user@example.com';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        'https://ui-avatars.com/api/?name=User&background=0D8ABC&color=fff',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // username,
                          'Abhishek',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stats Section
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: _buildStatsCard(
              //           context,
              //           'Total Workouts',
              //           '48',
              //           Icons.fitness_center_outlined,
              //         ),
              //       ),
              //       const SizedBox(width: 16),
              //       Expanded(
              //         child: _buildStatsCard(
              //           context,
              //           'Calories Burned',
              //           '12.4k',
              //           Icons.local_fire_department_outlined,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),
              // Clear History Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    if (workoutHistory.isLoading)
                      const CircularProgressIndicator()
                    else if (workoutHistory.error != null)
                      Text(
                        workoutHistory.error!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: workoutHistory.workoutHistory.isEmpty
                            ? null
                            : () => _showClearHistoryDialog(context),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          workoutHistory.workoutHistory.isEmpty
                              ? 'No Workout History'
                              : 'Clear Workout History',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Settings Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 350,
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
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Settings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingItem(
                            context,
                            'Account Settings',
                            Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildSettingItem(
                            context,
                            'Notifications',
                            Icons.notifications_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildSettingItem(
                            context,
                            'Privacy',
                            Icons.lock_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildSettingItem(
                            context,
                            'Help & Support',
                            Icons.help_outline,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              await Provider.of<AuthProvider>(context, listen: false).logout();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const StartScreen()),
                                (route) => false,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Logout',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.red,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.red,
                                    size: 20,
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Workout history cleared successfully')),
              );
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

  Widget _buildStatsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        // TODO: Implement setting item tap
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
} 