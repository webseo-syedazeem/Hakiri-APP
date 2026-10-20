import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class HakkiriApiException implements Exception {
  final String message;
  final int? statusCode;

  HakkiriApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class HakkiriApiService {
  HakkiriApiService._();
  static final HakkiriApiService instance = HakkiriApiService._();

  /// Reuses TCP/TLS connections across requests (big win vs new client each call).
  final http.Client _client = http.Client();

  static const _tokenKey = 'hakkiri_auth_token';
  static const _userIdKey = 'hakkiri_user_id';
  static const _fullNameKey = 'hakkiri_full_name';
  static const _emailKey = 'hakkiri_email';
  static const _onboardedKey = 'hakkiri_is_onboarded';
  static const _loggedInKey = 'hakkiri_logged_in';

  String? _token;
  String? _userId;
  String? _fullName;
  String? _email;
  bool _isOnboarded = false;
  bool _sessionLoaded = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get fullName => _fullName;
  String? get email => _email;
  bool get isLoggedIn =>
      (_token != null && _token!.isNotEmpty);
  bool get isOnboardedCached => _isOnboarded;
  bool get sessionLoaded => _sessionLoaded;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getString(_userIdKey);
    _fullName = prefs.getString(_fullNameKey);
    _email = prefs.getString(_emailKey);
    _isOnboarded = prefs.getBool(_onboardedKey) ?? false;
    // Redundant flag in case token key was ever wiped but login marker remains.
    final loggedInFlag = prefs.getBool(_loggedInKey) ?? false;
    if ((_token == null || _token!.isEmpty) && !loggedInFlag) {
      _token = null;
    }
    _sessionLoaded = true;
  }

  Future<void> _persistSession({
    required String token,
    required String userId,
    required String fullName,
    String email = '',
  }) async {
    _token = token;
    _userId = userId;
    _fullName = fullName;
    if (email.isNotEmpty) _email = email;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_tokenKey, token),
      prefs.setString(_userIdKey, userId),
      prefs.setString(_fullNameKey, fullName),
      prefs.setBool(_loggedInKey, true),
      if (_email != null && _email!.isNotEmpty) prefs.setString(_emailKey, _email!),
    ]);
  }

  Future<void> persistOnboarded(bool value) async {
    _isOnboarded = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, value);
  }

  Future<void> persistSessionFields({String? fullName, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    if (fullName != null) {
      _fullName = fullName;
      await prefs.setString(_fullNameKey, fullName);
    }
    if (email != null && email.isNotEmpty) {
      _email = email;
      await prefs.setString(_emailKey, email);
    }
  }

  Future<void> clearSession() async {
    _token = null;
    _userId = null;
    _fullName = null;
    _email = null;
    _isOnboarded = false;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_userIdKey),
      prefs.remove(_fullNameKey),
      prefs.remove(_emailKey),
      prefs.remove(_onboardedKey),
      prefs.remove(_loggedInKey),
    ]);
  }

  Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final t = _token;
      if (t == null || t.isEmpty) {
        throw HakkiriApiException('Please create an account first.');
      }
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      throw HakkiriApiException(
        'Server returned an unexpected response.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body['message'] ?? body['error'] ?? 'Request failed.').toString();
    throw HakkiriApiException(message, statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> _get(String path, {bool auth = false}) async {
    final response = await _client
        .get(ApiConfig.api(path), headers: _headers(auth: auth))
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    return (body['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final response = await _client
        .post(
          ApiConfig.api(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(timeout);
    final decoded = _decode(response);
    return (decoded['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final response = await _client
        .put(
          ApiConfig.api(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    return (decoded['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> _delete(String path, {bool auth = false}) async {
    final response = await _client
        .delete(ApiConfig.api(path), headers: _headers(auth: auth))
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    return (decoded['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/register', body: {
      'full_name': fullName,
      'email': email,
      'password': password,
    });
    final user = (data['user'] as Map<String, dynamic>?) ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) {
      throw HakkiriApiException('Account created but no token was returned.');
    }
    await _persistSession(
      token: token,
      userId: (user['id'] ?? '').toString(),
      fullName: (user['full_name'] ?? fullName).toString(),
      email: (user['email'] ?? email).toString(),
    );
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final user = (data['user'] as Map<String, dynamic>?) ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) {
      throw HakkiriApiException('Login succeeded but no token was returned.');
    }
    await _persistSession(
      token: token,
      userId: (user['id'] ?? '').toString(),
      fullName: (user['full_name'] ?? '').toString(),
      email: (user['email'] ?? email).toString(),
    );
    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final data = await _post('/auth/google', body: {
      'id_token': idToken,
    });
    final user = (data['user'] as Map<String, dynamic>?) ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) {
      throw HakkiriApiException('Google sign-in succeeded but no token was returned.');
    }
    await _persistSession(
      token: token,
      userId: (user['id'] ?? '').toString(),
      fullName: (user['full_name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
    );
    return data;
  }

  Future<Map<String, dynamic>> loginWithApple({
    required String idToken,
    String? fullName,
  }) async {
    final data = await _post('/auth/apple', body: {
      'id_token': idToken,
      if (fullName != null && fullName.trim().length >= 2)
        'full_name': fullName.trim(),
    });
    final user = (data['user'] as Map<String, dynamic>?) ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) {
      throw HakkiriApiException('Apple sign-in succeeded but no token was returned.');
    }
    await _persistSession(
      token: token,
      userId: (user['id'] ?? '').toString(),
      fullName: (user['full_name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
    );
    return data;
  }

  Future<Map<String, dynamic>> me() => _get('/auth/me', auth: true);

  /// Single round-trip for home/login refresh (replaces 5 separate calls).
  Future<Map<String, dynamic>> bootstrap({int limit = 30}) =>
      _get('/bootstrap?limit=$limit', auth: true);

  Future<Map<String, dynamic>> submitAssessment({
    required String name,
    required String voiceProfile,
    required String careerStage,
    required String careerType,
    required String speakingConfidence,
    required String primaryRoadblock,
    required String primaryGoal,
  }) {
    return _post('/assessment', auth: true, body: {
      'name': name,
      'voice_profile': voiceProfile,
      'career_stage': careerStage,
      'career_type': careerType,
      'speaking_confidence': speakingConfidence,
      'primary_roadblock': primaryRoadblock,
      'primary_goal': primaryGoal,
    });
  }

  Future<Map<String, dynamic>> dashboard() => _get('/dashboard', auth: true);

  Future<Map<String, dynamic>> sessions({int limit = 20}) =>
      _get('/sessions?limit=$limit', auth: true);

  Future<Map<String, dynamic>> deleteSession(String sessionId) =>
      _delete('/sessions/$sessionId', auth: true);

  Future<Map<String, dynamic>> dailyAnchor() => _get('/daily-anchor', auth: true);

  Future<Map<String, dynamic>> challenges() => _get('/challenges', auth: true);

  Future<Map<String, dynamic>> joinChallenge(String slug) =>
      _post('/challenges/$slug/join', auth: true);

  Future<Map<String, dynamic>> freezeStreak() =>
      _post('/streaks/freeze', auth: true);

  Future<Map<String, dynamic>> settings() => _get('/settings', auth: true);

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> patch) =>
      _put('/settings', auth: true, body: patch);

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) =>
      _put('/profile', auth: true, body: body);

  Future<Map<String, dynamic>> plan() => _get('/plan', auth: true);

  Future<Map<String, dynamic>> chooseSubscription(String tier) =>
      _post('/subscription', auth: true, body: {'tier': tier});

  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body) =>
      _post('/sessions', auth: true, body: body);

  Future<Map<String, dynamic>> createLiveToken({String? systemInstruction}) =>
      _post('/ai/live-token', auth: true, body: {
        if (systemInstruction != null && systemInstruction.trim().isNotEmpty)
          'system_instruction': systemInstruction.trim(),
      });

  /// Gemini Flash scoring (optional audio base64 → transcribe + score).
  Future<Map<String, dynamic>> analyzeSpeech(Map<String, dynamic> body) =>
      _post(
        '/ai/analyze-speech',
        auth: true,
        body: body,
        // Audio transcription + scoring can take longer than text-only.
        timeout: const Duration(seconds: 90),
      );

  /// Guided Debate Me: opening audio/text → one AI pushback line.
  Future<Map<String, dynamic>> debatePushback(Map<String, dynamic> body) =>
      _post(
        '/ai/debate-pushback',
        auth: true,
        body: body,
        timeout: const Duration(seconds: 90),
      );

  /// Save FCM device token for daily practice reminders.
  Future<Map<String, dynamic>> registerDeviceToken({
    required String token,
    required String platform,
  }) =>
      _post('/device-token', auth: true, body: {
        'token': token,
        'platform': platform,
      });

  /// Remove FCM tokens when Reminder is off or OS notifications are denied.
  Future<Map<String, dynamic>> clearDeviceToken() =>
      _delete('/device-token', auth: true);

  /// Next catalog prompt for an activity (server-chosen question).
  Future<Map<String, dynamic>> nextPrompt({
    required String activitySlug,
    String? difficulty,
    String? careerType,
    String? excludePromptId,
  }) {
    final q = <String, String>{
      'activity': activitySlug,
      if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
      if (careerType != null && careerType.isNotEmpty) 'career_type': careerType,
      if (excludePromptId != null && excludePromptId.isNotEmpty)
        'exclude': excludePromptId,
    };
    final query = q.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return _get('/prompts/next?$query', auth: true);
  }
}
