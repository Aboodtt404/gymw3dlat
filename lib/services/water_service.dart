import 'supabase_service.dart';

class WaterService {
  final _supabase = SupabaseService.client;

  Future<void> logWater(double amount) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('water_logs').insert({
        'user_id': userId,
        'amount': amount,
        'logged_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to log water: $e');
    }
  }

  Future<double> getTodayWaterAmount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final startOfDay = DateTime.now().toUtc().subtract(
            Duration(
              hours: DateTime.now().hour,
              minutes: DateTime.now().minute,
              seconds: DateTime.now().second,
              milliseconds: DateTime.now().millisecond,
              microseconds: DateTime.now().microsecond,
            ),
          );

      final response = await _supabase
          .from('water_logs')
          .select('amount')
          .eq('user_id', userId)
          .gte('logged_at', startOfDay.toIso8601String());

      double total = 0;
      for (final log in response) {
        total += (log['amount'] as num).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Failed to get water amount: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWaterHistory(int days) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final startDate =
          DateTime.now().subtract(Duration(days: days)).toUtc().subtract(
                Duration(
                  hours: DateTime.now().hour,
                  minutes: DateTime.now().minute,
                  seconds: DateTime.now().second,
                ),
              );

      final response = await _supabase
          .from('water_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startDate.toIso8601String())
          .order('logged_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get water history: $e');
    }
  }
}
