import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Crisp, beautifully illustrated vector SVG character avatars for the 5 Voice Coaches.
class CoachCharacterAvatar extends StatelessWidget {
  final String coachId; // 'sarah', 'david', 'elena', 'marcus', 'alex'
  final double size;

  const CoachCharacterAvatar({
    super.key,
    required this.coachId,
    this.size = 80,
  });

  static String _normalizeId(String id) {
    switch (id.toLowerCase().trim()) {
      case 'david':
      case 'male':
        return 'david';
      case 'elena':
        return 'elena';
      case 'marcus':
        return 'marcus';
      case 'alex':
      case 'non_binary':
        return 'alex';
      case 'sarah':
      case 'female':
      default:
        return 'sarah';
    }
  }

  static const String _sarahSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="48" fill="#EFF6FF" stroke="#DBEAFE" stroke-width="2"/>
  <!-- Body / Navy Blazer -->
  <path d="M22 96 C22 76 34 72 42 70 L42 80 L58 80 L58 70 C66 72 78 76 78 96 Z" fill="#1E3A8A"/>
  <path d="M42 70 L50 82 L58 70 Z" fill="#FFFFFF"/>
  <path d="M46 70 L50 78 L54 70 Z" fill="#F87171"/>
  <!-- Neck -->
  <rect x="44" y="58" width="12" height="15" rx="3" fill="#FCD34D"/>
  <path d="M44 65 Q50 68 56 65 L56 70 L44 70 Z" fill="#F59E0B" opacity="0.3"/>
  <!-- Head -->
  <ellipse cx="50" cy="46" rx="17" ry="19" fill="#FDE68A"/>
  <!-- Hair Behind -->
  <path d="M29 44 C29 28 36 20 50 20 C64 20 71 28 71 44 C71 58 68 62 67 64 C64 56 65 48 64 42 C58 40 42 40 36 42 C35 48 36 56 33 64 C32 62 29 58 29 44 Z" fill="#1E293B"/>
  <!-- Bangs / Front Hair -->
  <path d="M33 36 C36 26 44 24 50 24 C56 24 64 26 67 36 C64 33 58 31 50 31 C42 31 36 33 33 36 Z" fill="#0F172A"/>
  <!-- Eyes -->
  <circle cx="43" cy="45" r="2.2" fill="#0F172A"/>
  <circle cx="57" cy="45" r="2.2" fill="#0F172A"/>
  <!-- Eye highlights -->
  <circle cx="43.8" cy="44.2" r="0.7" fill="#FFFFFF"/>
  <circle cx="57.8" cy="44.2" r="0.7" fill="#FFFFFF"/>
  <!-- Eyebrows -->
  <path d="M39 40 Q43 38 47 40" stroke="#0F172A" stroke-width="1.2" stroke-linecap="round" fill="none"/>
  <path d="M53 40 Q57 38 61 40" stroke="#0F172A" stroke-width="1.2" stroke-linecap="round" fill="none"/>
  <!-- Smile -->
  <path d="M45 54 Q50 58 55 54" stroke="#DC2626" stroke-width="1.4" stroke-linecap="round" fill="none"/>
  <!-- Pearl Earrings -->
  <circle cx="32.5" cy="49" r="2.2" fill="#FFFFFF" stroke="#E2E8F0" stroke-width="0.8"/>
  <circle cx="67.5" cy="49" r="2.2" fill="#FFFFFF" stroke="#E2E8F0" stroke-width="0.8"/>
</svg>
''';

  static const String _davidSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="48" fill="#F8FAFC" stroke="#E2E8F0" stroke-width="2"/>
  <!-- Body / Dark Charcoal Suit -->
  <path d="M20 96 C20 74 32 70 42 68 L42 82 L58 82 L58 68 C68 70 80 74 80 96 Z" fill="#0F172A"/>
  <!-- Shirt & Tie -->
  <path d="M42 68 L50 82 L58 68 Z" fill="#FFFFFF"/>
  <path d="M48 70 L52 70 L53 88 L50 92 L47 88 Z" fill="#2563EB"/>
  <!-- Neck -->
  <rect x="43" y="56" width="14" height="15" rx="3" fill="#E29578"/>
  <!-- Head -->
  <path d="M33 42 C33 30 40 26 50 26 C60 26 67 30 67 42 C67 54 62 62 50 62 C38 62 33 54 33 42 Z" fill="#F2B880"/>
  <!-- Short Executive Hair -->
  <path d="M31 38 C31 24 38 18 50 18 C62 18 69 22 69 36 C67 30 61 25 50 25 C41 25 35 29 31 38 Z" fill="#475569"/>
  <!-- Neat beard stubble line -->
  <path d="M37 49 C39 58 45 61 50 61 C55 61 61 58 63 49 C63 56 57 63 50 63 C43 63 37 56 37 49 Z" fill="#334155" opacity="0.4"/>
  <!-- Eyes -->
  <circle cx="43" cy="43" r="2.2" fill="#0F172A"/>
  <circle cx="57" cy="43" r="2.2" fill="#0F172A"/>
  <!-- Eyebrows -->
  <path d="M39 38 Q44 36 47 39" stroke="#334155" stroke-width="1.8" stroke-linecap="round" fill="none"/>
  <path d="M53 39 Q56 36 61 38" stroke="#334155" stroke-width="1.8" stroke-linecap="round" fill="none"/>
  <!-- Smile -->
  <path d="M45 54 Q50 57 55 54" stroke="#9A3412" stroke-width="1.6" stroke-linecap="round" fill="none"/>
</svg>
''';

