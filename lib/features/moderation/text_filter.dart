/// Cleans user text before it is stored or shown (BRD FR-MOD-04): masks
/// email addresses and phone numbers so people don't post private details,
/// and masks a short list of common profanity.
String cleanUserText(String input) {
  var out = input.replaceAllMapped(_email, (_) => '[email removed]');
  out = out.replaceAllMapped(_phone, (_) => '[phone removed]');
  return out.replaceAllMapped(
    _profanity,
    (m) => m[0]![0] + '*' * (m[0]!.length - 1),
  );
}

final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');

/// US numbers like 412-555-1234, (412) 555 1234, +1 412.555.1234.
final _phone = RegExp(
  r'(?:\+?1[\s.-]?)?\(?\b\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b',
);

/// Kept deliberately short; moderation flags catch the rest.
final _profanity = RegExp(
  r'\b(fuck\w*|shit\w*|bitch\w*|asshole\w*|bastard\w*|dick(?:head)?s?|cunt\w*|'
  r'motherfuck\w*|piss(?:ed|ing)?|crap)\b',
  caseSensitive: false,
);
