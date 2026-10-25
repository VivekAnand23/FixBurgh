import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fixburgh/app/analytics.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/moderation/text_filter.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/channel.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final channelRepositoryProvider = Provider<ChannelRepository>(
  (ref) => ChannelRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    analytics: ref.watch(analyticsProvider),
  ),
);

/// A society's open channels, General first.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final channelsProvider = StreamProvider.autoDispose
    .family<List<Channel>, String>(
      (ref, sid) => ref.watch(channelRepositoryProvider).watchChannels(sid),
    );

typedef ChannelKey = ({String sid, String cid});

// ignore: specify_nonobvious_property_types, family type isn't exported.
final channelProvider = StreamProvider.autoDispose.family<Channel?, ChannelKey>(
  (ref, k) => ref.watch(channelRepositoryProvider).watchChannel(k.sid, k.cid),
);

// ignore: specify_nonobvious_property_types, family type isn't exported.
final postsProvider = StreamProvider.autoDispose.family<List<Post>, ChannelKey>(
  (ref, k) => ref.watch(channelRepositoryProvider).watchPosts(k.sid, k.cid),
);

typedef PostKey = ({String sid, String cid, String pid});

// ignore: specify_nonobvious_property_types, family type isn't exported.
final postProvider = StreamProvider.autoDispose.family<Post?, PostKey>(
  (ref, k) =>
      ref.watch(channelRepositoryProvider).watchPost(k.sid, k.cid, k.pid),
);

// ignore: specify_nonobvious_property_types, family type isn't exported.
final commentsProvider = StreamProvider.autoDispose
    .family<List<Comment>, PostKey>(
      (ref, k) => ref
          .watch(channelRepositoryProvider)
          .watchComments(k.sid, k.cid, k.pid),
    );

/// The signed-in member's reaction on a post or comment (its path).
// ignore: specify_nonobvious_property_types, family type isn't exported.
final myReactionProvider = StreamProvider.autoDispose.family<String?, String>((
  ref,
  path,
) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(channelRepositoryProvider).watchReaction(path, uid);
});

/// New posts in a channel since the member last opened it, and how many
/// of them @mention them.
typedef Unread = ({int posts, int mentions});

typedef UnreadKey = ({String sid, String cid, DateTime? since, String uid});

// ignore: specify_nonobvious_property_types, family type isn't exported.
final unreadProvider = FutureProvider.autoDispose.family<Unread, UnreadKey>(
  (ref, k) => ref.watch(channelRepositoryProvider).unread(k),
);

/// Unread posts across a society's channels, for the Society tab badge.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final societyUnreadProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  sid,
) async {
  final me = ref.watch(myMembershipProvider(sid)).value;
  final channels = ref.watch(channelsProvider(sid)).value ?? const [];
  if (me == null || !me.isApproved) return 0;
  final now = DateTime.now();
  var total = 0;
  for (final c in channels) {
    if (me.isMuted(c.id, now)) continue;
    // Re-runs when the channel's last post changes.
    final u = await ref.watch(
      unreadProvider((
        sid: sid,
        cid: c.id,
        since: me.lastRead[c.id] ?? _neverRead(c),
        uid: me.uid,
      )).future,
    );
    total += u.posts;
  }
  return total;
});

/// Before a member first opens a channel, only the last day counts as new.
DateTime? _neverRead(Channel c) =>
    c.lastPostAt?.subtract(const Duration(days: 1));

/// Channels, posts, comments and reactions under `societies/{sid}`.
/// Counts and pushes are handled by Cloud Functions (functions/src/channels.ts).
class ChannelRepository {
  ChannelRepository(
    this._db,
    this._storage, {
    Analytics analytics = const NoAnalytics(),
  }) : _analytics = analytics;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final Analytics _analytics;

  CollectionReference<Map<String, dynamic>> _channels(String sid) =>
      _db.collection('societies').doc(sid).collection('channels');

  CollectionReference<Map<String, dynamic>> _posts(String sid, String cid) =>
      _channels(sid).doc(cid).collection('posts');

  Stream<List<Channel>> watchChannels(String sid) => _channels(sid)
      .where('archived', isEqualTo: false)
      .snapshots()
      .map(
        (s) => sortChannels([
          for (final d in s.docs) Channel.fromDoc(d.id, plain(d.data())),
        ]),
      );

  Stream<Channel?> watchChannel(String sid, String cid) => _channels(sid)
      .doc(cid)
      .snapshots()
      .map(
        (d) => d.exists ? Channel.fromDoc(d.id, plain(d.data()!)) : null,
      );

