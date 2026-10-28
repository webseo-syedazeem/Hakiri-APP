import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hakkiri_api_service.dart';
import 'karaoke_native_tts.dart';

/// Speaks coached exemplar text using the user's selected Coach voice profile
/// ('sarah', 'david', 'elena', 'marcus', 'alex').
///
/// Prefer Gemini TTS (same audio the app plays + word timings) so karaoke
/// highlight stays locked to speech. Falls back to on-device TTS if needed.
class CoachTtsService {
  CoachTtsService._();
  static final CoachTtsService instance = CoachTtsService._();

  static const String _kVoicePrefsKey = 'hakiri_selected_coach_voice';

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  bool _speaking = false;
  String _activeCoachId = 'sarah';
  Timer? _karaokePaceTimer;
  StreamSubscription? _posSub;
  StreamSubscription? _completeSub;
  Completer<void>? _playDone;
  int _speakGen = 0;

  /// In-memory clip cache so replay / second tap is instant.
  final Map<String, _CachedCoachClip> _clipCache = {};
  final Set<String> _prefetchInFlight = {};

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

  Future<void> _applyVoiceProfile(String profile) async {
    await _ensureReady();
    final norm = normalizeCoachId(profile);

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
    if (blob.contains('compact')) score -= 40;
    if (blob.contains('siri')) score += 25;
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
        final score = _voiceQualityScore(v) + 50;
        if (score > bestMatchScore) {
          bestMatchScore = score;
          bestMatch = v;
        }
      }
      if (bestMatch != null) break;
    }

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

  String _cacheKey(String text, String voiceProfile) =>
      '${normalizeCoachId(voiceProfile)}::${text.trim()}';

  /// Split into speakable lines so playback can start on sentence 1
  /// while later sentences still download.
  static List<String> splitSpeakChunks(String text) {
    final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return const [];
    final parts = <String>[];
    final re = RegExp(r'[^.!?]+[.!?]+|[^.!?]+$');
    for (final m in re.allMatches(clean)) {
      final s = m.group(0)?.trim() ?? '';
      if (s.isNotEmpty) parts.add(s);
    }
    if (parts.isEmpty) return [clean];
    // Merge tiny trailing fragments into the previous sentence.
    final merged = <String>[];
    for (final s in parts) {
      if (merged.isNotEmpty && s.split(RegExp(r'\s+')).length <= 3) {
        merged[merged.length - 1] = '${merged.last} $s';
      } else {
        merged.add(s);
      }
    }
    return merged;
  }

  /// Fetch + cache coach audio without playing (speeds up first tap).
  /// Prefetches the first sentence first so play can start quickly.
  Future<void> prefetch(String text, {required String voiceProfile}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final norm = normalizeCoachId(voiceProfile);
    final chunks = splitSpeakChunks(clean);
    final targets = chunks.length <= 1
        ? [clean]
        : chunks.take(2).toList(); // first two lines warm the queue
    for (final chunk in targets) {
      await _prefetchOne(chunk, norm);
    }
  }

  Future<void> _prefetchOne(String text, String norm) async {
    final key = _cacheKey(text, norm);
    if (_clipCache.containsKey(key) || _prefetchInFlight.contains(key)) return;
    _prefetchInFlight.add(key);
    try {
      final apiRate = (_defaultRateFor(norm) / 0.46).clamp(0.85, 1.15);
      final data = await HakkiriApiService.instance.coachSpeak(
        text: text,
        voiceProfile: norm,
        rate: apiRate,
      );
      final clip = _clipFromApiData(data, text);
      if (clip != null) {
        _clipCache[key] = clip;
        _trimCache();
      }
    } catch (e) {
      debugPrint('Coach TTS prefetch failed: $e');
    } finally {
      _prefetchInFlight.remove(key);
    }
  }

  Future<_CachedCoachClip?> _fetchClip({
    required String text,
    required String voiceProfile,
    required double flutterRate,
    required int gen,
  }) async {
    final cacheKey = _cacheKey(text, voiceProfile);
    final cached = _clipCache[cacheKey];
    if (cached != null) return cached;
    final apiRate = (flutterRate / 0.46).clamp(0.85, 1.15);
    final data = await HakkiriApiService.instance.coachSpeak(
      text: text,
      voiceProfile: voiceProfile,
      rate: apiRate,
    );
    if (gen != _speakGen) return null;
    final clip = _clipFromApiData(data, text);
    if (clip == null) return null;
    _clipCache[cacheKey] = clip;
    _trimCache();
    return clip;
  }

  void _trimCache() {
    while (_clipCache.length > 8) {
      _clipCache.remove(_clipCache.keys.first);
    }
  }

  _CachedCoachClip? _clipFromApiData(Map<String, dynamic> data, String clean) {
    final b64 = (data['audio_base64'] ?? data['audioBase64'] ?? '')
        .toString()
        .replaceAll(RegExp(r'\s'), '');
    if (b64.length < 64) return null;
    final mime =
        (data['mime_type'] ?? data['mimeType'] ?? 'audio/wav').toString();
    final ext = mime.contains('mpeg') || mime.contains('mp3')
        ? 'mp3'
        : mime.contains('wav')
            ? 'wav'
            : 'mp3';
    final durationMs = (data['duration_ms'] is num)
        ? (data['duration_ms'] as num).round()
        : 8000;
    final words =
        clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final timings = <({int startMs, int endMs, String word})>[];
    final rawWords = data['words'];
    if (rawWords is List) {
      for (final item in rawWords) {
        if (item is! Map) continue;
        final m = item.map((k, v) => MapEntry('$k', v));
        timings.add((
          startMs: (m['start_ms'] is num)
              ? (m['start_ms'] as num).round()
              : int.tryParse('${m['start_ms']}') ?? 0,
          endMs: (m['end_ms'] is num)
              ? (m['end_ms'] as num).round()
              : int.tryParse('${m['end_ms']}') ?? 0,
          word: '${m['word'] ?? ''}',
        ));
      }
    }
    if (timings.isEmpty && words.isNotEmpty) {
      final slice = durationMs / words.length;
      for (var i = 0; i < words.length; i++) {
        timings.add((
          startMs: (i * slice).round(),
          endMs: ((i + 1) * slice).round(),
          word: words[i],
        ));
      }
    }
    return _CachedCoachClip(
      bytes: base64Decode(b64),
      ext: ext,
      durationMs: durationMs,
      timings: timings,
    );
  }

  Future<void> speak(
    String text, {
    required String voiceProfile,
    VoidCallback? onPlaybackStarted,
    /// True while waiting for audio (first clip or gap between sentences).
    void Function(bool buffering)? onBufferingChanged,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (_speaking) await stop();

    final norm = normalizeCoachId(voiceProfile);
    final gen = ++_speakGen;
    _speaking = true;
    final rate = _defaultRateFor(norm);
    try {
      final chunks = splitSpeakChunks(clean);
      // Chunked playback: start sentence 1 ASAP; load 2/3 while it plays.
      if (chunks.length > 1) {
        final played = await _speakChunksViaApi(
          chunks: chunks,
          voiceProfile: norm,
          flutterRate: rate,
          gen: gen,
          onPlaybackStarted: onPlaybackStarted,
          onBufferingChanged: onBufferingChanged,
        );
        if (gen != _speakGen) return;
        if (played) return;
      }

      onBufferingChanged?.call(
        !_clipCache.containsKey(_cacheKey(clean, norm)),
      );
      final usedApi = await _speakViaApi(
        clean: clean,
        words: clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList(),
        voiceProfile: norm,
        flutterRate: rate,
        gen: gen,
        paintTo: (_) {},
        onPlaybackStarted: () {
          onBufferingChanged?.call(false);
          onPlaybackStarted?.call();
        },
      );
      if (gen != _speakGen) return;
      if (usedApi) return;

      onPlaybackStarted?.call();
      await _ensureReady();
      await _applyVoiceProfile(norm);
      await _tts.speak(clean);
    } catch (e) {
      debugPrint('CoachTtsService speak error: $e');
    } finally {
      if (gen == _speakGen) _speaking = false;
    }
  }

  /// Play sentence-by-sentence; prefetch the next clip while current plays.
  Future<bool> _speakChunksViaApi({
    required List<String> chunks,
    required String voiceProfile,
    required double flutterRate,
    required int gen,
    VoidCallback? onPlaybackStarted,
    void Function(bool buffering)? onBufferingChanged,
  }) async {
    try {
      // Kick off line 1 + line 2 in parallel.
      if (!_clipCache.containsKey(_cacheKey(chunks.first, voiceProfile))) {
        onBufferingChanged?.call(true);
      }
      final firstFuture = _fetchClip(
        text: chunks.first,
        voiceProfile: voiceProfile,
        flutterRate: flutterRate,
        gen: gen,
      );
      if (chunks.length > 1) {
        unawaited(
          _fetchClip(
            text: chunks[1],
            voiceProfile: voiceProfile,
            flutterRate: flutterRate,
            gen: gen,
          ),
        );
      }
      var started = false;
      for (var i = 0; i < chunks.length; i++) {
        if (gen != _speakGen) return true;
        // Between sentences: show loading on the play button if next clip
        // is still downloading.
        if (i > 0 &&
            !_clipCache.containsKey(_cacheKey(chunks[i], voiceProfile))) {
          onBufferingChanged?.call(true);
        }
        final clip = i == 0
            ? await firstFuture
            : await _fetchClip(
                text: chunks[i],
                voiceProfile: voiceProfile,
                flutterRate: flutterRate,
                gen: gen,
              );
        if (clip == null) {
          if (i == 0) return false;
          onBufferingChanged?.call(false);
          continue;
        }
        // Warm the next sentence while this one plays.
        if (i + 1 < chunks.length) {
          unawaited(
            _fetchClip(
              text: chunks[i + 1],
              voiceProfile: voiceProfile,
              flutterRate: flutterRate,
              gen: gen,
            ),
          );
        }
        final ok = await _playClip(
          clip: clip,
          gen: gen,
          paintTo: (_) {},
          onPlaybackStarted: () {
            onBufferingChanged?.call(false);
            if (!started) {
              started = true;
              onPlaybackStarted?.call();
            }
          },
        );
        if (!ok || gen != _speakGen) return true;
      }
      return started;
    } catch (e) {
      debugPrint('Chunked coach-speak failed: $e');
      return false;
    }
  }

  Future<void> _tearDownPlayerSubs() async {
    _karaokePaceTimer?.cancel();
    _karaokePaceTimer = null;
    await _posSub?.cancel();
    _posSub = null;
    await _completeSub?.cancel();
    _completeSub = null;
  }

  /// Speaks [text] and reports word progress for karaoke-style UI.
  /// [onWord] receives 1-based spoken word count (monotonic — never jumps back).
  ///
  /// Primary path: Gemini TTS audio + timings driven by [AudioPlayer] position
  /// so highlight and speech stay locked. Native / flutter_tts are fallbacks.
  Future<void> speakWithProgress(
    String text, {
    required String voiceProfile,
    void Function(int spokenWordCount, String word)? onWord,
    VoidCallback? onDone,
    double? speechRate,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      onDone?.call();
      return;
    }
    if (_speaking) {
      await stop();
    }

    final words =
        clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final norm = normalizeCoachId(voiceProfile);
    final rate = (speechRate ?? _defaultRateFor(norm)).clamp(0.35, 0.55);
    final gen = ++_speakGen;

    var uiCount = 0;
    void paintTo(int count) {
      if (onWord == null || words.isEmpty) return;
      final capped = count.clamp(0, words.length);
      while (uiCount < capped) {
        uiCount++;
        onWord(uiCount, words[uiCount - 1]);
      }
    }

    _speaking = true;

    // 1) ElevenLabs / Gemini — same audio the user hears + word timings.
    final usedApi = await _speakViaApi(
      clean: clean,
      words: words,
      voiceProfile: norm,
      flutterRate: rate,
      gen: gen,
      paintTo: paintTo,
      onPlaybackStarted: null,
    );
    if (gen != _speakGen) return;
    if (usedApi) {
      if (_speaking && onWord != null && words.isNotEmpty) {
        paintTo(words.length);
      }
      _speaking = false;
      onDone?.call();
      return;
    }

    // 2) Native karaoke fallback
    final pitch = _defaultPitchFor(norm);
    final starts = <int>[];
    var cursor = 0;
    for (final w in words) {
      final i = clean.indexOf(w, cursor);
      starts.add(i < 0 ? cursor : i);
      cursor = (i < 0 ? cursor : i) + w.length;
    }

    var nativePeak = 0;
    DateTime? audioStartedAt;
    final msPerWord = (340 * (0.50 / rate)).round().clamp(260, 420);

    int countFromStart(int startOffset, String spokenWord) {
      var idx = 0;
      for (var i = 0; i < starts.length; i++) {
        if (startOffset >= starts[i]) idx = i;
      }
      final spoken = spokenWord.trim().toLowerCase();
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
      return idx + 1;
    }

    void syncHighlight() {
      if (!_speaking || onWord == null || words.isEmpty) return;
      final started = audioStartedAt;
      if (started == null) {
        if (nativePeak > 0) paintTo(nativePeak);
        return;
      }
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      final byTime = elapsed < 40
          ? 1
          : (elapsed / msPerWord).floor().clamp(1, words.length);
      var target = byTime;
      if (nativePeak > byTime) {
        target = (byTime + 1).clamp(1, words.length);
      }
      paintTo(target);
    }

    void startHighlightClock() {
      audioStartedAt ??= DateTime.now();
      paintTo(1);
      _karaokePaceTimer?.cancel();
      _karaokePaceTimer =
          Timer.periodic(const Duration(milliseconds: 40), (_) {
        if (!_speaking) {
          _karaokePaceTimer?.cancel();
          _karaokePaceTimer = null;
          return;
        }
        syncHighlight();
      });
    }

    if (KaraokeNativeTts.instance.isSupported) {
      try {
        await KaraokeNativeTts.instance.speak(
          clean,
          rate: rate,
          pitch: pitch,
          onStart: () {
            if (!_speaking || gen != _speakGen) return;
            startHighlightClock();
          },
          onProgress: (start, end, word) {
            if (!_speaking || gen != _speakGen) return;
            if (audioStartedAt == null) startHighlightClock();
            final atStart = countFromStart(start, word);
            final atEnd =
                end > start ? countFromStart(end - 1, word) : atStart;
            final peak = atEnd > atStart ? atEnd : atStart;
            if (peak > nativePeak) nativePeak = peak;
            syncHighlight();
          },
        );
        _karaokePaceTimer?.cancel();
        _karaokePaceTimer = null;
        if (gen != _speakGen) return;
        if (_speaking && onWord != null && words.isNotEmpty) {
          paintTo(words.length);
        }
        _speaking = false;
        onDone?.call();
        return;
      } catch (e) {
        debugPrint('Native karaoke TTS fallback: $e');
        _karaokePaceTimer?.cancel();
        _karaokePaceTimer = null;
      }
    }

    // 3) flutter_tts last resort
    await _ensureReady();
    await _applyVoiceProfile(voiceProfile);
    try {
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
    } catch (_) {}

    try {
      _tts.setProgressHandler(
          (String _, int startOffset, int endOffset, String word) {
        if (!_speaking || onWord == null || gen != _speakGen) return;
        final atStart = countFromStart(startOffset, word);
        final atEnd = endOffset > startOffset
            ? countFromStart(endOffset - 1, word)
            : atStart;
        paintTo(atEnd > atStart ? atEnd : atStart);
      });
    } catch (_) {}

    try {
      await _tts.speak(clean);
    } catch (_) {
      _speaking = false;
    } finally {
      try {
        _tts.setProgressHandler((String _, int __, int ___, String ____) {});
      } catch (_) {}
      if (gen != _speakGen) return;
      if (_speaking && onWord != null && words.isNotEmpty) {
        paintTo(words.length);
      }
      _speaking = false;
      onDone?.call();
    }
  }

  /// Returns true if ElevenLabs / Gemini coach audio played successfully.
  Future<bool> _speakViaApi({
    required String clean,
    required List<String> words,
    required String voiceProfile,
    required double flutterRate,
    required int gen,
    required void Function(int count) paintTo,
    VoidCallback? onPlaybackStarted,
  }) async {
    try {
      final clip = await _fetchClip(
        text: clean,
        voiceProfile: voiceProfile,
        flutterRate: flutterRate,
        gen: gen,
      );
      if (gen != _speakGen) return true;
      if (clip == null) return false;
      return _playClip(
        clip: clip,
        gen: gen,
        paintTo: paintTo,
        onPlaybackStarted: onPlaybackStarted,
      );
    } catch (e) {
      debugPrint('Coach-speak API failed, falling back: $e');
      await _tearDownPlayerSubs();
      try {
        await _player.stop();
      } catch (_) {}
      return false;
    }
  }

  Future<bool> _playClip({
    required _CachedCoachClip clip,
    required int gen,
    required void Function(int count) paintTo,
    VoidCallback? onPlaybackStarted,
  }) async {
    final timings = clip.timings;
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/coach_tts_${DateTime.now().millisecondsSinceEpoch}.${clip.ext}',
    );
    await file.writeAsBytes(clip.bytes, flush: true);
    if (gen != _speakGen) {
      try {
        await file.delete();
      } catch (_) {}
      return true;
    }

    await _tearDownPlayerSubs();
    try {
      await _player.stop();
    } catch (_) {}

    try {
      await _player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.assistanceAccessibility,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
    } catch (_) {}

    void paintFromMs(int ms) {
      if (!_speaking || gen != _speakGen || timings.isEmpty) return;
      var idx = 0;
      for (var i = 0; i < timings.length; i++) {
        if (ms >= timings[i].startMs) idx = i;
      }
      paintTo(idx + 1);
    }

    final done = Completer<void>();
    _playDone = done;

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    _posSub = _player.onPositionChanged.listen((pos) {
      paintFromMs(pos.inMilliseconds);
    });
    _karaokePaceTimer =
        Timer.periodic(const Duration(milliseconds: 32), (_) async {
      if (!_speaking || gen != _speakGen) return;
      try {
        final pos = await _player.getCurrentPosition();
        if (pos != null) paintFromMs(pos.inMilliseconds);
      } catch (_) {}
    });

    paintTo(1);
    onPlaybackStarted?.call();
    await _player.play(DeviceFileSource(file.path));

    await done.future.timeout(
      Duration(milliseconds: clip.durationMs + 4000),
      onTimeout: () {},
    );

    await _tearDownPlayerSubs();
    try {
      await file.delete();
    } catch (_) {}
    try {
      final tmp = Directory(dir.path);
      await for (final entity in tmp.list()) {
        if (entity is File &&
            entity.path.contains('coach_tts_') &&
            (entity.path.endsWith('.wav') || entity.path.endsWith('.mp3'))) {
          final age = DateTime.now().difference(await entity.lastModified());
          if (age.inMinutes > 10) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}

    return gen == _speakGen;
  }

  double _defaultRateFor(String norm) {
    switch (norm) {
      case 'david':
        return 0.44;
      case 'elena':
        return 0.47;
      case 'marcus':
        return 0.50;
      case 'alex':
        return 0.48;
      case 'sarah':
      default:
        return 0.46;
    }
  }

  double _defaultPitchFor(String norm) {
    switch (norm) {
      case 'david':
        return 0.96;
      case 'elena':
        return 1.04;
      case 'marcus':
        return 1.0;
      case 'alex':
        return 1.02;
      case 'sarah':
      default:
        return 1.0;
    }
  }

  Future<void> stop() async {
    _speakGen++;
    _karaokePaceTimer?.cancel();
    _karaokePaceTimer = null;
    final pending = _playDone;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
    _playDone = null;
    await _tearDownPlayerSubs();
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await KaraokeNativeTts.instance.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking = false;
  }
}

class _CachedCoachClip {
  final List<int> bytes;
  final String ext;
  final int durationMs;
  final List<({int startMs, int endMs, String word})> timings;

  _CachedCoachClip({
    required this.bytes,
    required this.ext,
    required this.durationMs,
    required this.timings,
  });
}
