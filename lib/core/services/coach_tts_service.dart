import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speaks coached exemplar text using the user's selected Coach voice profile
/// ('sarah', 'david', 'elena', 'marcus', 'alex').
class CoachTtsService {
  CoachTtsService._();
  static final CoachTtsService instance = CoachTtsService._();

  static const String _kVoicePrefsKey = 'hakiri_selected_coach_voice';

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _speaking = false;
  String _activeCoachId = 'sarah';

  bool get isSpeaking => _speaking;
  String get activeCoachId => _activeCoachId;

  static String normalizeCoachId(String? raw) {
    if (raw == null) return 'sarah';
    final key = raw.trim().toLowerCase();
    if (key == 'female') return 'sarah';
    if (key == 'male') return 'david';
    if (key == 'non_binary') return 'alex';
    if (coachSampleLines.containsKey(key)) return key;
    return 'sarah';
  }

  Future<void> init() async {
    await _ensureReady();
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kVoicePrefsKey);
      if (saved != null && saved.isNotEmpty) {
        _activeCoachId = normalizeCoachId(saved);
      }
    } catch (_) {}
  }

  Future<void> setActiveCoach(String coachId) async {
    _activeCoachId = normalizeCoachId(coachId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kVoicePrefsKey, _activeCoachId);
    } catch (_) {}
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() => _speaking = false);
      _tts.setCancelHandler(() => _speaking = false);
      _tts.setErrorHandler((_) => _speaking = false);
      _ready = true;
    } catch (e) {
      debugPrint('CoachTtsService _ensureReady error: $e');
    }
  }

  static const Map<String, String> coachSampleLines = {
    'sarah': "Hello, I'm Sarah. I'll help you speak with executive clarity and calm confidence.",
    'david': "Welcome. I'm David. Let's build a strong, authoritative voice that commands respect.",
    'elena': "Hi there, I'm Elena! Together, we'll make your delivery warm, engaging, and persuasive.",
    'marcus': "Hey, I'm Marcus. Let's get straight to the point with sharp, high-impact delivery.",
    'alex': "Hello! I'm Alex. Let's develop your natural rhythm and balanced articulation.",
  };

  Future<void> _applyVoiceProfile(String profile) async {
    await _ensureReady();
    final norm = normalizeCoachId(profile);

    double pitch;
    double rate;
    bool wantMale;
    List<String> preferredVoiceNames;

    switch (norm) {
      case 'david':
        wantMale = true;
        pitch = 0.72;
        rate = 0.44;
        preferredVoiceNames = ['daniel', 'arthur', 'en-gb', 'male'];
        break;
      case 'elena':
        wantMale = false;
        pitch = 1.22;
        rate = 0.52;
        preferredVoiceNames = ['karen', 'moira', 'zoe', 'ava', 'female'];
        break;
      case 'marcus':
        wantMale = true;
        pitch = 0.88;
        rate = 0.54;
        preferredVoiceNames = ['aaron', 'gordon', 'fred', 'tom', 'male'];
        break;
      case 'alex':
        wantMale = false;
        pitch = 1.04;
        rate = 0.49;
        preferredVoiceNames = ['tessa', 'nicky', 'samantha', 'female'];
        break;
      case 'sarah':
      default:
        wantMale = false;
        pitch = 1.0;
        rate = 0.46;
        preferredVoiceNames = ['samantha', 'allison', 'ava', 'female'];
        break;
    }

    try {
      final raw = await _tts.getVoices;
      if (raw is List && raw.isNotEmpty) {
        final en = raw
            .whereType<Map>()
            .map((m) => m.map((k, v) => MapEntry('$k', '$v')))
            .where((v) => (v['locale'] ?? '').toLowerCase().startsWith('en'))
            .toList();

        final matchesGender = en.where((v) {
          final gender = (v['gender'] ?? '').toLowerCase();
          final name = (v['name'] ?? '').toLowerCase();
          final isFemale = gender.contains('female') ||
              name.contains('female') ||
              name.contains('samantha') ||
              name.contains('karen') ||
              name.contains('moira') ||
              name.contains('ava') ||
              name.contains('zoe') ||
              name.contains('tessa') ||
              name.contains('allison') ||
              name.contains('nicky');
          final isMale = (!isFemale) &&
              (gender == 'male' ||
                  gender.contains('male') ||
                  name.contains('male') ||
                  name.contains('daniel') ||
                  name.contains('aaron') ||
                  name.contains('fred') ||
                  name.contains('tom') ||
                  name.contains('arthur') ||
                  name.contains('gordon'));
          return wantMale ? isMale : isFemale;
        }).toList();

        Map<String, String>? picked;
        for (final pref in preferredVoiceNames) {
          for (final v in matchesGender) {
            final name = (v['name'] ?? '').toLowerCase();
            final loc = (v['locale'] ?? '').toLowerCase();
            if (name.contains(pref) || loc.contains(pref)) {
              picked = {'name': v['name']!, 'locale': v['locale'] ?? 'en-US'};
              break;
            }
          }
          if (picked != null) break;
        }

        if (picked == null && matchesGender.isNotEmpty) {
          int index = 0;
          if (norm == 'elena' || norm == 'marcus') {
            index = (matchesGender.length > 1) ? 1 : 0;
          } else if (norm == 'alex') {
            index = (matchesGender.length > 2) ? 2 : (matchesGender.length - 1);
          }
          final v = matchesGender[index];
          picked = {'name': v['name']!, 'locale': v['locale'] ?? 'en-US'};
        }

        if (picked != null &&
            picked['name']!.isNotEmpty &&
            picked['locale']!.isNotEmpty) {
          await _tts.setVoice(picked);
        }
      }
    } catch (_) {}

    // Important: setPitch, setSpeechRate, setVolume must be called AFTER setVoice
    await _tts.setPitch(pitch);
    await _tts.setSpeechRate(rate);
    await _tts.setVolume(1.0);
  }

  Future<void> previewCoach(String coachId) async {
    final norm = normalizeCoachId(coachId);
    final sample = coachSampleLines[norm] ?? coachSampleLines['sarah']!;
    await speak(sample, voiceProfile: norm);
  }

  Future<void> speak(String text, {required String voiceProfile}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _ensureReady();
    if (_speaking) {
      await stop();
    }
    await _applyVoiceProfile(voiceProfile);
    _speaking = true;
    try {
      await _tts.speak(clean);
    } catch (e) {
      _speaking = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking = false;
  }
}