  static const String _elenaSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="48" fill="#ECFDF5" stroke="#A7F3D0" stroke-width="2"/>
  <!-- Body / Emerald Jacket -->
  <path d="M22 96 C22 75 34 71 43 69 L43 80 L57 80 L57 69 C66 71 78 75 78 96 Z" fill="#059669"/>
  <path d="M43 69 L50 81 L57 69 Z" fill="#FEF3C7"/>
  <!-- Neck -->
  <rect x="44" y="57" width="12" height="15" rx="3" fill="#FBBF24"/>
  <!-- Wavy Long Auburn Hair Behind -->
  <path d="M26 46 C26 26 35 18 50 18 C65 18 74 26 74 46 C74 66 72 78 68 84 C64 74 65 58 64 46 C58 40 42 40 36 46 C35 58 36 74 32 84 C28 78 26 66 26 46 Z" fill="#9A3412"/>
  <!-- Head -->
  <ellipse cx="50" cy="46" rx="16.5" ry="18.5" fill="#FDE68A"/>
  <!-- Side Hair Strands -->
  <path d="M33 34 C36 24 43 22 50 22 C57 22 64 24 67 34 C63 30 57 28 50 28 C43 28 37 30 33 34 Z" fill="#7C2D12"/>
  <!-- Eyes -->
  <circle cx="43" cy="44" r="2.2" fill="#0F172A"/>
  <circle cx="57" cy="44" r="2.2" fill="#0F172A"/>
  <circle cx="43.8" cy="43.2" r="0.7" fill="#FFFFFF"/>
  <circle cx="57.8" cy="43.2" r="0.7" fill="#FFFFFF"/>
  <!-- Eyebrows -->
  <path d="M39 39 Q43 37 47 39" stroke="#7C2D12" stroke-width="1.3" stroke-linecap="round" fill="none"/>
  <path d="M53 39 Q57 37 61 39" stroke="#7C2D12" stroke-width="1.3" stroke-linecap="round" fill="none"/>
  <!-- Warm Smile -->
  <path d="M44 53 Q50 58 56 53" stroke="#DC2626" stroke-width="1.6" stroke-linecap="round" fill="none"/>
  <!-- Gold hoop earrings -->
  <circle cx="32" cy="48" r="2.5" fill="none" stroke="#D97706" stroke-width="1.2"/>
  <circle cx="68" cy="48" r="2.5" fill="none" stroke="#D97706" stroke-width="1.2"/>
</svg>
''';

  static const String _marcusSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="48" fill="#FEF2F2" stroke="#FECDD3" stroke-width="2"/>
  <!-- Body / Burgundy Blazer -->
  <path d="M20 96 C20 74 32 70 42 68 L42 82 L58 82 L58 68 C68 70 80 74 80 96 Z" fill="#881337"/>
  <path d="M42 68 L50 82 L58 68 Z" fill="#FFFFFF"/>
  <path d="M48 70 L52 70 L53 88 L50 92 L47 88 Z" fill="#0F172A"/>
  <!-- Neck -->
  <rect x="43" y="56" width="14" height="15" rx="3" fill="#B45309"/>
  <!-- Head -->
  <ellipse cx="50" cy="44" rx="17" ry="19" fill="#D97706"/>
  <!-- Sleek Fade Cut Hair -->
  <path d="M32 38 C32 24 40 18 50 18 C60 18 68 24 68 38 C65 26 58 22 50 22 C42 22 35 26 32 38 Z" fill="#1C1917"/>
  <!-- Sharp Modern Glasses -->
  <rect x="36" y="38" width="12" height="9" rx="2.5" fill="none" stroke="#0F172A" stroke-width="1.8"/>
  <rect x="52" y="38" width="12" height="9" rx="2.5" fill="none" stroke="#0F172A" stroke-width="1.8"/>
  <path d="M48 42 L52 42" stroke="#0F172A" stroke-width="1.8"/>
  <!-- Eyes Behind Glasses -->
  <circle cx="42" cy="42.5" r="2" fill="#0F172A"/>
  <circle cx="58" cy="42.5" r="2" fill="#0F172A"/>
  <!-- Eyebrows -->
  <path d="M37 35 Q42 33 46 35" stroke="#1C1917" stroke-width="1.5" stroke-linecap="round" fill="none"/>
  <path d="M54 35 Q58 33 63 35" stroke="#1C1917" stroke-width="1.5" stroke-linecap="round" fill="none"/>
  <!-- Confident Smile -->
  <path d="M45 54 Q50 57 55 54" stroke="#78350F" stroke-width="1.6" stroke-linecap="round" fill="none"/>
</svg>
''';

