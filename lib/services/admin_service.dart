import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/professor.dart';
import '../models/scan_log.dart';
import '../models/elev.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'error_service.dart';

class AdminService {
  Future<AdminListResponse> getProfessors(String token) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/profesori');

    try {
      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        ErrorService().logInfo(
          'GET /admin/profesori - Success',
          input: 'GET /admin/profesori',
          output: 'Status: ${response.statusCode}, Count: ${data['count']}',
        );
        return AdminListResponse.fromJson(data);
      } else {
        ErrorService().showError(
          'GET /admin/profesori - Failed',
          input: 'GET /admin/profesori',
          output: 'Status: ${response.statusCode}, Body: ${response.body}',
          notificationMessage: 'Server Error',
        );
        throw Exception(
          'Failed to load professors: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('401')) {
        ErrorService().showError(
          'Error fetching professors: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('Error fetching professors: $e');
    }
  }

  Future<Professor> addProfessor(
    String token,
    String name,
    String email,
    String password,
  ) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/profesori');
    try {
      final response = await http.post(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nume': name,
          'email': email,
          'password': password,
          'admin': 0,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Professor.fromJson(data);
      } else {
        throw Exception(
          'Failed to add professor: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      ErrorService().showError(
        'Error adding professor: $e',
        notificationMessage: 'Server Error',
      );
      throw Exception('Error adding professor: $e');
    }
  }

  Future<void> deleteProfessor(String token, int id) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/profesori/$id');
    try {
      final response = await http.delete(
        uri,
        headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception(
          'Failed to delete professor: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      ErrorService().showError(
        'Error deleting professor: $e',
        notificationMessage: 'Server Error',
      );
      throw Exception('Error deleting professor: $e');
    }
  }

  Future<void> updateProfessor(
    String token,
    int id,
    String name,
    String email,
  ) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/profesori/$id');
    try {
      final Map<String, dynamic> body = {'nume': name, 'email': email};

      final response = await http.put(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ErrorService().logInfo(
          'PUT /admin/profesori/$id - Success',
          input: 'PUT /admin/profesori/$id',
          output: 'Status: ${response.statusCode}',
        );
        return;
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData.containsKey('detail')) {
            throw Exception(
              'Validation error: ${jsonEncode(errorData['detail'])}',
            );
          }
        } catch (_) {}
        ErrorService().showError(
          'PUT /admin/profesori/$id - Failed',
          input: jsonEncode(body),
          output: 'Status: ${response.statusCode}, Body: ${response.body}',
          notificationMessage: 'Server Error',
        );
        throw Exception(
          'Failed to update professor: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('Server Error')) {
        ErrorService().showError(
          'Error updating professor: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('$e');
    }
  }

  Future<Professor> changePassword(
    String token,
    int id,
    String password,
  ) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/changepassword/$id');
    try {
      final response = await http.put(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        ErrorService().logInfo(
          'PUT /admin/changepassword/$id - Success',
          input: 'PUT /admin/changepassword/$id',
          output: 'Status: ${response.statusCode}, ID: ${data['ID']}',
        );
        return Professor.fromJson(data);
      } else {
        ErrorService().showError(
          'PUT /admin/changepassword/$id - Failed',
          input: 'Password change request',
          output: 'Status: ${response.statusCode}, Body: ${response.body}',
          notificationMessage: 'Server Error',
        );
        throw Exception(
          'Failed to change password: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('Server Error')) {
        ErrorService().showError(
          'Error changing password: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('Error changing password: $e');
    }
  }

  Future<ScanLogResponse> getScansByDate(
    String token,
    DateTime start,
    DateTime end,
  ) async {
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);
    final uri = Uri.parse(
      '${AuthService.baseUrl}/admin/scans_by_date?start=$startStr&end=$endStr',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        ErrorService().logInfo(
          'GET /admin/scans_by_date - Success',
          input: 'Start: $startStr, End: $endStr',
          output: 'Count: ${data['count']}',
        );
        return ScanLogResponse.fromJson(data);
      } else {
        ErrorService().showError(
          'GET /admin/scans_by_date - Failed',
          input: 'Start: $startStr, End: $endStr',
          output: 'Status: ${response.statusCode}, Body: ${response.body}',
          notificationMessage: 'Server Error',
        );
        throw Exception(
          'Failed to load scans: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('Server Error')) {
        ErrorService().showError(
          'Error fetching scans: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('Error fetching scans: $e');
    }
  }

  Future<ElevListResponse> getEleviEnrolled(String token) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/elevi_enrolled');

    try {
      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        ErrorService().logInfo(
          'GET /admin/elevi_enrolled - Success',
          input: 'GET /admin/elevi_enrolled',
          output: 'Count: ${data['count']}',
        );
        return ElevListResponse.fromJson(data);
      } else {
        ErrorService().showError(
          'GET /admin/elevi_enrolled - Failed',
          input: 'GET /admin/elevi_enrolled',
          output: 'Status: ${response.statusCode}, Body: ${response.body}',
          notificationMessage: 'Server Error',
        );
        throw Exception(
          'Failed to load enrolled students: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('Server Error')) {
        ErrorService().showError(
          'Error fetching enrolled students: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('Error fetching enrolled students: $e');
    }
  }
}
