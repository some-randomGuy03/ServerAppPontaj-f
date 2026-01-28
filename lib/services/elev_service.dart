import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/elev.dart';
import 'auth_service.dart';
import 'error_service.dart';

class ElevService {
  Future<ElevListResponse> getElevi(String token) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/elevi');

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
          'GET /admin/elevi - Success',
          input: 'GET /admin/elevi',
          output: 'Status: ${response.statusCode}, Count: ${data['count']}',
        );
        return ElevListResponse.fromJson(data);
      } else {
        ErrorService().showError(
          'GET /admin/elevi - Failed',
          input: 'GET /admin/elevi',
          output: 'Status: ${response.statusCode}, Body: ${response.body}',
          notificationMessage: 'Server Error',
        );
        throw Exception(
          'Failed to load elevi: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('401')) {
        ErrorService().showError(
          'Error fetching elevi: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('Error fetching elevi: $e');
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
          'Failed to load enrolled elevi: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('401')) {
        ErrorService().showError(
          'Error fetching enrolled elevi: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('Error fetching enrolled elevi: $e');
    }
  }

  Future<Elev> addElev(
    String token,
    String nume,
    String email,
    String codMatricol,
    int activ,
  ) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/elevi');
    try {
      final response = await http.post(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nume': nume,
          'email': email,
          'codmatricol': codMatricol,
          'activ': activ,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        ErrorService().logInfo(
          'POST /admin/elevi - Success',
          input: 'POST /admin/elevi',
          output: 'Status: ${response.statusCode}, ID: ${data['ID']}',
        );
        return Elev.fromJson(data);
      } else {
        ErrorService().showError(
          'POST /admin/elevi - Failed',
          input: jsonEncode({
            'nume': nume,
            'email': email,
            'codmatricol': codMatricol,
            'activ': activ,
          }),
          output: 'Status: ${response.statusCode}, Body: ${response.body}',
          notificationMessage: 'Server Error',
        );
        throw Exception(
          'Failed to add elev: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('Server Error')) {
        ErrorService().showError(
          'Error adding elev: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('Error adding elev: $e');
    }
  }

  Future<void> updateElev(
    String token,
    int id,
    String nume,
    String email,
    String codMatricol,
    int activ,
  ) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/elevi/$id');
    try {
      final response = await http.put(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nume': nume,
          'email': email,
          'codmatricol': codMatricol,
          'activ': activ,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ErrorService().logInfo(
          'PUT /admin/elevi/$id - Success',
          input: 'PUT /admin/elevi/$id',
          output: 'Status: ${response.statusCode}',
        );
        return;
      } else {
        ErrorService().showError(
          'PUT /admin/elevi/$id - Failed',
          input: jsonEncode({
            'nume': nume,
            'email': email,
            'codmatricol': codMatricol,
            'activ': activ,
          }),
          output: 'Status: ${response.statusCode}, Body: ${response.body}',
          notificationMessage: 'Server Error',
        );
        throw Exception(
          'Failed to update elev: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('Server Error')) {
        ErrorService().showError(
          'Error updating elev: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('Error updating elev: $e');
    }
  }

  Future<void> deleteElev(String token, int id) async {
    final uri = Uri.parse('${AuthService.baseUrl}/admin/elevi/$id');
    try {
      final response = await http.delete(
        uri,
        headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ErrorService().logInfo(
          'DELETE /admin/elevi/$id - Success',
          input: 'DELETE /admin/elevi/$id',
          output: 'Status: ${response.statusCode}',
        );
        return;
      } else {
        ErrorService().showError(
          'DELETE /admin/elevi/$id - Failed',
          input: 'DELETE /admin/elevi/$id',
          output: 'Status: ${response.statusCode}, Body: ${response.body}',
          notificationMessage: 'Server Error',
        );
        throw Exception(
          'Failed to delete elev: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!e.toString().contains('Server Error')) {
        ErrorService().showError(
          'Error deleting elev: $e',
          notificationMessage: 'Server Error',
        );
      }
      throw Exception('Error deleting elev: $e');
    }
  }
}