  static const String _alexSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="48" fill="#F5F3FF" stroke="#DDD6FE" stroke-width="2"/>
  <!-- Body / Indigo Turtleneck -->
  <path d="M22 96 C22 75 34 71 43 69 L43 78 L57 78 L57 69 C66 71 78 75 78 96 Z" fill="#4338CA"/>
  <!-- Turtleneck collar -->
  <rect x="42" y="63" width="16" height="11" rx="4" fill="#3730A3"/>
  <!-- Neck -->
  <rect x="44" y="55" width="12" height="14" rx="3" fill="#FBCFE8"/>
  <!-- Head -->
  <ellipse cx="50" cy="44" rx="16.5" ry="18.5" fill="#FED7AA"/>
  <!-- Modern Textured Hair -->
  <path d="M31 36 C31 20 40 16 50 16 C60 16 69 20 69 36 C64 26 58 22 50 22 C42 22 36 26 31 36 Z" fill="#312E81"/>
  <!-- Hair swoop -->
  <path d="M35 25 C40 18 52 18 58 23 C50 20 42 22 35 25 Z" fill="#4338CA"/>
  <!-- Eyes -->
  <circle cx="43" cy="43" r="2.2" fill="#0F172A"/>
  <circle cx="57" cy="43" r="2.2" fill="#0F172A"/>
  <circle cx="43.8" cy="42.2" r="0.7" fill="#FFFFFF"/>
  <circle cx="57.8" cy="42.2" r="0.7" fill="#FFFFFF"/>
  <!-- Eyebrows -->
  <path d="M39 38 Q43 36 47 38" stroke="#312E81" stroke-width="1.3" stroke-linecap="round" fill="none"/>
  <path d="M53 38 Q57 36 61 38" stroke="#312E81" stroke-width="1.3" stroke-linecap="round" fill="none"/>
  <!-- Balanced Smile -->
  <path d="M45 53 Q50 56 55 53" stroke="#BE185D" stroke-width="1.5" stroke-linecap="round" fill="none"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final norm = _normalizeId(coachId);
    String svg;
    switch (norm) {
      case 'david':
        svg = _davidSvg;
        break;
      case 'elena':
        svg = _elenaSvg;
        break;
      case 'marcus':
        svg = _marcusSvg;
        break;
      case 'alex':
        svg = _alexSvg;
        break;
      case 'sarah':
      default:
        svg = _sarahSvg;
        break;
    }

    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      semanticsLabel: 'Coach $norm',
    );
  }
}
