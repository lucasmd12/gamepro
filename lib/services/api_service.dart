import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucasbeatsfederacao/utils/constants.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ApiService {
  final String _baseUrl = backendBaseUrl;
  String get baseUrl => _baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Timeout aumentado para lidar com cold start do Render.com
  static const Duration _defaultTimeout = Duration(seconds: 90);
  static const Duration _shortTimeout = Duration(seconds: 30);

  Future<String?> getToken() async { // Alterado para público
    return await _secureStorage.read(key: 'jwt_token');
  }

  Future<void> setAuthToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (includeAuth) {
      final token = await getToken(); // Usando o método público
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    Logger.info('API Response Status: $statusCode, Body: ${response.body}');

    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        data: {
          'url': response.request?.url.toString(),
          'method': response.request?.method,
          'status_code': statusCode,
          'response_body_length': response.body.length,
        },
        level: statusCode >= 200 && statusCode < 300 ? SentryLevel.info : SentryLevel.error,
      ),
    );

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          Logger.error('Error decoding JSON response: ${e.toString()}');
          throw Exception('Failed to decode JSON response');
        }
      } else {
        return null;
      }
    } else {
      String errorMessage = 'API Error ($statusCode)';
      try {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('msg')) {
          errorMessage = decodedBody['msg'] + ' (Code: $statusCode)';
        } else if (decodedBody is Map && decodedBody.containsKey('errors')) {
          final errors = decodedBody['errors'] as List;
          errorMessage = "${errors.map((e) => e['msg']).join(', ')} (Code: $statusCode)";
        } else if (response.body.isNotEmpty) {
           errorMessage = "${response.body} (Code: $statusCode)";
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? "${response.body} (Code: $statusCode)" : errorMessage;
      }
      Logger.error('API Error: $statusCode - $errorMessage');
      throw Exception(errorMessage);
    }
  }

  Future<http.Response> _makeRequestWithRetry(Future<http.Response> Function() requestFunction, {int maxRetries = 2}) async {
    int attempts = 0;
    while (attempts <= maxRetries) {
      try {
        final response = await requestFunction();
        return response;
      } catch (e) {
        attempts++;
        if (e.toString().contains('TimeoutException') && attempts <= maxRetries) {
          Logger.warning('Request timeout, retrying... (attempt $attempts/$maxRetries)');
          await Future.delayed(Duration(seconds: 2 * attempts)); // Backoff progressivo
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Max retries reached');
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = true, Duration? timeout, Map<String, dynamic>? queryParams}) async {
    Uri url;
    if (queryParams != null && queryParams.isNotEmpty) {
      url = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
    } else {
      url = Uri.parse('$_baseUrl$endpoint');
    }

    Logger.info('API GET Request: $url');

    final transaction = Sentry.startTransaction(
      'GET $endpoint',
      'http.client',
      description: 'HTTP GET request to $endpoint',
    );
    final span = transaction.startChild(
      'http.client',
      description: 'GET $url',
    );

    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        data: {
          'url': url.toString(),
          'method': 'GET',
        },
        level: SentryLevel.info,
      ),
    );

    try {
      final httpResponse = await _makeRequestWithRetry(() async {
        return await http.get(
          url,
          headers: await _getHeaders(includeAuth: requireAuth),
        ).timeout(timeout ?? _defaultTimeout);
      });
      
      span.setTag('http.status_code', httpResponse.statusCode.toString());
      span.finish(status: SpanStatus.ok());
      transaction.finish(status: SpanStatus.ok());
      
      return _handleResponse(httpResponse);
    } catch (e, stackTrace) {
      span.finish(status: SpanStatus.internalError());
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool requireAuth = true, Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API POST Request: $url, Data: ${jsonEncode(data)}');

    final transaction = Sentry.startTransaction(
      'POST $endpoint',
      'http.client',
      description: 'HTTP POST request to $endpoint',
    );
    final span = transaction.startChild(
      'http.client',
      description: 'POST $url',
    );

    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        data: {
          'url': url.toString(),
          'method': 'POST',
          'request_body': jsonEncode(data),
        },
        level: SentryLevel.info,
      ),
    );
    
    try {
      final httpResponse = await _makeRequestWithRetry(() async {
        return await http.post(
          url,
          headers: await _getHeaders(includeAuth: requireAuth),
          body: jsonEncode(data),
        ).timeout(timeout ?? _defaultTimeout);
      });
      
      span.setTag('http.status_code', httpResponse.statusCode.toString());
      span.finish(status: SpanStatus.ok());
      transaction.finish(status: SpanStatus.ok());
      
      return _handleResponse(httpResponse);
    } catch (e, stackTrace) {
      span.finish(status: SpanStatus.internalError());
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data, {bool requireAuth = true, Duration? timeout}) async {
 print('DEBUG: Entering ApiService.put for endpoint: $endpoint'); // Linha adicionada
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API PUT Request: $url, Data: ${jsonEncode(data)}');

    final transaction = Sentry.startTransaction(
      'PUT $endpoint',
      'http.client',
      description: 'HTTP PUT request to $endpoint',
    );
    final span = transaction.startChild(
      'http.client',
      description: 'PUT $url',
    );

    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        data: {
          'url': url.toString(),
          'method': 'PUT',
          'request_body': jsonEncode(data),
        },
        level: SentryLevel.info,
      ),
    );
    
    try {
      final httpResponse = await _makeRequestWithRetry(() async {
        return await http.put(
          url,
          headers: await _getHeaders(includeAuth: requireAuth),
          body: jsonEncode(data as Object?),
        ).timeout(timeout ?? _defaultTimeout);
      });
      
      span.setTag('http.status_code', httpResponse.statusCode.toString());
      span.finish(status: SpanStatus.ok());
      transaction.finish(status: SpanStatus.ok());
      
      return _handleResponse(httpResponse);
    } catch (e, stackTrace) {
      span.finish(status: SpanStatus.internalError());
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data, {bool requireAuth = true, Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API PATCH Request: $url, Data: ${jsonEncode(data)}');

    final transaction = Sentry.startTransaction(
      'PATCH $endpoint',
      'http.client',
      description: 'HTTP PATCH request to $endpoint',
    );
    final span = transaction.startChild(
      'http.client',
      description: 'PATCH $url',
    );

    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        data: {
          'url': url.toString(),
          'method': 'PATCH',
          'request_body': jsonEncode(data),
        },
        level: SentryLevel.info,
      ),
    );

    try {
      final httpResponse = await _makeRequestWithRetry(() async {
        return await http.patch(
          url,
          headers: await _getHeaders(includeAuth: requireAuth),
          body: jsonEncode(data),
        ).timeout(timeout ?? _defaultTimeout);
      });

      span.setTag('http.status_code', httpResponse.statusCode.toString());
      span.finish(status: SpanStatus.ok());
      transaction.finish(status: SpanStatus.ok());

      return _handleResponse(httpResponse);
    } catch (e, stackTrace) {
      span.finish(status: SpanStatus.internalError());
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true, Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API DELETE Request: $url');

    final transaction = Sentry.startTransaction(
      'DELETE $endpoint',
      'http.client',
      description: 'HTTP DELETE request to $endpoint',
    );
    final span = transaction.startChild(
      'http.client',
      description: 'DELETE $url',
    );

    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        type: 'http',
        data: {
          'url': url.toString(),
          'method': 'DELETE',
        },
        level: SentryLevel.info,
      ),
    );

    try {
      final httpResponse = await _makeRequestWithRetry(() async {
        return await http.delete(
          url,
          headers: await _getHeaders(includeAuth: requireAuth),
        ).timeout(timeout ?? _defaultTimeout);
      });
      
      span.setTag('http.status_code', httpResponse.statusCode.toString());
      span.finish(status: SpanStatus.ok());
      transaction.finish(status: SpanStatus.ok());
      
      return _handleResponse(httpResponse);
    } catch (e, stackTrace) {
      span.finish(status: SpanStatus.internalError());
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Método para manter o servidor vivo (ping)
  Future<void> keepServerAlive() async {
    final url = Uri.parse('$_baseUrl/api/keep-alive');
    try {
      await http.get(url).timeout(_shortTimeout);
      Logger.info('Server keep-alive ping successful.');
    } catch (e) {
      Logger.warning('Server keep-alive ping failed: ${e.toString()}');
    }
  }
}


