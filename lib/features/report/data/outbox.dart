import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Where a waiting report stands (BRD FR-OFF-03).
enum OutboxStatus {
  /// Sends when the connection returns.
  waiting,

  /// A neighbor reported the same thing meanwhile; the person decides
  /// between "Me too" and sending anyway (FR-OFF-05).
  duplicate,

  /// Today's report limit is used up; tries again tomorrow.
  limitReached,

  /// Gave up after [maxSendAttempts]; the person can retry or cancel.
  failed,
}

/// Sends that fail this many times stop retrying on their own.
const maxSendAttempts = 8;

/// Wait before retry [attempt] (1-based): 30 s doubling, at most an hour.
Duration retryDelay(int attempt) => Duration(
  seconds: math.min(3600, 30 * math.pow(2, math.max(0, attempt - 1)).toInt()),
);

/// A report saved on the device until it can be sent (BRD FR-OFF-01).
@immutable
class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.draft,
    required this.photoIds,
    required this.queuedAt,
    this.routing,
    this.attempts = 0,
    this.nextAttemptAt,
    this.status = OutboxStatus.waiting,
    this.duplicateOfId,
    this.sendAnyway = false,
  });

  factory OutboxItem.fromJson(Map<String, Object?> j, String dir) {
    final draft = ReportDraft.fromJson(
      (j['draft']! as Map).cast<String, Object?>(),
    );
    return OutboxItem(
      id: j['id']! as String,
      draft: draft.copyWith(
        photoPaths: [for (final p in draft.photoPaths) '$dir/$p'],
      ),
      photoIds: (j['photoIds']! as List).cast<String>(),
      routing: (j['routing'] as Map?)?.cast<String, Object?>(),
      queuedAt: DateTime.parse(j['queuedAt']! as String),
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      nextAttemptAt: j['nextAttemptAt'] == null
          ? null
          : DateTime.parse(j['nextAttemptAt']! as String),
      status: OutboxStatus.values.byName(j['status'] as String? ?? 'waiting'),
      duplicateOfId: j['duplicateOfId'] as String?,
      sendAnyway: j['sendAnyway'] as bool? ?? false,
    );
  }

  /// Also the report's ID once sent, so a repeated send can't duplicate it.
  final String id;

  /// Photo paths point into the outbox folder.
  final ReportDraft draft;

  /// Storage IDs for each photo, fixed so an interrupted send resumes.
  final List<String> photoIds;

  /// Routing fields worked out on the device when it was queued.
  final Map<String, Object?>? routing;
  final DateTime queuedAt;
  final int attempts;
  final DateTime? nextAttemptAt;
  final OutboxStatus status;
  final String? duplicateOfId;

  /// The person chose "Send anyway" after a duplicate was found.
  final bool sendAnyway;

  bool isDue(DateTime now) =>
      status == OutboxStatus.waiting ||
      (status == OutboxStatus.limitReached &&
          !(nextAttemptAt?.isAfter(now) ?? false));

  Map<String, Object?> toJson() => {
    'id': id,
    'draft': draft
        .copyWith(
          photoPaths: [for (final p in draft.photoPaths) p.split('/').last],
        )
        .toJson(),
    'photoIds': photoIds,
    'routing': routing,
    'queuedAt': queuedAt.toIso8601String(),
    'attempts': attempts,
    'nextAttemptAt': nextAttemptAt?.toIso8601String(),
    'status': status.name,
    'duplicateOfId': duplicateOfId,
    'sendAnyway': sendAnyway,
  };

  OutboxItem copyWith({
    int? attempts,
    DateTime? nextAttemptAt,
    bool clearNextAttempt = false,
    OutboxStatus? status,
    String? duplicateOfId,
    bool? sendAnyway,
  }) => OutboxItem(
    id: id,
    draft: draft,
    photoIds: photoIds,
    routing: routing,
    queuedAt: queuedAt,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: clearNextAttempt
        ? null
        : nextAttemptAt ?? this.nextAttemptAt,
    status: status ?? this.status,
    duplicateOfId: duplicateOfId ?? this.duplicateOfId,
    sendAnyway: sendAnyway ?? this.sendAnyway,
  );
}

