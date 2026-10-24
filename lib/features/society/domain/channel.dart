import 'package:flutter/foundation.dart';

/// The reactions members can add, as the rules allow.
const reactionEmoji = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Most photos on one post, as the rules allow.
const maxPostPhotos = 6;

/// A society channel, e.g. General or Block B.
@immutable
class Channel {
  const Channel({
    required this.id,
    required this.name,
    this.archived = false,
    this.postCount = 0,
    this.lastPostAt,
    this.lastPostText = '',
    this.lastPostAuthor = '',
  });

  factory Channel.fromDoc(String id, Map<String, dynamic> d) => Channel(
    id: id,
    name: d['name'] as String? ?? id,
    archived: d['archived'] as bool? ?? false,
    postCount: (d['postCount'] as num?)?.toInt() ?? 0,
    lastPostAt: d['lastPostAt'] as DateTime?,
    lastPostText: d['lastPostText'] as String? ?? '',
    lastPostAuthor: d['lastPostAuthor'] as String? ?? '',
  );

  final String id;
  final String name;
  final bool archived;
  final int postCount;
  final DateTime? lastPostAt;
  final String lastPostText;
  final String lastPostAuthor;

  bool get isGeneral => id == 'general';
}

/// General first, then the most recently active.
List<Channel> sortChannels(List<Channel> channels) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  return [...channels]..sort((a, b) {
    if (a.isGeneral != b.isGeneral) return a.isGeneral ? -1 : 1;
    return (b.lastPostAt ?? epoch).compareTo(a.lastPostAt ?? epoch);
  });
}

typedef PostPhoto = ({String path, String thumbPath, String thumbUrl});

/// A post in a channel.
@immutable
class Post {
  const Post({
    required this.id,
    required this.authorUid,
    required this.text,
    this.authorName = '',
    this.authorUnit = '',
    this.photos = const [],
    this.mentions = const [],
    this.pinned = false,
    this.reactionCounts = const {},
    this.commentCount = 0,
    this.createdAt,
    this.edited = false,
  });

  factory Post.fromDoc(String id, Map<String, dynamic> d) => Post(
    id: id,
    authorUid: d['authorUid'] as String? ?? '',
    authorName: d['authorName'] as String? ?? '',
    authorUnit: d['authorUnit'] as String? ?? '',
    text: d['text'] as String? ?? '',
    photos: [
      for (final p
          in (d['photos'] as List? ?? const [])
              .whereType<Map<Object?, Object?>>())
        (
          path: p['path'] as String? ?? '',
          thumbPath: p['thumbPath'] as String? ?? '',
          thumbUrl: p['thumbUrl'] as String? ?? '',
        ),
    ],
    mentions: [...(d['mentions'] as List? ?? const []).whereType<String>()],
    pinned: d['pinned'] as bool? ?? false,
    reactionCounts: _counts(d['reactionCounts']),
    commentCount: (d['commentCount'] as num?)?.toInt() ?? 0,
    createdAt: d['createdAt'] as DateTime?,
    edited: d['editedAt'] != null,
  );

  final String id;
  final String authorUid;
  final String authorName;
  final String authorUnit;
  final String text;
  final List<PostPhoto> photos;
  final List<String> mentions;
  final bool pinned;
  final Map<String, int> reactionCounts;
  final int commentCount;

  /// Null while the server timestamp is pending.
  final DateTime? createdAt;
  final bool edited;
}

/// A comment, or a reply to one ([replyTo] is the parent's id).
@immutable
class Comment {
  const Comment({
    required this.id,
    required this.authorUid,
    required this.text,
    this.authorName = '',
    this.replyTo,
    this.mentions = const [],
    this.reactionCounts = const {},
    this.createdAt,
  });

