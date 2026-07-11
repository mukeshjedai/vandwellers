import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/azure_config.dart';
import '../models/campsite.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class VanDwellersApi {
  VanDwellersApi._();
  static final VanDwellersApi instance = VanDwellersApi._();

  String get _base => AzureConfig.apiBaseUrl;

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await AuthService.instance.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<AuthResponse> register({
    required String username,
    required String password,
    String? displayName,
    String? bio,
    String? vanType,
    String? homeBase,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/api/auth/register'),
      headers: await _headers(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'displayName': displayName,
        'bio': bio,
        'vanType': vanType,
        'homeBase': homeBase,
      }),
    );
    return _handleAuth(response);
  }

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/api/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _handleAuth(response);
  }

  Future<UserProfile> getMe() async {
    final response = await http.get(
      Uri.parse('$_base/api/auth/me'),
      headers: await _headers(),
    );
    _ensureOk(response);
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    required String displayName,
    required String bio,
    required String vanType,
    required String homeBase,
  }) async {
    final response = await http.put(
      Uri.parse('$_base/api/profile'),
      headers: await _headers(),
      body: jsonEncode({
        'displayName': displayName,
        'bio': bio,
        'vanType': vanType,
        'homeBase': homeBase,
      }),
    );
    _ensureOk(response);
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserProfile> uploadProfilePhoto(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/profile/photos'),
    );
    final token = await AuthService.instance.getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureOk(response);
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<UserProfile>> discoverUsers() async {
    final response = await http.get(
      Uri.parse('$_base/api/users'),
      headers: await _headers(),
    );
    _ensureOk(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Campsite>> getCampsites() async {
    final response = await http.get(
      Uri.parse('$_base/api/campsites'),
      headers: await _headers(),
    );
    _ensureOk(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Campsite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Campsite> createCampsite({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required bool hasToilet,
    required bool hasTap,
    List<File> photos = const [],
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/campsites'),
    );
    final token = await AuthService.instance.getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['hasToilet'] = hasToilet.toString();
    request.fields['hasTap'] = hasTap.toString();

    for (final photo in photos) {
      request.files.add(await http.MultipartFile.fromPath('files', photo.path));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureOk(response);
    return Campsite.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<CamperUpdate>> getCamperUpdates() async {
    final response = await http.get(
      Uri.parse('$_base/api/updates'),
      headers: await _headers(),
    );
    _ensureOk(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CamperUpdate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile?> getUserById(String id) async {
    final response = await http.get(
      Uri.parse('$_base/api/users/$id'),
      headers: await _headers(),
    );
    if (response.statusCode == 404) return null;
    _ensureOk(response);
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<ConversationPreview>> getConversations() async {
    final response = await http.get(
      Uri.parse('$_base/api/conversations'),
      headers: await _headers(),
    );
    _ensureOk(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ConversationPreview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> getMessages(String otherUserId) async {
    final response = await http.get(
      Uri.parse('$_base/api/messages/$otherUserId'),
      headers: await _headers(),
    );
    _ensureOk(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String otherUserId,
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/api/messages/$otherUserId'),
      headers: await _headers(),
      body: jsonEncode({'text': text}),
    );
    _ensureOk(response);
    return ChatMessage.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ChatMessage> sendPhotoMessage({
    required String otherUserId,
    required File file,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/messages/$otherUserId/photo'),
    );
    final token = await AuthService.instance.getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureOk(response);
    return ChatMessage.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  AuthResponse _handleAuth(http.Response response) {
    if (response.statusCode == 409) {
      throw ApiException('Username already taken.', statusCode: 409);
    }
    if (response.statusCode == 401) {
      throw ApiException('Invalid username or password.', statusCode: 401);
    }
    _ensureOk(response);
    return AuthResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message = 'Request failed (${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        message = body['error'] as String? ?? message;
      }
    } catch (_) {
      // Keep default message when body is not JSON.
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
