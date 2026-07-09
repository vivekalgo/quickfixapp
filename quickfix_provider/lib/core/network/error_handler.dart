import 'package:dio/dio.dart';

class ErrorHandler {
  static String handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.sendTimeout:
          return 'Request send timeout. Please try again.';
        case DioExceptionType.receiveTimeout:
          return 'Response receive timeout. Please try again.';
        case DioExceptionType.badResponse:
          final response = error.response;
          if (response != null) {
            final data = response.data;
            if (data is Map && data.containsKey('error')) {
              return data['error'].toString();
            }
            if (data is Map && data.containsKey('message')) {
              return data['message'].toString();
            }
            switch (response.statusCode) {
              case 400:
                return 'Bad request. Please verify your input.';
              case 401:
                return 'Session expired. Please log in again.';
              case 403:
                return 'Access forbidden. Please contact admin support.';
              case 404:
                return 'Requested resource not found.';
              case 500:
                return 'Internal Server Error. Please try again later.';
              default:
                return 'Error occurred with status code: ${response.statusCode}';
            }
          }
          return 'Unexpected response error occurred.';
        case DioExceptionType.cancel:
          return 'Request cancelled.';
        case DioExceptionType.connectionError:
          return 'Connection error. The server could not be reached.';
        case DioExceptionType.unknown:
          return 'An unexpected error occurred. Please check your internet.';
        default:
          return 'An unexpected network error occurred.';
      }
    }
    return error?.toString() ?? 'An unknown error occurred.';
  }
}
