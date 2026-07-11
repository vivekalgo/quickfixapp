import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ErrorHandler {
  static ApiException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException('Connection timed out. The server could not be reached.\n\nTip: If you are using mobile data (Jio/Airtel), our server may be blocked by your operator. Try switching to Wi-Fi, using a VPN, or changing your phone\'s Private DNS to "dns.google" or "1.1.1.1".');
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;
          String errorMessage = 'Something went wrong. Please try again.';

          if (responseData != null && responseData is Map) {
            errorMessage = responseData['message']?.toString() ?? errorMessage;
          }

          switch (statusCode) {
            case 400:
              return ApiException(errorMessage, statusCode);
            case 401:
              return ApiException('Session expired. Please log in again.', statusCode);
            case 403:
              return ApiException('You do not have permission to access this resource.', statusCode);
            case 404:
              return ApiException(errorMessage, statusCode);
            case 500:
              return ApiException('Internal Server Error. Please try again later.', statusCode);
            default:
              return ApiException(errorMessage, statusCode);
          }
          
        case DioExceptionType.cancel:
          return ApiException('Request was cancelled.');
          
        case DioExceptionType.connectionError:
          return ApiException('Connection error. The server could not be reached.\n\nTip: If you are using mobile data (Jio/Airtel), our server may be blocked by your operator. Try switching to Wi-Fi, using a VPN, or changing your phone\'s Private DNS to "dns.google" or "1.1.1.1".');
          
        default:
          return ApiException('Failed to connect to QuickFix servers.');
      }
    }
    return ApiException(error?.toString() ?? 'An unexpected error occurred.');
  }
}
