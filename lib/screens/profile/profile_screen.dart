import 'package:flutter/material.dart';
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';
import '../../services/supabase_service.dart';
import '../auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      await SupabaseService.client.auth.signOut();
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
            backgroundColor: Styles.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
                    SliverAppBar(
                      floating: true,
                      backgroundColor: Colors.transparent,
                      title: Text('Profile', style: Styles.headingStyle),
                      centerTitle: true,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        child: Column(
                          children: [
                            _buildProfileHeader(),
                            const SizedBox(height: AppConstants.largePadding),
                            _buildStatsCard(),
                            const SizedBox(height: AppConstants.defaultPadding),
                            _buildSettingsSection(),
                            const SizedBox(height: AppConstants.defaultPadding),
                            ListTile(
                              title: const Text('Dark Mode'),
                              trailing: Switch(
                                value: themeProvider.isDarkMode,
                                onChanged: (_) => themeProvider.toggleTheme(),
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
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Styles.primaryColor.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Styles.primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            _userData?['name'] ?? 'Athlete',
            style: Styles.headingStyle,
          ),
          const SizedBox(height: AppConstants.smallPadding / 2),
          Text(
            _userData?['email'] ?? '',
            style: Styles.bodyStyle.copyWith(color: Styles.subtleText),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Progress', style: Styles.subheadingStyle),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.calendar_today,
                value: '0',
                label: 'Days Tracked',
              ),
              _buildStatItem(
                icon: Icons.restaurant_menu,
                value: '0',
                label: 'Foods Logged',
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                value: '0',
                label: 'Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: Styles.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Styles.primaryColor),
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

  Widget _buildSettingsSection() {
    return Container(
      decoration: Styles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text('Settings', style: Styles.subheadingStyle),
          ),
          const Divider(color: Styles.cardBackground),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Styles.subtleText),
            title: Text('Edit Profile', style: Styles.bodyStyle),
            trailing: const Icon(Icons.chevron_right, color: Styles.subtleText),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) => _loadUserData());
            },
          ),
          const Divider(color: Styles.cardBackground),
          ListTile(
            leading: const Icon(Icons.notifications_outlined,
                color: Styles.subtleText),
            title: Text('Notifications', style: Styles.bodyStyle),
            trailing: const Icon(Icons.chevron_right, color: Styles.subtleText),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const Divider(color: Styles.cardBackground),
          ListTile(
            leading: const Icon(Icons.logout, color: Styles.errorColor),
            title: Text(
              'Sign Out',
              style: Styles.bodyStyle.copyWith(color: Styles.errorColor),
            ),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}