/// The outbox on disk: `outbox/index.json` plus a folder of photos per
/// report. A file (not SharedPreferences) so the app and the background
/// task always see the same list.
class Outbox {
  Outbox({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _baseDir;

  Future<Directory> _root() async =>
      Directory('${(await _baseDir()).path}/outbox');

  Future<File> _index() async => File('${(await _root()).path}/index.json');

  Future<List<OutboxItem>> load() async {
    final index = await _index();
    if (!index.existsSync()) return const [];
    try {
      final root = (await _root()).path;
      return [
        for (final j
            in (jsonDecode(await index.readAsString()) as List)
                .cast<Map<String, Object?>>())
          OutboxItem.fromJson(j, '$root/${j['id']}'),
      ];
    } on FormatException {
      return const [];
    }
  }

  Future<void> _write(List<OutboxItem> items) async {
    final index = await _index();
    await index.parent.create(recursive: true);
    // Write then rename, so a crash mid-write can't corrupt the list.
    final tmp = File('${index.path}.tmp');
    await tmp.writeAsString(jsonEncode([for (final i in items) i.toJson()]));
    await tmp.rename(index.path);
  }

  /// Saves [draft] with copies of its photos, ready to send later.
  Future<OutboxItem> add({
    required String id,
    required ReportDraft draft,
    required List<String> photoIds,
    Map<String, Object?>? routing,
    DateTime? now,
  }) async {
    final dir = Directory('${(await _root()).path}/$id');
    await dir.create(recursive: true);
    final photos = <String>[];
    for (final (i, p) in draft.photoPaths.indexed) {
      photos.add((await File(p).copy('${dir.path}/photo_$i.jpg')).path);
    }
    final item = OutboxItem(
      id: id,
      draft: draft.copyWith(photoPaths: photos),
      photoIds: photoIds,
      routing: routing,
      queuedAt: now ?? DateTime.now(),
    );
    await _write([...(await load()).where((i) => i.id != id), item]);
    return item;
  }

  Future<void> update(OutboxItem item) async => _write([
    for (final i in await load())
      if (i.id == item.id) item else i,
  ]);

  /// Removes the item and its photo copies.
  Future<void> remove(String id) async {
    await _write([...(await load()).where((i) => i.id != id)]);
    final dir = Directory('${(await _root()).path}/$id');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<void> clear() async {
    final root = await _root();
    if (root.existsSync()) await root.delete(recursive: true);
  }
}

/// What a send run did.
typedef OutboxRun = ({int sent, int waiting});

/// The signed-in (or guest) user sending: their ID and whether a guest.
typedef Sender = ({String uid, bool isGuest});

/// Sends due outbox items (BRD FR-OFF-02). Used by the app and by the
/// background task.
class OutboxSender {
  OutboxSender({
    required this.outbox,
    required this.repo,
    required this.sender,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Outbox outbox;
  final ReportRepository repo;

  /// Resolves the current user, starting a guest session if needed.
  final Future<Sender> Function() sender;
  final DateTime Function() _now;

  /// Sends items that are due. [force] also retries items that are backing
  /// off or gave up. Stops at the first connection failure.
  Future<OutboxRun> sendDue({bool force = false}) async {
    var sent = 0;
    for (final item in await outbox.load()) {
      final now = _now();
      final backingOff = item.nextAttemptAt?.isAfter(now) ?? false;
      final due = force
          ? item.status != OutboxStatus.duplicate
          : item.isDue(now) && !backingOff;
      if (!due) continue;
      try {
        if (await _send(item)) sent++;
      } on DailyLimitReached {
        final t = now.toUtc();
        await outbox.update(
          item.copyWith(
            status: OutboxStatus.limitReached,
            nextAttemptAt: DateTime.utc(t.year, t.month, t.day + 1),
          ),
        );
      } on Object catch (e) {
        debugPrint('Outbox: send failed ($e)');
        final attempts = item.attempts + 1;
        await outbox.update(
          item.copyWith(
            attempts: attempts,
            status: attempts >= maxSendAttempts
                ? OutboxStatus.failed
                : OutboxStatus.waiting,
            nextAttemptAt: now.add(retryDelay(attempts)),
          ),
        );
        break; // Likely offline; the rest would fail the same way.
      }
    }
    // Items waiting on the person (a duplicate, or gave up) don't keep the
    // background task retrying.
    final waiting = (await outbox.load())
        .where(
          (i) =>
              i.status == OutboxStatus.waiting ||
              i.status == OutboxStatus.limitReached,
        )
        .length;
    return (sent: sent, waiting: waiting);
  }

  /// True when the report is now on the server.
  Future<bool> _send(OutboxItem item) async {
    // An earlier attempt may have got through before the app was closed.
    if (await repo.existsOnServer(item.id)) {
      await outbox.remove(item.id);
      return true;
    }
    final me = await sender();
    if (!item.sendAnyway) {
      final dupes = await repo.nearbyDuplicates(
        item.draft.location!,
        item.draft.category!,
      );
      final other = dupes.where((r) => r.authorUid != me.uid).firstOrNull;
      if (other != null) {
        await outbox.update(
          item.copyWith(
            status: OutboxStatus.duplicate,
            duplicateOfId: other.id,
            clearNextAttempt: true,
          ),
        );
        return false;
      }
    }
    await repo.submit(
      draft: item.draft,
      uid: me.uid,
      isGuest: me.isGuest,
      routing: item.routing,
      reportId: item.id,
      photoIds: item.photoIds,
      source: 'offline_queue',
    );
    await outbox.remove(item.id);
    return true;
  }
}
