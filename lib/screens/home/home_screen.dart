import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';
import '../auth/login_screen.dart';
import '../workout/active_workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await SupabaseService().getCurrentUser();
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Styles.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Styles.backgroundGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Styles.primaryColor),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeCard(),
                            const SizedBox(height: AppConstants.defaultPadding),
                            _buildDailySummaryCard(),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Text(
                              'Quick Actions',
                              style: Styles.subheadingStyle,
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            _buildQuickActionsGrid(),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Text(
                              'Your Progress',
                              style: Styles.subheadingStyle,
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            _buildProgressCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final greeting = _getGreeting();
    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Styles.bodyStyle.copyWith(color: Styles.subtleText),
                ),
                const SizedBox(height: AppConstants.smallPadding / 2),
                Text(
                  _userData?['name'] ?? 'Athlete',
                  style: Styles.headingStyle,
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Styles.primaryColor.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.person,
              color: Styles.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Summary',
            style: Styles.subheadingStyle,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.local_fire_department,
                value: '0',
                label: 'Calories',
                color: Colors.orange,
              ),
              _buildSummaryItem(
                icon: Icons.restaurant_menu,
                value: '0',
                label: 'Foods',
                color: Styles.primaryColor,
              ),
              _buildSummaryItem(
                icon: Icons.water_drop,
                value: '0',
                label: 'Water',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppConstants.smallPadding,
      crossAxisSpacing: AppConstants.smallPadding,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          icon: Icons.add_circle_outline,
          title: 'Log Food',
          color: Styles.primaryColor,
          onTap: () {
            // Navigate to food logging screen
          },
        ),
        _buildActionCard(
          icon: Icons.fitness_center,
          title: 'Start Workout',
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActiveWorkoutScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          icon: Icons.water_drop_outlined,
          title: 'Log Water',
          color: Colors.blue,
          onTap: () {
            // Navigate to water logging screen
          },
        ),
        _buildActionCard(
          icon: Icons.insights_outlined,
          title: 'View Stats',
          color: Colors.purple,
          onTap: () {
            // Navigate to stats screen
          },
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Goal',
                    style: Styles.subheadingStyle,
                  ),
                  Text(
                    '0 / 2000 kcal',
                    style: Styles.bodyStyle.copyWith(color: Styles.subtleText),
                  ),
                ],
              ),
              Text(
                '0%',
                style: Styles.headingStyle.copyWith(
                  color: Styles.primaryColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          LinearProgressIndicator(
            value: 0,
            backgroundColor: Styles.cardBackground,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Styles.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          value,
          style: Styles.headingStyle.copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: Styles.bodyStyle.copyWith(
            color: Styles.subtleText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: Styles.cardDecoration,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              title,
              style: Styles.bodyStyle.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
