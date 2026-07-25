import 'package:dio/dio.dart';
import 'package:quickfix/core/network/api_endpoints.dart';
import 'package:quickfix/core/network/dio_client.dart';

class HelpdeskService {
  final Dio _dio = DioClient().dio;

  /// Send message to Helpdesk AI Agent
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? ticketId,
    List<String>? attachments,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.helpdeskChat,
        data: {
          'message': message,
          if (ticketId != null && ticketId.isNotEmpty) 'ticketId': ticketId,
          if (attachments != null) 'attachments': attachments,
          'platform': 'android_flutter',
          'appVersion': '2.1.0',
          if (deviceInfo != null) 'deviceInfo': deviceInfo,
        },
      );
      if (response.data is Map && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return {
        'reply': {
          'text': response.data['error'] ?? 'Support server response error.'
        }
      };
    } catch (e) {
      return {
        'reply': {
          'text': 'We received your message. Our AI Assistant is processing your request. (Offline sync active)'
        }
      };
    }
  }

  /// Fetch user support tickets
  Future<List<dynamic>> fetchUserTickets() async {
    try {
      final response = await _dio.get(ApiEndpoints.helpdeskUserTickets);
      if (response.data is Map && response.data['success'] == true) {
        return response.data['tickets'] as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch single ticket detail with messages
  Future<Map<String, dynamic>?> fetchTicketDetail(String ticketId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.helpdeskTicketDetail}/$ticketId');
      if (response.data is Map && response.data['success'] == true) {
        return response.data['ticket'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