  factory Comment.fromDoc(String id, Map<String, dynamic> d) => Comment(
    id: id,
    authorUid: d['authorUid'] as String? ?? '',
    authorName: d['authorName'] as String? ?? '',
    text: d['text'] as String? ?? '',
    replyTo: d['replyTo'] as String?,
    mentions: [...(d['mentions'] as List? ?? const []).whereType<String>()],
    reactionCounts: _counts(d['reactionCounts']),
    createdAt: d['createdAt'] as DateTime?,
  );

  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final String? replyTo;
  final List<String> mentions;
  final Map<String, int> reactionCounts;
  final DateTime? createdAt;
}

/// Comments in order, each followed by its replies (one level deep, as in
/// WhatsApp). Replies to a reply attach to the top-level comment.
List<(Comment comment, bool isReply)> threadComments(List<Comment> comments) {
  final byId = {for (final c in comments) c.id: c};
  String root(Comment c) {
    var cur = c;
    final seen = <String>{};
    while (cur.replyTo != null &&
        byId.containsKey(cur.replyTo) &&
        seen.add(cur.id)) {
      cur = byId[cur.replyTo]!;
    }
    return cur.id;
  }

  int byTime(Comment a, Comment b) =>
      (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
  final tops = comments.where((c) => root(c) == c.id).toList()..sort(byTime);
  final replies = <String, List<Comment>>{};
  for (final c in comments) {
    final r = root(c);
    if (r != c.id) (replies[r] ??= []).add(c);
  }
  return [
    for (final t in tops) ...[
      (t, false),
      for (final r in (replies[t.id] ?? const <Comment>[])..sort(byTime))
        (r, true),
    ],
  ];
}

/// A channel mute: until a time, or always.
@immutable
class Mute {
  const Mute.until(DateTime this.until) : always = false;
  const Mute.always() : until = null, always = true;

  final DateTime? until;
  final bool always;

  bool isActive(DateTime now) => always || (until?.isAfter(now) ?? false);

  static Mute? parse(Object? v) => switch (v) {
    'always' => const Mute.always(),
    final DateTime d => Mute.until(d),
    _ => null,
  };
}

/// How long to mute for, from the channel menu.
enum MuteLength { eightHours, oneWeek, always }

Mute muteFor(MuteLength length, DateTime now) => switch (length) {
  MuteLength.eightHours => Mute.until(now.add(const Duration(hours: 8))),
  MuteLength.oneWeek => Mute.until(now.add(const Duration(days: 7))),
  MuteLength.always => const Mute.always(),
};

/// Splits [text] into plain runs and @mentions of [names] (longest first,
/// so "@Ann Lee" wins over "@Ann"). True marks a mention.
List<(String, bool)> splitMentions(String text, Iterable<String> names) {
  final sorted = names.where((n) => n.isNotEmpty).toSet().toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  if (sorted.isEmpty) return [(text, false)];
  final pattern = RegExp(
    '@(${sorted.map(RegExp.escape).join('|')})',
    caseSensitive: false,
  );
  final out = <(String, bool)>[];
  var last = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > last) out.add((text.substring(last, m.start), false));
    out.add((m.group(0)!, true));
    last = m.end;
  }
  if (last < text.length) out.add((text.substring(last), false));
  return out;
}

/// The members still @mentioned in [text], from those picked while
/// writing it ([picked] maps display name to uid).
List<String> mentionedUids(String text, Map<String, String> picked) => [
  for (final MapEntry(key: name, value: uid) in picked.entries)
    if (text.toLowerCase().contains('@${name.toLowerCase()}')) uid,
];

/// The text after an unfinished "@" at [cursor], for the member picker;
/// null when the cursor isn't in a mention.
String? mentionQuery(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;
  final before = text.substring(0, cursor);
  final at = before.lastIndexOf('@');
  if (at < 0) return null;
  if (at > 0 && !RegExp(r'\s').hasMatch(before[at - 1])) return null;
  final q = before.substring(at + 1);
  if (q.contains('\n') || q.length > 30) return null;
  return q;
}

Map<String, int> _counts(Object? v) => {
  if (v is Map<Object?, Object?>)
    for (final MapEntry(:key, :value) in v.entries)
      if (key is String && value is num && value > 0) key: value.toInt(),
};
