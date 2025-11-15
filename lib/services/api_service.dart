import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';
import 'auth_service.dart';
import '../constants/app_config.dart';

class ApiService {
  // Use centralized configuration for base URL
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Get headers with authorization
  static Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (AuthService.instance.token != null) {
      headers['Authorization'] = 'Bearer ${AuthService.instance.token}';
    }

    return headers;
  }

  // GET request
  static Future<http.Response> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(url, headers: _getHeaders());
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST request
  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT request
  static Future<http.Response> put(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  static Future<http.Response> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(url, headers: _getHeaders());
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Upload files (multipart request)
  static Future<http.Response> uploadFiles(
    String endpoint,
    List<File> files, {
    Map<String, dynamic>? data,
    String fileFieldName = 'files',
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      var request = http.MultipartRequest('POST', url);

      // Add authorization header
      if (AuthService.instance.token != null) {
        request.headers['Authorization'] =
            'Bearer ${AuthService.instance.token}';
      }
      request.headers['Accept'] = 'application/json';

      // Add additional data fields if provided
      if (data != null) {
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }

      // Add files
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final mimeType =
            lookupMimeType(file.path) ?? 'application/octet-stream';
        final mediaType = MediaType.parse(mimeType);

        request.files.add(await http.MultipartFile.fromPath(
          '$fileFieldName[$i]', // Use array notation for multiple files
          file.path,
          contentType: mediaType,
        ));
      }

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('File upload error: $e');
    }
  }

  // Upload single file
  static Future<http.Response> uploadFile(
    String endpoint,
    File file, {
    Map<String, dynamic>? data,
    String fileFieldName = 'file',
  }) async {
    return uploadFiles(endpoint, [file],
        data: data, fileFieldName: fileFieldName);
  }

  // Upload PlatformFiles (works on both Web and Mobile)
  static Future<http.Response> uploadPlatformFiles(
    String endpoint,
    List<PlatformFile> files, {
    Map<String, dynamic>? data,
    String fileFieldName = 'files',
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      var request = http.MultipartRequest('POST', url);

      // Add authorization header
      if (AuthService.instance.token != null) {
        request.headers['Authorization'] =
            'Bearer ${AuthService.instance.token}';
      }
      request.headers['Accept'] = 'application/json';

      // Add additional data fields if provided
      if (data != null) {
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }

      // Add files
      for (int i = 0; i < files.length; i++) {
        final file = files[i];

        if (kIsWeb && file.bytes != null) {
          // For web, use bytes
          final mimeType =
              lookupMimeType(file.name) ?? 'application/octet-stream';
          final mediaType = MediaType.parse(mimeType);

          request.files.add(http.MultipartFile.fromBytes(
            '$fileFieldName[$i]',
            file.bytes!,
            filename: file.name,
            contentType: mediaType,
          ));
        } else if (file.path != null) {
          // For mobile, use path
          final mimeType =
              lookupMimeType(file.path!) ?? 'application/octet-stream';
          final mediaType = MediaType.parse(mimeType);

          request.files.add(await http.MultipartFile.fromPath(
            '$fileFieldName[$i]',
            file.path!,
            contentType: mediaType,
            filename: file.name,
          ));
        }
      }

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Platform file upload error: $e');
    }
  }

  // Parse response
  static Map<String, dynamic> parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Fetch user orders
  static Future<List<Map<String, dynamic>>> fetchUserOrders({
    int page = 1,
    String? status,
    String? search,
  }) async {
    try {
      String endpoint = '/orders?page=$page';

      if (status != null && status.isNotEmpty) {
        endpoint += '&status=$status';
      }

      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await get(endpoint);
      final data = parseResponse(response);

      if (data['success'] == true) {
        final ordersData = data['data'];
        if (ordersData is Map && ordersData.containsKey('data')) {
          // Paginated response
          return List<Map<String, dynamic>>.from(ordersData['data']);
        } else if (ordersData is List) {
          // Direct array response
          return List<Map<String, dynamic>>.from(ordersData);
        }
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Fetch single order details with delivery proof
  static Future<Map<String, dynamic>> fetchOrderDetails(String orderId) async {
    try {
      final response = await get('/orders/$orderId');
      final data = parseResponse(response);

      if (data['success'] == true) {
        return data['data'];
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }
}
