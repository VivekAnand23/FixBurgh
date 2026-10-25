import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/report/data/outbox.dart'
    show maxSendAttempts, retryDelay;
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/services/data/service_request_repository.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// A service request saved on the device until it can be posted, like the
/// city report outbox (lib/features/report/data/outbox.dart).
@immutable
class QueuedRequest {
  const QueuedRequest({
    required this.id,
    required this.draft,
    required this.posterName,
    required this.queuedAt,
    this.attempts = 0,
    this.nextAttemptAt,
  });

  factory QueuedRequest.fromJson(Map<String, Object?> j, String dir) {
    final d = (j['draft']! as Map).cast<String, Object?>();
    final loc = (d['location'] as Map?)?.cast<String, Object?>();
    return QueuedRequest(
      id: j['id']! as String,
      posterName: j['posterName'] as String? ?? '',
      queuedAt: DateTime.parse(j['queuedAt']! as String),
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      nextAttemptAt: j['nextAttemptAt'] == null
          ? null
          : DateTime.parse(j['nextAttemptAt']! as String),
      draft: (
        scope: RequestScope.values.byName(d['scope']! as String),
        societyId: d['societyId'] as String?,
        title: d['title'] as String? ?? '',
        description: d['description'] as String? ?? '',
        category: d['category'] as String? ?? '',
        group: d['group'] as String? ?? '',
        details: (d['details'] as Map? ?? const {}).cast<String, String>(),
        photos: [
          for (final p in (d['photos'] as List? ?? const []).cast<String>())
            File('$dir/$p'),
        ],
        location: loc == null
            ? null
            : GeoPoint(
                (loc['lat']! as num).toDouble(),
                (loc['lng']! as num).toDouble(),
              ),
        providerId: d['providerId'] as String?,
      ),
    );
  }

  /// Also the request's id once posted, so a repeat can't duplicate it.
  final String id;

  /// Photo files point into the outbox folder.
  final RequestDraft draft;
  final String posterName;
  final DateTime queuedAt;
  final int attempts;
  final DateTime? nextAttemptAt;

  bool get failed => attempts >= maxSendAttempts;

  Map<String, Object?> toJson() => {
    'id': id,
    'posterName': posterName,
    'queuedAt': queuedAt.toIso8601String(),
    'attempts': attempts,
    'nextAttemptAt': nextAttemptAt?.toIso8601String(),
    'draft': {
      'scope': draft.scope.name,
      'societyId': draft.societyId,
      'title': draft.title,
      'description': draft.description,
      'category': draft.category,
      'group': draft.group,
      'details': draft.details,
      'photos': [for (final f in draft.photos) f.path.split('/').last],
      'location': draft.location == null
          ? null
          : {'lat': draft.location!.lat, 'lng': draft.location!.lng},
      'providerId': draft.providerId,
    },
  };

  QueuedRequest retried(DateTime now) => QueuedRequest(
    id: id,
    draft: draft,
    posterName: posterName,
    queuedAt: queuedAt,
    attempts: attempts + 1,
    nextAttemptAt: now.add(retryDelay(attempts + 1)),
  );
}

/// The request outbox on disk: `service_outbox/index.json` plus a folder of
/// photo copies per request.
class RequestOutbox {
  RequestOutbox({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _baseDir;

  Future<Directory> _root() async =>
      Directory('${(await _baseDir()).path}/service_outbox');

  Future<File> _index() async => File('${(await _root()).path}/index.json');

  Future<List<QueuedRequest>> load() async {
    final index = await _index();
    if (!index.existsSync()) return const [];
    try {
      final root = (await _root()).path;
      return [
        for (final j
            in (jsonDecode(await index.readAsString()) as List)
                .cast<Map<String, Object?>>())
          QueuedRequest.fromJson(j, '$root/${j['id']}'),
      ];
    } on FormatException {
      return const [];
    }
  }

  Future<void> _write(List<QueuedRequest> items) async {
    final index = await _index();
    await index.parent.create(recursive: true);
    final tmp = File('${index.path}.tmp');
    await tmp.writeAsString(jsonEncode([for (final i in items) i.toJson()]));
    await tmp.rename(index.path);
  }

  /// Saves [draft] with copies of its photos.
  Future<QueuedRequest> add(
    String id,
    RequestDraft draft, {
    required String posterName,
    DateTime? now,
  }) async {
    final dir = Directory('${(await _root()).path}/$id');
    await dir.create(recursive: true);
    final photos = [
      for (final (i, f) in draft.photos.indexed)
        await f.copy('${dir.path}/photo_$i.jpg'),
    ];
    final item = QueuedRequest(
      id: id,
      draft: (
        scope: draft.scope,
        societyId: draft.societyId,
        title: draft.title,
        description: draft.description,
        category: draft.category,
        group: draft.group,
        details: draft.details,
        photos: photos,
        location: draft.location,
        providerId: draft.providerId,
      ),
      posterName: posterName,
      queuedAt: now ?? DateTime.now(),
    );
    await _write([...(await load()).where((i) => i.id != id), item]);
    return item;
  }

  Future<void> update(QueuedRequest item) async => _write([
    for (final i in await load())
      if (i.id == item.id) item else i,
  ]);

  Future<void> remove(String id) async {
    await _write([...(await load()).where((i) => i.id != id)]);
    final dir = Directory('${(await _root()).path}/$id');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

final requestOutboxStoreProvider = Provider<RequestOutbox>(
  (ref) => RequestOutbox(),
);

/// Requests waiting on this device, shown at the top of Service requests.
final requestOutboxProvider =
    NotifierProvider<RequestOutboxController, List<QueuedRequest>>(
      RequestOutboxController.new,
    );

class RequestOutboxController extends Notifier<List<QueuedRequest>> {
  bool _sending = false;

  RequestOutbox get _store => ref.read(requestOutboxStoreProvider);

  @override
  List<QueuedRequest> build() {
    unawaited(refresh());
    return const [];
  }

  Future<void> refresh() async {
    final items = await _store.load();
    if (ref.mounted) state = items;
  }

  Future<void> enqueue(
    String id,
    RequestDraft draft, {
    required String posterName,
  }) async {
    await _store.add(id, draft, posterName: posterName);
    await refresh();
  }

  /// Posts what's due. [force] also retries ones that gave up. Stops at the
  /// first failure, which most likely means still offline.
  Future<int> sendNow({bool force = false, DateTime? now}) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (_sending || uid == null) return 0;
    _sending = true;
    final repo = ref.read(serviceRequestRepositoryProvider);
    var sent = 0;
    try {
      for (final item in await _store.load()) {
        final t = now ?? DateTime.now();
        final due =
            force ||
            (!item.failed && !(item.nextAttemptAt?.isAfter(t) ?? false));
        if (!due) continue;
        try {
          if (!await repo.existsOnServer(item.id)) {
            await repo.post(
              item.draft,
              uid: uid,
              posterName: item.posterName,
              id: item.id,
            );
          }
          await _store.remove(item.id);
          sent++;
        } on Object catch (e) {
          debugPrint('Request outbox: send failed ($e)');
          await _store.update(item.retried(t));
          break;
        }
      }
      return sent;
    } finally {
      _sending = false;
      await refresh();
    }
  }

  Future<void> cancel(String id) async {
    await _store.remove(id);
    await refresh();
  }
}
