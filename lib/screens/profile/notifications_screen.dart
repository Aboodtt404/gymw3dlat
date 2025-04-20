import 'package:flutter/material.dart';
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _workoutReminders = true;
  bool _nutritionReminders = true;
  bool _waterReminders = true;
  bool _progressUpdates = true;
  TimeOfDay _workoutTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _nutritionTime = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _waterTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _workoutReminders = prefs.getBool('workout_reminders') ?? true;
        _nutritionReminders = prefs.getBool('nutrition_reminders') ?? true;
        _waterReminders = prefs.getBool('water_reminders') ?? true;
        _progressUpdates = prefs.getBool('progress_updates') ?? true;

        final workoutHour = prefs.getInt('workout_reminder_hour') ?? 8;
        final workoutMinute = prefs.getInt('workout_reminder_minute') ?? 0;
        _workoutTime = TimeOfDay(hour: workoutHour, minute: workoutMinute);

        final nutritionHour = prefs.getInt('nutrition_reminder_hour') ?? 7;
        final nutritionMinute = prefs.getInt('nutrition_reminder_minute') ?? 30;
        _nutritionTime =
            TimeOfDay(hour: nutritionHour, minute: nutritionMinute);

        final waterHour = prefs.getInt('water_reminder_hour') ?? 9;
        final waterMinute = prefs.getInt('water_reminder_minute') ?? 0;
        _waterTime = TimeOfDay(hour: waterHour, minute: waterMinute);

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('workout_reminders', _workoutReminders);
      await prefs.setBool('nutrition_reminders', _nutritionReminders);
      await prefs.setBool('water_reminders', _waterReminders);
      await prefs.setBool('progress_updates', _progressUpdates);

      await prefs.setInt('workout_reminder_hour', _workoutTime.hour);
      await prefs.setInt('workout_reminder_minute', _workoutTime.minute);

      await prefs.setInt('nutrition_reminder_hour', _nutritionTime.hour);
      await prefs.setInt('nutrition_reminder_minute', _nutritionTime.minute);

      await prefs.setInt('water_reminder_hour', _waterTime.hour);
      await prefs.setInt('water_reminder_minute', _waterTime.minute);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    TimeOfDay? selectedTime;
    TimeOfDay initialTime;

    switch (type) {
      case 'workout':
        initialTime = _workoutTime;
        break;
      case 'nutrition':
        initialTime = _nutritionTime;
        break;
      case 'water':
        initialTime = _waterTime;
        break;
      default:
        return;
    }

    selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null && mounted) {
      setState(() {
        switch (type) {
          case 'workout':
            _workoutTime = selectedTime!;
            break;
          case 'nutrition':
            _nutritionTime = selectedTime!;
            break;
          case 'water':
            _waterTime = selectedTime!;
            break;
        }
      });
      _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Settings',
                    style: Styles.subheadingStyle,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildNotificationCard(
                    title: 'Workout Reminders',
                    subtitle: 'Daily reminder to complete your workout',
                    icon: Icons.fitness_center,
                    value: _workoutReminders,
                    onChanged: (value) {
                      setState(() => _workoutReminders = value);
                      _savePreferences();
                    },
                    time: _workoutTime,
                    onTimeTap: () => _selectTime(context, 'workout'),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildNotificationCard(
                    title: 'Nutrition Reminders',
                    subtitle: 'Reminders to log your meals',
                    icon: Icons.restaurant_menu,
                    value: _nutritionReminders,
                    onChanged: (value) {
                      setState(() => _nutritionReminders = value);
                      _savePreferences();
                    },
                    time: _nutritionTime,
                    onTimeTap: () => _selectTime(context, 'nutrition'),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildNotificationCard(
                    title: 'Water Reminders',
                    subtitle: 'Reminders to track your water intake',
                    icon: Icons.water_drop,
                    value: _waterReminders,
                    onChanged: (value) {
                      setState(() => _waterReminders = value);
                      _savePreferences();
                    },
                    time: _waterTime,
                    onTimeTap: () => _selectTime(context, 'water'),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildNotificationCard(
                    title: 'Progress Updates',
                    subtitle: 'Weekly progress and achievement notifications',
                    icon: Icons.trending_up,
                    value: _progressUpdates,
                    onChanged: (value) {
                      setState(() => _progressUpdates = value);
                      _savePreferences();
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    TimeOfDay? time,
    VoidCallback? onTimeTap,
  }) {
    return Container(
      decoration: Styles.cardDecoration,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Styles.primaryColor),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Styles.primaryColor,
            ),
          ),
          if (value && time != null && onTimeTap != null)
            InkWell(
              onTap: onTimeTap,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reminder Time',
                      style:
                          Styles.bodyStyle.copyWith(color: Styles.subtleText),
                    ),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: Styles.bodyStyle,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
