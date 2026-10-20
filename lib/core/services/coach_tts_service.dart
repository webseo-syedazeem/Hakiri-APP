import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speaks coached exemplar text using the user's selected Coach voice profile
/// ('sarah', 'david', 'elena', 'marcus', 'alex').
///
/// Uses on-device TTS. We keep pitch near natural and prefer enhanced/neural
/// system voices so coaches sound human rather than pitch-shifted robots.
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
      if (!kIsWeb && Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final engines = await _tts.getEngines;
          if (engines is List) {
            final google = engines
                .map((e) => '$e')
                .firstWhere(
                  (e) => e.toLowerCase().contains('google'),
                  orElse: () => '',
                );
            if (google.isNotEmpty) {
              await _tts.setEngine(google);
            }
          }
        } catch (_) {}
      }

      await _tts.setLanguage('en-US');
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      // Natural cadence — avoid chipmunk / sluggish extremes.
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.48);
      _tts.setCompletionHandler(() => _speaking = false);
      _tts.setCancelHandler(() => _speaking = false);
      _tts.setErrorHandler((_) => _speaking = false);
      _ready = true;
    } catch (e) {
      debugPrint('CoachTtsService _ensureReady error: $e');
    }
  }

  static const Map<String, String> coachSampleLines = {
    'sarah':
        "Hello, I'm Sarah. I'll help you speak with calm clarity — clear, confident, and easy to follow.",
    'david':
        "Welcome. I'm David. Let's build a steady, authoritative presence that holds the room.",
    'elena':
        "Hi, I'm Elena. Together we'll make your delivery warmer, more engaging, and easier to connect with.",
    'marcus':
        "Hey, I'm Marcus. We'll keep it sharp and punchy — high impact, without the rush.",
    'alex':
        "Hello, I'm Alex. Let's find a natural rhythm — clear, balanced, and easy to listen to.",
  };

  /// Prefer enhanced / neural system voices; keep pitch near 1.0 so speech
  /// stays human. Coaches differ by voice identity + light rate/pitch only.
  Future<void> _applyVoiceProfile(String profile) async {
    await _ensureReady();
    final norm = normalizeCoachId(profile);

    // Pitch stays close to 1.0 — large shifts are what sound robotic.
    late final double pitch;
    late final double rate;
    late final bool wantMale;
    late final List<String> preferredVoiceNames;

    switch (norm) {
      case 'david':
        wantMale = true;
        pitch = 0.96;
        rate = 0.44;
        preferredVoiceNames = [
          'daniel',
          'arthur',
          'aaron',
          'fred',
          'gordon',
          'tom',
          'en-gb-x-gbd',
          'en-us-x-iom',
          'en-us-x-iol',
        ];
        break;
      case 'elena':
        wantMale = false;
        pitch = 1.04;
        rate = 0.47;
        preferredVoiceNames = [
          'karen',
          'moira',
          'zoe',
          'ava',
          'allison',
          'en-au',
          'en-us-x-sfg',
          'en-us-x-tpf',
        ];
        break;
      case 'marcus':
        wantMale = true;
        pitch = 1.0;
        rate = 0.50;
        preferredVoiceNames = [
          'aaron',
          'gordon',
          'nathan',
          'reed',
          'en-us-x-iog',
          'en-us-x-tpd',
          'en-gb-x-gbb',
        ];
        break;
      case 'alex':
        wantMale = false;
        pitch = 1.02;
        rate = 0.48;
        preferredVoiceNames = [
          'tessa',
          'nicky',
          'samantha',
          'susan',
          'en-za',
          'en-us-x-tpc',
          'en-us-x-sfg',
        ];
        break;
      case 'sarah':
      default:
        wantMale = false;
        pitch = 1.0;
        rate = 0.46;
        preferredVoiceNames = [
          'samantha',
          'allison',
          'ava',
          'susan',
          'en-us-x-sfg',
          'en-us-x-tpf',
          'en-gb-x-gba',
        ];
        break;
    }

    try {
      final raw = await _tts.getVoices;
      if (raw is List && raw.isNotEmpty) {
        final en = raw
            .whereType<Map>()
            .map((m) => m.map((k, v) => MapEntry('$k', '$v')))
            .where((v) {
              final loc = (v['locale'] ?? v['localeId'] ?? '').toLowerCase();
              final name = (v['name'] ?? '').toLowerCase();
              return loc.startsWith('en') ||
                  name.contains('en-us') ||
                  name.contains('en-gb') ||
                  name.contains('en-au') ||
                  name.contains('en_');
            })
            .toList();

        final gendered = en.where((v) {
          return wantMale ? _looksMale(v) : _looksFemale(v);
        }).toList();

        final pool = gendered.isNotEmpty ? gendered : en;
        final picked = _pickBestVoice(pool, preferredVoiceNames);

        if (picked != null &&
            (picked['name'] ?? '').isNotEmpty &&
            (picked['locale'] ?? '').isNotEmpty) {
          await _tts.setVoice({
            'name': picked['name']!,
            'locale': picked['locale']!,
          });
        }
      }
    } catch (_) {}

    // Pitch / rate AFTER setVoice (platform requirement).
    await _tts.setPitch(pitch.clamp(0.9, 1.1));
    await _tts.setSpeechRate(rate.clamp(0.38, 0.55));
    await _tts.setVolume(1.0);
  }

  static bool _looksFemale(Map<String, String> v) {
    final gender = (v['gender'] ?? '').toLowerCase();
    final name = (v['name'] ?? '').toLowerCase();
    if (gender.contains('female') || name.contains('female')) return true;
    const markers = [
      'samantha',
      'karen',
      'moira',
      'ava',
      'zoe',
      'tessa',
      'allison',
      'nicky',
      'susan',
      'victoria',
      'fiona',
      'kate',
      'serena',
      'siri female',
      'en-us-x-sfg',
      'en-us-x-tpf',
      'en-us-x-tpc',
      'en-gb-x-gba',
      'en-au-x-afh',
    ];
    return markers.any(name.contains);
  }

  static bool _looksMale(Map<String, String> v) {
    if (_looksFemale(v)) return false;
    final gender = (v['gender'] ?? '').toLowerCase();
    final name = (v['name'] ?? '').toLowerCase();
    if (gender == 'male' ||
        gender.contains('male') ||
        name.contains('male')) {
      return true;
    }
    const markers = [
      'daniel',
      'aaron',
      'fred',
      'tom',
      'arthur',
      'gordon',
      'nathan',
      'oliver',
      'reed',
      'rishi',
      'en-us-x-iom',
      'en-us-x-iol',
      'en-us-x-iog',
      'en-us-x-tpd',
      'en-gb-x-gbd',
      'en-gb-x-gbb',
    ];
    return markers.any(name.contains);
  }

  /// Higher score = more natural / higher quality system voice.
  static int _voiceQualityScore(Map<String, String> v) {
    final blob =
        '${v['name'] ?? ''} ${v['locale'] ?? ''} ${v['quality'] ?? ''} ${v['identifier'] ?? ''}'
            .toLowerCase();
    var score = 0;
    if (blob.contains('premium')) score += 120;
    if (blob.contains('enhanced')) score += 100;
    if (blob.contains('neural')) score += 90;
    if (blob.contains('wavenet')) score += 85;
    if (blob.contains('quality') && blob.contains('default')) score += 40;
    if (blob.contains('compact')) score -= 40; // often thinner / robotic
    if (blob.contains('siri')) score += 25;
    // Prefer US/GB/AU clear English locales slightly.
    if (blob.contains('en-us') || blob.contains('en_us')) score += 12;
    if (blob.contains('en-gb') || blob.contains('en_gb')) score += 10;
    if (blob.contains('en-au') || blob.contains('en_au')) score += 8;
    return score;
  }

  static Map<String, String>? _pickBestVoice(
    List<Map<String, String>> pool,
    List<String> preferredNames,
  ) {
    if (pool.isEmpty) return null;

    Map<String, String>? bestMatch;
    var bestMatchScore = -999999;

    for (final pref in preferredNames) {
      for (final v in pool) {
        final name = (v['name'] ?? '').toLowerCase();
        final loc = (v['locale'] ?? '').toLowerCase();
        if (!name.contains(pref) && !loc.contains(pref)) continue;
        final score = _voiceQualityScore(v) + 50; // name preference boost
        if (score > bestMatchScore) {
          bestMatchScore = score;
          bestMatch = v;
        }
      }
      if (bestMatch != null) break;
    }

    // Fall back: highest quality voice in the gender pool.
    Map<String, String>? bestAny;
    var bestAnyScore = -999999;
    for (final v in pool) {
      final score = _voiceQualityScore(v);
      if (score > bestAnyScore) {
        bestAnyScore = score;
        bestAny = v;
      }
    }

    final chosen = bestMatch ?? bestAny ?? pool.first;
    final locale = (chosen['locale'] ?? chosen['localeId'] ?? 'en-US').trim();
    final name = (chosen['name'] ?? '').trim();
    if (name.isEmpty) return null;
    return {
      'name': name,
      'locale': locale.isEmpty ? 'en-US' : locale,
    };
  }

  Future<void> previewCoach(String coachId) async {
    final norm = normalizeCoachId(coachId);
    final sample = coachSampleLines[norm] ?? coachSampleLines['sarah']!;
    await speak(sample, voiceProfile: norm);
  }

  Future<void> speak(String text, {required String voiceProfile}) async {
    await speakWithProgress(
      text,
      voiceProfile: voiceProfile,
    );
  }

  /// Speaks [text] and reports word progress for karaoke-style UI.
  /// [onWord] receives 1-based spoken word count (monotonic — never jumps back).
  Future<void> speakWithProgress(
    String text, {
    required String voiceProfile,
    void Function(int spokenWordCount, String word)? onWord,
    VoidCallback? onDone,
    /// Optional slower rate for prompt read-along (e.g. 0.38–0.42).
    double? speechRate,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      onDone?.call();
      return;
    }
    await _ensureReady();
    if (_speaking) {
      await stop();
    }
    await _applyVoiceProfile(voiceProfile);
    if (speechRate != null) {
      try {
        await _tts.setSpeechRate(speechRate.clamp(0.35, 0.55));
      } catch (_) {}
    }
    _speaking = true;

    final words =
        clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    // Character start index of each word in [clean].
    final starts = <int>[];
    var cursor = 0;
    for (final w in words) {
      final i = clean.indexOf(w, cursor);
      starts.add(i < 0 ? cursor : i);
      cursor = (i < 0 ? cursor : i) + w.length;
    }

    var lastCount = 0;
    try {
      _tts.setProgressHandler(
          (String _, int startOffset, int endOffset, String word) {
        if (onWord == null || words.isEmpty) return;
        var idx = 0;
        for (var i = 0; i < starts.length; i++) {
          if (startOffset >= starts[i]) idx = i;
        }
        final spoken = word.trim().toLowerCase();
        if (spoken.isNotEmpty) {
          for (var i = idx; i < words.length; i++) {
            final bare =
                words[i].toLowerCase().replaceAll(RegExp(r"[^a-z0-9']"), '');
            final token = spoken.replaceAll(RegExp(r"[^a-z0-9']"), '');
            if (bare == token ||
                bare.startsWith(token) ||
                token.startsWith(bare)) {
              idx = i;
              break;
            }
          }
        }
        final count = idx + 1;
        // Never report a lower word — avoids highlight jumping backward.
        if (count <= lastCount) return;
        lastCount = count;
        onWord(count, words[idx]);
      });
    } catch (_) {}

    try {
      await _tts.speak(clean);
    } catch (e) {
      _speaking = false;
    } finally {
      try {
        _tts.setProgressHandler((String _, int __, int ___, String ____) {});
      } catch (_) {}
      _speaking = false;
      onDone?.call();
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking = false;
  }
}
