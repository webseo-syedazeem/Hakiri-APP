/// Utility to ensure consistent British / UK English spelling across all UI text.
class _Replacement {
  final RegExp pattern;
  final String Function(Match) replace;
  const _Replacement(this.pattern, this.replace);
}

final List<_Replacement> _ukEnglishPatterns = [
  // -ize / -ization -> -ise / -isation
  _Replacement(
    RegExp(r'\b([Ss])ynchroniz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}ynchronis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Oo])rganiz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}rganis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Pp])rioritiz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}rioritis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Aa])nalyz(e|es|ed|ing)\b'),
    (m) => '${m[1]}nalys${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Pp])ersonaliz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}ersonalis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Cc])ustomiz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}ustomis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Ss])ummariz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}ummaris${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Oo])ptimiz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}ptimis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Rr])ealiz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}ealis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Rr])ecogniz(e|es|ed|ing|able)\b'),
    (m) => '${m[1]}ecognis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Ss])pecializ(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}pecialis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Uu])tiliz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}tilis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Cc])ategoriz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}ategoris${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Cc])entraliz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}entralis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Ss])tandardiz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}tandardis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Vv])isualiz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}isualis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Ee])mphasiz(e|es|ed|ing)\b'),
    (m) => '${m[1]}mphasis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Mm])aximiz(e|es|ed|ing)\b'),
    (m) => '${m[1]}ximis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Mm])inimiz(e|es|ed|ing)\b'),
    (m) => '${m[1]}nimis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Ff])amiliariz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}amiliaris${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Cc])haracteriz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}haracteris${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Cc])apitaliz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}apitalis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Hh])armoniz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}armonis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Ff])ormaliz(e|es|ed|ing|ation|ations)\b'),
    (m) => '${m[1]}ormalis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Cc])riticiz(e|es|ed|ing)\b'),
    (m) => '${m[1]}riticis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Mm])emoriz(e|es|ed|ing)\b'),
    (m) => '${m[1]}emoris${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Aa])pologiz(e|es|ed|ing)\b'),
    (m) => '${m[1]}pologis${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Pp])enaliz(e|es|ed|ing)\b'),
    (m) => '${m[1]}enalis${m[2]}',
  ),

  // -or -> -our
  _Replacement(
    RegExp(r'\b([Bb])ehavior(s)?\b'),
    (m) => '${m[1]}ehaviour${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Cc])olor(s)?\b'),
    (m) => '${m[1]}olour${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Ff])avor(s|ed|ing|ite|ites)?\b'),
    (m) => '${m[1]}avour${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Hh])onor(s|ed|ing|able)?\b'),
    (m) => '${m[1]}onour${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Ff])lavor(s|ed|ing)?\b'),
    (m) => '${m[1]}lavour${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Nn])eighbor(s|hood|hoods)?\b'),
    (m) => '${m[1]}eighbour${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Ll])abor(s|ed|ing|er|ers)?\b'),
    (m) => '${m[1]}abour${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Hh])umor(s)?\b'),
    (m) => '${m[1]}umour${m[2] ?? ''}',
  ),

  // Other UK English spellings
  _Replacement(
    RegExp(r'\b([Cc])enter(s|ed|ing)?\b'),
    (m) => '${m[1]}entre${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Tt])heater(s)?\b'),
    (m) => '${m[1]}heatre${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Cc])atalog(s)?\b'),
    (m) => '${m[1]}atalogue${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Aa])nalog(s)?\b'),
    (m) => '${m[1]}nalogue${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Dd])ialog(s)?\b'),
    (m) => '${m[1]}ialogue${m[2] ?? ''}',
  ),
  _Replacement(
    RegExp(r'\b([Tt])ravel(ed|ing|er|ers)\b'),
    (m) => '${m[1]}ravell${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Cc])ancel(ed|ing)\b'),
    (m) => '${m[1]}ancell${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Ss])ignal(ed|ing)\b'),
    (m) => '${m[1]}ignall${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Mm])odel(ed|ing)\b'),
    (m) => '${m[1]}odell${m[2]}',
  ),
  _Replacement(
    RegExp(r'\b([Dd])efense\b'),
    (m) => '${m[1]}efence',
  ),
  _Replacement(
    RegExp(r'\b([Oo])ffense\b'),
    (m) => '${m[1]}ffence',
  ),
  _Replacement(
    RegExp(r'\b([Pp])racticing\b'),
    (m) => '${m[1]}ractising',
  ),
  _Replacement(
    RegExp(r'\b([Pp])rogram(s)?\b'),
    (m) => '${m[1]}rogramme${m[2] ?? ''}',
  ),
];

/// Converts text with American English spellings into UK / British English.
String toUkEnglish(String text) {
  if (text.isEmpty) return text;
  var out = text;
  for (final entry in _ukEnglishPatterns) {
    out = out.replaceAllMapped(entry.pattern, entry.replace);
  }
  return out;
}