  /// The latest 100 posts, newest first.
  Stream<List<Post>> watchPosts(String sid, String cid) => _posts(sid, cid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) Post.fromDoc(d.id, plain(d.data()))],
      );

  Stream<Post?> watchPost(String sid, String cid, String pid) =>
      _posts(sid, cid)
          .doc(pid)
          .snapshots()
          .map(
            (d) => d.exists ? Post.fromDoc(d.id, plain(d.data()!)) : null,
          );

  Stream<List<Comment>> watchComments(String sid, String cid, String pid) =>
      _posts(sid, cid)
          .doc(pid)
          .collection('comments')
          .orderBy('createdAt')
          .limit(300)
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs) Comment.fromDoc(d.id, plain(d.data())),
            ],
          );

  Stream<String?> watchReaction(String path, String uid) => _db
      .doc('$path/reactions/$uid')
      .snapshots()
      .map((d) => d.data()?['emoji'] as String?);

  Future<Unread> unread(UnreadKey k) async {
    final since = k.since;
    Query<Map<String, dynamic>> q = _posts(k.sid, k.cid);
    if (since != null) {
      q = q.where('createdAt', isGreaterThan: Timestamp.fromDate(since));
    }
    final mentions = _posts(k.sid, k.cid)
        .where('mentions', arrayContains: k.uid)
        .where(
          'createdAt',
          isGreaterThan: Timestamp.fromDate(since ?? DateTime(2000)),
        );
    final counts = await Future.wait([
      q.count().get(),
      mentions.count().get(),
    ]);
    return (posts: counts[0].count ?? 0, mentions: counts[1].count ?? 0);
  }

  Future<void> createChannel(String sid, String uid, String name) =>
      _channels(sid).doc().set({
        'name': name.trim(),
        'createdBy': uid,
        'archived': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateChannel(
    String sid,
    String cid, {
    String? name,
    bool? archived,
  }) => _channels(sid).doc(cid).update({
    'name': ?name?.trim(),
    'archived': ?archived,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Uploads [photos] (compressed, without location data), then the post.
  Future<void> createPost(
    String sid,
    String cid, {
    required String uid,
    required String authorName,
    required String authorUnit,
    required String text,
    required List<String> mentions,
    List<File> photos = const [],
  }) async {
    final ref = _posts(sid, cid).doc();
    final uploaded = <Map<String, String>>[];
    for (final f in photos.take(maxPostPhotos)) {
      final id = const Uuid().v4();
      final base = 'societies/$sid/posts/${ref.id}/$id';
      final meta = SettableMetadata(contentType: 'image/jpeg');
      final full = _storage.ref('$base.jpg');
      final thumb = _storage.ref('${base}_thumb.jpg');
      await full.putData(await _compress(f, 1600, 80), meta);
      await thumb.putData(await _compress(f, 480, 70), meta);
      uploaded.add({
        'path': full.fullPath,
        'thumbPath': thumb.fullPath,
        'thumbUrl': await thumb.getDownloadURL(),
      });
    }
    await ref.set({
      'authorUid': uid,
      'authorName': _take(authorName, 60),
      'authorUnit': _take(authorUnit, 20),
      'text': cleanUserText(text.trim()),
      'photos': uploaded,
      'mentions': mentions.take(20).toList(),
      'pinned': false,
      'reactionCounts': <String, int>{},
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _analytics.channelPost(photos: uploaded.length);
  }

  Future<void> deletePost(String sid, String cid, String pid) =>
      _posts(sid, cid).doc(pid).delete();

  Future<void> setPinned(
    String sid,
    String cid,
    String pid, {
    required bool pinned,
  }) => _posts(sid, cid).doc(pid).update({'pinned': pinned});

  Future<void> addComment(
    String sid,
    String cid,
    String pid, {
    required String uid,
    required String authorName,
    required String text,
    required List<String> mentions,
    String? replyTo,
  }) async {
    await _posts(sid, cid).doc(pid).collection('comments').doc().set({
      'authorUid': uid,
      'authorName': _take(authorName, 60),
      'text': cleanUserText(text.trim()),
      'replyTo': replyTo,
      'mentions': mentions.take(20).toList(),
      'reactionCounts': <String, int>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _analytics.channelComment(reply: replyTo != null);
  }

  Future<void> deleteComment(String sid, String cid, String pid, String id) =>
      _posts(sid, cid).doc(pid).collection('comments').doc(id).delete();

  /// Sets the member's reaction on the post or comment at [path]; the same
  /// emoji again removes it.
  Future<void> toggleReaction(
    String path,
    String uid,
    String emoji, {
    String? current,
  }) async {
    final ref = _db.doc('$path/reactions/$uid');
    if (current == emoji) return ref.delete();
    await ref.set({'emoji': emoji, 'createdAt': FieldValue.serverTimestamp()});
    await _analytics.channelReaction();
  }

  /// Clears the channel's unread badge for this member.
  Future<void> markRead(String sid, String cid, String uid) => _db
      .collection('societies')
      .doc(sid)
      .collection('members')
      .doc(uid)
      .update({'lastRead.$cid': FieldValue.serverTimestamp()});

  Future<void> setMute(String sid, String cid, String uid, Mute? mute) => _db
      .collection('societies')
      .doc(sid)
      .collection('members')
      .doc(uid)
      .update({
        'mutes.$cid': mute == null
            ? FieldValue.delete()
            : mute.always
            ? 'always'
            : Timestamp.fromDate(mute.until!),
      });

  /// Reports a post or comment to the society's admins and committee.
  Future<void> report(
    String sid, {
    required String cid,
    required String pid,
    required String uid,
    required String reason,
    String commentId = '',
  }) => _db
      .collection('societies')
      .doc(sid)
      .collection('flags')
      .doc('${pid}_${commentId}_$uid')
      .set({
        'channelId': cid,
        'postId': pid,
        'commentId': commentId,
        'reporterUid': uid,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Resizes to [size] px on the long edge and re-encodes as JPEG, which
  /// drops EXIF metadata (GPS, device).
  static Future<Uint8List> _compress(File f, int size, int quality) async =>
      await FlutterImageCompress.compressWithFile(
        f.path,
        minWidth: size,
        minHeight: size,
        quality: quality,
      ) ??
      await f.readAsBytes();
}

/// Path of a post, for reactions.
String postPath(String sid, String cid, String pid) =>
    'societies/$sid/channels/$cid/posts/$pid';

String _take(String s, int n) => s.length <= n ? s : s.substring(0, n);
