import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  // Login
  static Future<AuthResponse> login(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  // Logout
  static Future<void> logout() async {
    await client.auth.signOut();
  }

  // Get current user session
  static Session? getCurrentSession() {
    return client.auth.currentSession;
  }

  // Get current user profile data
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await client.from('profiles').select().eq('id', userId).maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // STUDENTS
  // ==========================================

  static Future<List<dynamic>> getStudents({String? classId}) async {
    var query = client.from('students').select('*, profiles(*)');
    if (classId != null && classId.isNotEmpty) {
      query = query.eq('class_id', classId) as PostgrestFilterBuilder<List<Map<String, dynamic>>>;
    }
    final data = await query;
    return data;
  }

  // ==========================================
  // CLASSES
  // ==========================================

  static Future<List<dynamic>> getClasses() async {
    final data = await client.from('classes').select();
    return data;
  }

  // ==========================================
  // ATTENDANCE
  // ==========================================

  static Future<List<dynamic>> getStudentAttendance(String studentId) async {
    final data = await client.from('attendance').select().eq('student_id', studentId);
    return data;
  }

  // ==========================================
  // FEES
  // ==========================================

  static Future<List<dynamic>> getStudentFees(String studentId) async {
    final data = await client.from('fees').select().eq('student_id', studentId);
    return data;
  }
}
