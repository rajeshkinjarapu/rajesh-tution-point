import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_sync_service.dart';
import '../main.dart';

class ApiService {
  static const String baseUrl = 'http://YOUR_LOCAL_IP:19998';

  static String getImageUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return '';
    final trimmed = photoUrl.trim().replaceAll('\\', '/');
    if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'undefined') return '';
    
    // Fix for localhost URLs from backend in mobile app
    if (trimmed.contains('localhost:')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.path.isNotEmpty) {
        return '$baseUrl${uri.path}';
      }
    }
    
    if (trimmed.startsWith('http') || trimmed.startsWith('data:')) return trimmed;
    if (trimmed.startsWith('/')) return '$baseUrl$trimmed';
    return '$baseUrl/$trimmed';
  }

  // Base headers for API requests
  static Map<String, String> _getHeaders({String? token, bool isMultipart = false}) {
    final headers = <String, String>{
      'ngrok-skip-browser-warning': '69420',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Get active session token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  // Login method
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'client': 'mobile',
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = data['data'] ?? data;
        String? accessToken = responseData['accessToken'];
        String? refreshToken = responseData['refreshToken'];
        var user = responseData['user'];

        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);
          if (refreshToken != null) {
            await prefs.setString('refreshToken', refreshToken);
          }
          if (user != null) {
            await prefs.setString('user', jsonEncode(user));
          }
          return {'success': true, 'user': user};
        }
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    return _performGet('/api/auth/me', 'Failed to get profile');
  }

  static Future<Map<String, dynamic>> getAppInstalls() async {
    return _performGet('/api/users/app-installs', 'Failed to fetch app installs');
  }

  static Future<Map<String, dynamic>?> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<Map<String, dynamic>> getAttendance(String studentId, {String? startDate, String? endDate}) async {
    String url = '/api/attendance/student?studentId=$studentId';
    if (startDate != null) url += '&startDate=$startDate';
    if (endDate != null) url += '&endDate=$endDate';
    return _performGet(url, 'Failed to get attendance');
  }

  static Future<Map<String, dynamic>> getFeeStatus(String studentId) async {
    return _performGet('/api/fees/student/$studentId', 'Failed to get fee status');
  }

  static Future<Map<String, dynamic>> getMarks(String studentId) async {
    return _performGet('/api/marks/student/$studentId', 'Failed to get results');
  }

  static Future<Map<String, dynamic>> getTimetable(String classId) async {
    return _performGet('/api/timetable/class?classId=$classId', 'Failed to get timetable');
  }

  static Future<Map<String, dynamic>> getTimetableStats() async {
    return _performGet('/api/timetable/stats', 'Failed to get timetable stats');
  }

  static Future<Map<String, dynamic>> getTimetableClashes() async {
    return _performGet('/api/timetable/clashes', 'Failed to get timetable clashes');
  }

  static Future<Map<String, dynamic>> getLeaveRequests() async {
    return _performGet('/api/leave', 'Failed to get leave requests');
  }

  static Future<Map<String, dynamic>> updateLeaveRequest(String id, String status) async {
    return _performPut('/api/leave/$id', {'status': status}, 'Failed to update leave request');
  }

  static Future<Map<String, dynamic>> getTeacherTimetable(String teacherId) async {
    return _performGet('/api/timetable/teacher/$teacherId', 'Failed to get teacher timetable');
  }

  static Future<Map<String, dynamic>> getAnnouncements() async {
    return _performGet('/api/announcements', 'Failed to get announcements');
  }

  static Future<Map<String, dynamic>> getAnnouncementReadStats(String id) async {
    return _performGet('/api/announcements/$id/read-stats', 'Failed to get read stats');
  }

  static Future<Map<String, dynamic>> markAnnouncementRead(String id) async {
    return _performPost('/api/announcements/$id/read', {}, 'Failed to mark announcement as read');
  }

  static Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data) async {
    return _performPost('/api/announcements', data, 'Failed to create announcement');
  }

  static Future<Map<String, dynamic>> updateAnnouncement(String id, Map<String, dynamic> data) async {
    return _performPut('/api/announcements/$id', data, 'Failed to update announcement');
  }

  static Future<Map<String, dynamic>> deleteAnnouncement(String id) async {
    return _performDelete('/api/announcements/$id', 'Failed to delete announcement');
  }

  static Future<Map<String, dynamic>> getHomework() async {
    return _performGet('/api/homework', 'Failed to get homework');
  }

  static Future<Map<String, dynamic>> getClasses() async {
    return _performGet('/api/classes', 'Failed to get classes');
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) async {
    return _performPut('/api/auth/profile', payload, 'Failed to update profile');
  }

  static Future<Map<String, dynamic>> updateAppInfo(Map<String, dynamic> payload) async {
    return _performPost('/api/users/app-info', payload, 'Failed to update app info');
  }

  static Future<Map<String, dynamic>> getClassDetails(String classId) async {
    return _performGet('/api/classes/$classId', 'Failed to get class details');
  }

  static Future<Map<String, dynamic>> getClassSubjects(String classId) async {
    return _performGet('/api/classes/$classId/subjects', 'Failed to get class subjects');
  }

  static Future<Map<String, dynamic>> getStudents({String? classId, String? search, int limit = 50}) async {
    String url = '/api/students?limit=$limit';
    if (classId != null && classId.isNotEmpty) {
      url += '&classId=$classId';
    }
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }
    return _performGet(url, 'Failed to get students');
  }

  static Future<Map<String, dynamic>> getAccountantDashboard() async {
    return _performGet('/api/dashboard/accountant', 'Failed to fetch accountant dashboard');
  }

  // ==========================================
  // STAFF / TEACHER ATTENDANCE & HR ENDPOINTS
  // ==========================================

  static Future<Map<String, dynamic>> getTeacherAttendance({String? date, int? month, int? year}) async {
    String url = '/api/teacher-attendance?limit=500';
    if (date != null) url += '&date=$date';
    if (month != null) url += '&month=$month';
    if (year != null) url += '&year=$year';
    return _performGet(url, 'Failed to fetch staff attendance');
  }

  static Future<Map<String, dynamic>> bulkMarkTeacherAttendance(Map<String, dynamic> data) async {
    return _performPost('/api/teacher-attendance/bulk-mark', data, 'Failed to mark staff attendance');
  }

  // ==========================================
  // FEE ENDPOINTS
  // ==========================================

  static Future<Map<String, dynamic>> getStudentById(String id) async {
    return _performGet('/api/students/$id', 'Failed to get student profile');
  }

  static Future<Map<String, dynamic>> getMyStudentProfile() async {
    return _performGet('/api/students/my-profile', 'Failed to get my profile');
  }

  static Future<Map<String, dynamic>> updateStudent(String id, Map<String, dynamic> payload) async {
    return _performPut('/api/students/$id', payload, 'Failed to update student');
  }

  static Future<Map<String, dynamic>> markAnnouncementAsRead(String id) async {
    return _performPost('/api/announcements/$id/read', {}, 'Failed to mark as read');
  }

  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> payload) async {
    return _performPost('/api/students', payload, 'Failed to create student');
  }

  static Future<Map<String, dynamic>> getSubjects() async {
    return _performGet('/api/subjects?limit=5000', 'Failed to get subjects');
  }

  static Future<Map<String, dynamic>> createSubject(String name, String? teacherId) async {
    return _performPost('/api/subjects', {
      'name': name,
      if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
    }, 'Failed to create subject');
  }

  static Future<Map<String, dynamic>> updateSubject(String id, String name) async {
    return _performPut('/api/subjects/$id', {'name': name}, 'Failed to update subject');
  }

  static Future<Map<String, dynamic>> deleteSubject(String id) async {
    return _performDelete('/api/subjects/$id', 'Failed to delete subject');
  }

  static Future<Map<String, dynamic>> assignTeacherToSubject(String classId, String subjectId, String teacherId) async {
    return _performPost('/api/subjects/assign-teacher', {
      'classId': classId,
      'subjectId': subjectId,
      'teacherId': teacherId,
    }, 'Failed to assign teacher');
  }

  static Future<Map<String, dynamic>> getExams({String classId = ''}) async {
    final url = classId.isNotEmpty ? '/api/exams?classId=$classId' : '/api/exams?limit=500';
    return _performGet(url, 'Failed to get exams');
  }

  static Future<Map<String, dynamic>> createExam(Map<String, dynamic> payload) async {
    return _performPost('/api/exams', payload, 'Failed to create exam');
  }

  static Future<Map<String, dynamic>> updateExam(String examId, Map<String, dynamic> payload) async {
    return _performPut('/api/exams/$examId', payload, 'Failed to update exam');
  }

  static Future<Map<String, dynamic>> deleteExam(String examId) async {
    return _performDelete('/api/exams/$examId', 'Failed to delete exam');
  }

  // ==========================================
  // ONLINE QUIZZES (STUDENT)
  // ==========================================
  static Future<Map<String, dynamic>> getOnlineExams() async {
    return _performGet('/api/online-exams/student', 'Failed to fetch online exams');
  }

  static Future<Map<String, dynamic>> getOnlineExamDetails(String id) async {
    return _performGet('/api/online-exams/$id/student', 'Failed to fetch exam details');
  }

  static Future<Map<String, dynamic>> submitOnlineExam(String id, Map<String, dynamic> answers) async {
    return _performPost('/api/online-exams/$id/submit', {
      'answers': answers,
    }, 'Failed to submit exam');
  }

  static Future<Map<String, dynamic>> getExamById(String examId) async {
    return _performGet('/api/exams/$examId', 'Failed to get exam details');
  }

  static Future<Map<String, dynamic>> getMarksForExam(String examId) async {
    return _performGet('/api/marks/exam/$examId', 'Failed to get marks');
  }

  static Future<Map<String, dynamic>> bulkUploadMarks(Map<String, dynamic> payload) async {
    return _performPost('/api/marks/bulk', payload, 'Failed to save marks');
  }

  static Future<Map<String, dynamic>> uploadMarks(Map<String, dynamic> payload) async {
    return _performPost('/api/marks/bulk', payload, 'Failed to upload marks');
  }

  static Future<Map<String, dynamic>> freezeExamClass(String examId, String classId, bool isFrozen) async {
    return _performPost('/api/exams/$examId/freeze', {'classId': classId, 'isFrozen': isFrozen}, 'Failed to freeze exam');
  }

  static Future<Map<String, dynamic>> clearMarks(String examId, String classId, String subject) async {
    return _performDelete('/api/marks/exam/$examId?classId=$classId&subject=$subject', 'Failed to clear marks');
  }

  static Future<Map<String, dynamic>> sendMarksSMS(String examId, String classId, Map<String, dynamic> payload) async {
    return _performPost('/api/exams/$examId/classes/$classId/send-sms', payload, 'Failed to send SMS');
  }

  static Future<Map<String, dynamic>> getPendingBalances({String? classId, String? search}) async {
    String url = '/api/fees/pending-balances?limit=1000';
    if (classId != null && classId != 'ALL') url += '&classId=$classId';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    return _performGet(url, 'Failed to fetch pending balances');
  }

  static Future<Map<String, dynamic>> applyFeeDiscount({
    required String studentId,
    required String feeStructureId,
    required double discountAmount,
    required String remarks,
  }) async {
    return _performPost('/api/fees/discount', {
      'studentId': studentId,
      'feeStructureId': feeStructureId,
      'discountAmount': discountAmount,
      'remarks': remarks,
    }, 'Failed to apply discount');
  }

  static Future<Map<String, dynamic>> updateFeePayment(String paymentId, Map<String, dynamic> payload) async {
    return _performPut('/api/fees/payments/$paymentId', payload, 'Failed to update payment');
  }

  static Future<Map<String, dynamic>> deleteFeePayment(String paymentId) async {
    return _performDelete('/api/fees/payments/$paymentId', 'Failed to delete payment');
  }

  static Future<Map<String, dynamic>> recordPayments(Map<String, dynamic> payload) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/fees/payments'),
        headers: _getHeaders(token: token),
        body: jsonEncode(payload),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? 'Failed request') : 'Failed request'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getExamResults(String examId, {String classId = '', bool includePhoto = false}) async {
    String url = '/api/exams/$examId/results';
    List<String> params = [];
    if (classId.isNotEmpty) {
      params.add('classId=$classId');
    }
    if (includePhoto) {
      params.add('includePhoto=true');
    }
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    return _performGet(url, 'Failed to get exam results');
  }

  static Future<Map<String, dynamic>> getExamStatus() async {
    return _performGet('/api/exams/status/all', 'Failed to get exam status');
  }

  static Future<Map<String, dynamic>> getTeachers({int limit = 500}) async {
    return _performGet('/api/teachers?limit=$limit', 'Failed to get teachers');
  }

  static Future<Map<String, dynamic>> getTeacherById(String id) async {
    return _performGet('/api/teachers/$id', 'Failed to get teacher profile');
  }

  static Future<Map<String, dynamic>> getTeacherClasses(String id) async {
    return _performGet('/api/teachers/$id/assigned-classes', 'Failed to get assigned classes');
  }

  static Future<Map<String, dynamic>> createTeacher(Map<String, dynamic> data) async {
    return _performPost('/api/teachers', data, 'Failed to create teacher');
  }

  static Future<Map<String, dynamic>> updateTeacher(String id, Map<String, dynamic> data) async {
    return _performPut('/api/teachers/$id', data, 'Failed to update teacher');
  }

  static Future<Map<String, dynamic>> getAttendanceByClass(String classId, String date) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.get(
        Uri.parse('$baseUrl/api/attendance/class?classId=$classId&date=$date'),
        headers: _getHeaders(token: token),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to get student list'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitBulkAttendance(
      String classId, String date, List<Map<String, dynamic>> records) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/bulk'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'classId': classId,
          'date': date,
          'records': records,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Attendance marked successfully'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to mark attendance'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> markBulkAttendance(Map<String, dynamic> payload) async {
    return _performPost('/api/attendance/bulk', payload, 'Failed to mark attendance');
  }

  static Future<Map<String, dynamic>> submitHomework(
      String classId, String subjectId, String title, String description, String dueDate) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/homework'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'classId': classId,
          'subjectId': subjectId,
          'title': title,
          'description': description,
          'dueDate': dueDate,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Homework posted successfully'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to post homework'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateHomework(String id, Map<String, dynamic> payload) async {
    return _performPut('/api/homework/$id', payload, 'Failed to update homework');
  }

  static Future<Map<String, dynamic>> deleteHomework(String id) async {
    return _performDelete('/api/homework/$id', 'Failed to delete homework');
  }

  static Future<Map<String, dynamic>> submitBulkMarks(List<Map<String, dynamic>> marks) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/marks/bulk'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'marks': marks,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Marks saved successfully'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to save marks'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getClassStudents(String classId) async {
    return _performGet('/api/classes/$classId/students', 'Failed request');
  }

  static Future<Map<String, dynamic>> getEvents() async {
    return _performGet('/api/events', 'Failed request');
  }



  static Future<Map<String, dynamic>> getMyLeaves() async {
    return _performGet('/api/leave/my', 'Failed request');
  }

  static Future<Map<String, dynamic>> applyLeave({
    String? userId,
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/leave'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          if (userId != null) 'userId': userId,
          'type': type,
          'startDate': startDate,
          'endDate': endDate,
          'reason': reason,
        }),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': decoded is Map ? (decoded['message'] ?? 'Success') : 'Success'};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? 'Failed request') : 'Failed request'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllLeaves({String? status}) async {
    final qs = status != null && status != 'ALL' ? '?status=$status' : '';
    return _performGet('/api/leave$qs', 'Failed request');
  }

  static Future<Map<String, dynamic>> updateLeaveStatus(String id, String status, {String? rejectionReason}) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.put(
        Uri.parse('$baseUrl/api/leave/$id/status'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'status': status,
          if (rejectionReason != null) 'rejectionReason': rejectionReason,
        }),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': decoded is Map ? (decoded['message'] ?? 'Success') : 'Success'};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? 'Failed request') : 'Failed request'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getGatePasses({String? status}) async {
    final qs = status != null ? '?status=$status' : '';
    return _performGet('/api/gate-pass$qs', 'Failed to get gate passes');
  }

  static Future<Map<String, dynamic>> updateGatePass(String id, Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.patch(
        Uri.parse('$baseUrl/api/gate-pass/$id'),
        headers: _getHeaders(token: token),
        body: jsonEncode(data),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded is Map ? (decoded['message'] ?? 'Success') : 'Success'};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? 'Failed request') : 'Failed request'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteGatePass(String id) async {
    return _performDelete('/api/gate-pass/$id', 'Failed to delete gate pass');
  }

  static Future<Map<String, dynamic>> applyGatePass({
    String? studentId,
    String? staffId,
    required String reason,
    required String destination,
    required String outTime,
    String? expectedReturnTime,
    bool? isReturnable,
    String? requestType,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/gate-pass'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          if (studentId != null) 'studentId': studentId,
          if (staffId != null) 'staffId': staffId,
          'reason': reason,
          'destination': destination,
          'exitTime': outTime,
          if (expectedReturnTime != null) 'returnTime': expectedReturnTime,
          if (isReturnable != null) 'isReturnable': isReturnable,
          if (requestType != null) 'requestType': requestType,
        }),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': decoded is Map ? (decoded['message'] ?? 'Success') : 'Success'};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? 'Failed request') : 'Failed request'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSalary() async {
    return _performGet('/api/salary', 'Failed to get salary details');
  }

  static Future<Map<String, dynamic>> getSlipTests() async {
    return _performGet('/api/slipTests', 'Failed to get slip tests');
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    return _performGet('/api/notifications', 'Failed to get notifications');
  }

  static Future<Map<String, dynamic>> markNotificationsRead() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/read-all'),
        headers: _getHeaders(token: token),
      );

      return {'success': response.statusCode == 200 || response.statusCode == 201};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getChatConversations() async {
    return _performGet('/api/messages/conversations', 'Failed to get conversations');
  }

  static Future<Map<String, dynamic>> getConversation(String userId) async {
    return _performGet('/api/messages/$userId', 'Failed to get messages');
  }

  static Future<Map<String, dynamic>> sendMessage(String receiverId, String content) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/messages'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'receiverId': receiverId,
          'content': content,
        }),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? 'Failed request') : 'Failed request'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadImage(String filePath) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/uploads/image'));
      request.headers.addAll(_getHeaders(token: token));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'url': decoded['url']};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? 'Upload failed') : 'Upload failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _performGet(String endpoint, String errorMsg) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      try {
        final response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(token: token),
        );

        final dynamic decoded = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cache_$endpoint', response.body);
          
          return {'success': true, 'data': decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded};
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          await logout();
          return {'success': false, 'message': 'Session expired. Please login again.'};
        }
        return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? errorMsg) : errorMsg};
      } catch (e) {
        final prefs = await SharedPreferences.getInstance();
        final cachedStr = prefs.getString('cache_$endpoint');
        
        if (cachedStr != null) {
          final dynamic decoded = jsonDecode(cachedStr);
          if (decoded is Map || decoded is List) {
             final data = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
             return {'success': true, 'data': data, 'isCached': true};
          }
        }
        return {'success': false, 'message': 'Network error and no offline data. Please check your connection.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _performPost(String endpoint, Map<String, dynamic> payload, String errorMsg) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token: token),
        body: jsonEncode(payload),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded};
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
        return {'success': false, 'message': 'Session expired. Please login again.'};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? errorMsg) : errorMsg};
    } catch (e) {
      await OfflineSyncService.enqueueRequest(method: 'POST', endpoint: endpoint, body: payload);
      return {'success': true, 'isOfflineQueued': true, 'message': 'Network error. Request saved offline and will sync later.', 'data': {}};
    }
  }
  static Future<Map<String, dynamic>> _performPut(String endpoint, Map<String, dynamic> payload, String errorMsg) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token: token),
        body: jsonEncode(payload),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded};
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
        return {'success': false, 'message': 'Session expired. Please login again.'};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? errorMsg) : errorMsg};
    } catch (e) {
      await OfflineSyncService.enqueueRequest(method: 'PUT', endpoint: endpoint, body: payload);
      return {'success': true, 'isOfflineQueued': true, 'message': 'Network error. Request saved offline and will sync later.', 'data': {}};
    }
  }

  static Future<Map<String, dynamic>> _performDelete(String endpoint, String errorMsg) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token: token),
      );

      final dynamic decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'data': decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded};
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
        return {'success': false, 'message': 'Session expired. Please login again.'};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? errorMsg) : errorMsg};
    } catch (e) {
      await OfflineSyncService.enqueueRequest(method: 'DELETE', endpoint: endpoint);
      return {'success': true, 'isOfflineQueued': true, 'message': 'Network error. Request saved offline and will sync later.', 'data': {}};
    }
  }

  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    return _performGet('/api/dashboard/admin', 'Failed to get admin statistics');
  }

  static Future<Map<String, dynamic>> getAccountantDashboardStats() async {
    return _performGet('/api/dashboard/accountant', 'Failed to get accountant statistics');
  }

  static Future<Map<String, dynamic>> getQuestionPapers() async {
    return _performGet('/api/question-papers', 'Failed to get question papers');
  }

  static Future<Map<String, dynamic>> createQuestionPaper(Map<String, dynamic> data) async {
    return _performPost('/api/question-papers', data, 'Failed to create question paper');
  }

  static Future<Map<String, dynamic>> getQuestionPaperDashboardStats() async {
    return _performGet('/api/question-papers/dashboard-stats', 'Failed to get question paper statistics');
  }

  static Future<Map<String, dynamic>> approveQuestionPaper(String id) async {
    return _performPut('/api/question-papers/$id/approve', {}, 'Failed to approve question paper');
  }

  static Future<Map<String, dynamic>> rejectQuestionPaper(String id) async {
    return _performPut('/api/question-papers/$id/reject', {}, 'Failed to reject question paper');
  }

  static Future<Map<String, dynamic>> publishQuestionPaper(String id) async {
    return _performPut('/api/question-papers/$id/publish', {}, 'Failed to publish question paper');
  }

  static Future<Map<String, dynamic>> deleteQuestionPaper(String id) async {
    return _performDelete('/api/question-papers/$id', 'Failed to delete question paper');
  }

  static Future<Map<String, dynamic>> updateAnswerKey(String id, String answerKey, String answerKeyUrl) async {
    return _performPut('/api/question-papers/$id/answer-key', {
      'answerKey': answerKey,
      'answerKeyUrl': answerKeyUrl,
    }, 'Failed to update answer key');
  }

  static Future<Map<String, dynamic>> getGeneratedPapers() async {
    return _performGet('/api/generatedPapers', 'Failed to get generated papers');
  }

  static Future<Map<String, dynamic>> getAnswerKeys() async {
    return _performGet('/api/answerKeys', 'Failed to get answer keys');
  }

  static Future<Map<String, dynamic>> getOfficeTools() async {
    return {'success': true, 'data': []};
  }

  static Future<Map<String, dynamic>> getReports() async {
    return {'success': true, 'data': []};
  }

  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/change-password'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': decoded is Map ? (decoded['message'] ?? 'Password changed successfully') : 'Success'};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? 'Failed to change password') : 'Failed request'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAttendanceStats() async {
    return _performGet('/api/dashboard/teacher', 'Failed to get teacher dashboard stats');
  }

  static Future<Map<String, dynamic>> getFeeStructures() async {
    return _performGet('/api/fees/structures', 'Failed to get fee structures');
  }

  static Future<Map<String, dynamic>> getFeePayments() async {
    return _performGet('/api/fees/payments?limit=10000', 'Failed to get fee payments');
  }

  static Future<Map<String, dynamic>> getFeeGroups() async {
    return _performGet('/api/fees/groups', 'Failed to get fee groups');
  }

  static Future<Map<String, dynamic>> getFeeHeads() async {
    return _performGet('/api/fees/heads', 'Failed to get fee heads');
  }

  static Future<Map<String, dynamic>> approvePayment(String paymentId) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.put(
        Uri.parse('$baseUrl/api/fees/payments/$paymentId'),
        headers: _getHeaders(token: token),
        body: jsonEncode({'status': 'PAID'}),
      );

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': decoded is Map ? (decoded['message'] ?? 'Success') : 'Success'};
      }
      return {'success': false, 'message': decoded is Map ? (decoded['message'] ?? 'Failed request') : 'Failed request'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }


  static Future<Map<String, dynamic>> getDailyAttendanceSummary(String date) async {
    return _performGet('/api/attendance/daily-summary?date=$date', 'Failed to load daily report');
  }

  static Future<Map<String, dynamic>> getAttendanceDashboardStats() async {
    return _performGet('/api/attendance/dashboard-stats', 'Failed to load dashboard stats');
  }

  static Future<Map<String, dynamic>> getStudentDashboardStats() async {
    return _performGet('/api/dashboard/student', 'Failed to get student stats');
  }

  // ── Fee Settings (Groups / Heads / Concessions) ──────────────────────────

  static Future<Map<String, dynamic>> getFeeConcessions() async =>
      _performGet('/api/fees/concessions', 'Failed to load fee concessions');

  static Future<Map<String, dynamic>> createFeeGroup(Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.post(Uri.parse('$baseUrl/api/fees/groups'), headers: _getHeaders(token: token), body: jsonEncode(body));
      final data = jsonDecode(res.body);
      return res.statusCode == 200 || res.statusCode == 201
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> createFeeHead(Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.post(Uri.parse('$baseUrl/api/fees/heads'), headers: _getHeaders(token: token), body: jsonEncode(body));
      final data = jsonDecode(res.body);
      return res.statusCode == 200 || res.statusCode == 201
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> createFeeConcession(Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.post(Uri.parse('$baseUrl/api/fees/concessions'), headers: _getHeaders(token: token), body: jsonEncode(body));
      final data = jsonDecode(res.body);
      return res.statusCode == 200 || res.statusCode == 201
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> deleteItem(String path) async {
    try {
      final token = await getToken();
      final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _getHeaders(token: token));
      return res.statusCode == 200 || res.statusCode == 204
          ? {'success': true}
          : {'success': false, 'message': 'Failed to delete'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> getAllStudents() async =>
      _performGet('/api/students?limit=5000', 'Failed to load students');

  // ── Salary / HR ────────────────────────────────────────────────────────────



  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson == null) return null;
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>> getSalaries({required int year, int? month}) async {
    final q = month != null ? 'year=$year&month=$month' : 'year=$year';
    return _performGet('/api/salary?$q', 'Failed to load salaries');
  }

  static Future<Map<String, dynamic>> createSalary(Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/api/salary'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      return res.statusCode == 200 || res.statusCode == 201
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> updateSalary(String id, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.put(
        Uri.parse('$baseUrl/api/salary/$id'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      return res.statusCode == 200
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> markSalaryPaid(String id) async {
    try {
      final token = await getToken();
      final res = await http.patch(
        Uri.parse('$baseUrl/api/salary/$id/mark-paid'),
        headers: _getHeaders(token: token),
      );
      return res.statusCode == 200
          ? {'success': true}
          : {'success': false, 'message': 'Failed to mark paid'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> deleteSalary(String id) async {
    try {
      final token = await getToken();
      final res = await http.delete(
        Uri.parse('$baseUrl/api/salary/$id'),
        headers: _getHeaders(token: token),
      );
      return res.statusCode == 200
          ? {'success': true}
          : {'success': false, 'message': 'Failed to delete'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  // ── Settings & Admin ────────────────────────────────────────────────────────
  
  static Future<Map<String, dynamic>> getSettings() async {
    return _performGet('/api/settings', 'Failed to load system settings');
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.put(
        Uri.parse('$baseUrl/api/settings'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      return res.statusCode == 200
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 10, String? search, String? role}) async {
    String q = 'page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) q += '&search=$search';
    if (role != null && role.isNotEmpty) q += '&role=$role';
    return _performGet('/api/users?$q', 'Failed to load users');
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      return res.statusCode == 200 || res.statusCode == 201
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.put(
        Uri.parse('$baseUrl/api/users/$id'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      return res.statusCode == 200
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  // ── Question Bank / Generated Papers ────────────────────────────────────────


  static Future<Map<String, dynamic>> getGeneratedPaperById(String id) async {
    return _performGet('/api/generated-papers/$id', 'Failed to load paper details');
  }

  static Future<Map<String, dynamic>> saveGeneratedPaper(Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/api/generated-papers'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      return res.statusCode == 200 || res.statusCode == 201
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> updateGeneratedPaper(String id, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.put(
        Uri.parse('$baseUrl/api/generated-papers/$id'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      return res.statusCode == 200
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>> deleteGeneratedPaper(String id) async {
    return deleteItem('/api/generated-papers/$id');
  }

  static Future<Map<String, dynamic>> generateQuestionsFromAI(Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/api/questions/import-ai'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      return res.statusCode == 200 || res.statusCode == 201
          ? {'success': true, 'data': data}
          : {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  // ==========================================
  // MESSAGING ENDPOINTS
  // ==========================================
  static Future<Map<String, dynamic>> getConversations() async {
    return _performGet('/api/messages/conversations', 'Failed to fetch conversations');
  }



  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('user');
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  // ==========================================
  // GATE PASS STATS ENDPOINT
  // ==========================================
  static Future<Map<String, dynamic>> getGatePassStats() async {
    return _performGet('/api/gate-pass/stats', 'Failed to fetch gate pass stats');
  }

  // ==========================================
  // TRANSPORT ENDPOINTS
  // ==========================================
  static Future<Map<String, dynamic>> getTransportDashboard() async {
    return _performGet('/api/transport/dashboard', 'Failed to fetch transport stats');
  }
  
  static Future<Map<String, dynamic>> getTransportRoutes() async {
    return _performGet('/api/transport/routes', 'Failed to fetch transport routes');
  }
  
  static Future<Map<String, dynamic>> getTransportVehicles() async {
    return _performGet('/api/transport/vehicles', 'Failed to fetch transport vehicles');
  }
  
  static Future<Map<String, dynamic>> getTransportStudents() async {
    return _performGet('/api/transport/students', 'Failed to fetch transport students');
  }
  
  static Future<Map<String, dynamic>> getFuelLogs() async {
    return _performGet('/api/transport/fuel-logs', 'Failed to fetch fuel logs');
  }
  
  static Future<Map<String, dynamic>> getMaintenanceLogs() async {
    return _performGet('/api/transport/maintenance-logs', 'Failed to fetch maintenance logs');
  }

  // ==========================================
  // PUBLIC GENERIC METHODS (For newer screens)
  // ==========================================
  static Future<Map<String, dynamic>> performGet(String url, String errorMessage) async {
    return _performGet(url, errorMessage);
  }

  static Future<Map<String, dynamic>> performPost(String url, Map<String, dynamic> body, String errorMessage) async {
    return _performPost(url, body, errorMessage);
  }

  static Future<Map<String, dynamic>> performPut(String url, Map<String, dynamic> body, String errorMessage) async {
    return _performPut(url, body, errorMessage);
  }

  static Future<Map<String, dynamic>> deleteLeave(String id) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No session token'};

      final response = await http.delete(
        Uri.parse('$baseUrl/api/leave/$id'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to delete'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> uploadDocument(List<int> bytes, String filename) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/uploads/document'));
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['ngrok-skip-browser-warning'] = '69420';
      
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'url': data['url'] ?? data['data']?['url']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to upload document'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── Phase 3 Fee Payment Methods ──────────────────────────────────────────

  static Future<Map<String, dynamic>> getStudentPayments() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token'};

      final res = await http.get(
        Uri.parse('$baseUrl/api/fees/payments?limit=50'),
        headers: _getHeaders(token: token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data['data'] ?? []};
      }
      return {'success': false, 'message': 'Failed to load payments'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> studentPayFeeWithScreenshot({
    required double amount,
    required String paymentMethod,
    required String referenceNumber,
    String? notes,
    String? feeStructureId,
    required List<int> imageBytes,
    required String imageFilename,
  }) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/fees/student/pay'));
      request.headers.addAll(_getHeaders(token: token, isMultipart: true));

      request.fields['amount'] = amount.toString();
      request.fields['amountPaid'] = amount.toString();
      request.fields['paymentMethod'] = paymentMethod;
      request.fields['method'] = paymentMethod;
      request.fields['referenceNumber'] = referenceNumber;
      request.fields['utrNumber'] = referenceNumber;
      if (notes != null) request.fields['notes'] = notes;
      if (feeStructureId != null && feeStructureId.isNotEmpty) request.fields['feeStructureId'] = feeStructureId;

      final multipartFile = http.MultipartFile.fromBytes(
        'screenshot',
        imageBytes,
        filename: imageFilename,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false, 'message': data['message'] ?? 'Payment submission failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateSettingsWithFile({
    required Map<String, String> fields,
    List<int>? fileBytes,
    String? filename,
  }) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/api/settings'));
      request.headers.addAll(_getHeaders(token: token, isMultipart: true));

      request.fields.addAll(fields);

      if (fileBytes != null && filename != null) {
        final multipartFile = http.MultipartFile.fromBytes(
          'qrCode',
          fileBytes,
          filename: filename,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to update settings'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPendingFeeApprovals() async {
    return _performGet('/api/fees/admin/pending', 'Failed to load pending fee approvals');
  }

  static Future<Map<String, dynamic>> approveFeePayment(String paymentId, {required bool approve}) async {
    return _performPost('/api/fees/admin/approve', {'paymentId': paymentId, 'approve': approve}, 'Failed to process fee approval');
  }

}
