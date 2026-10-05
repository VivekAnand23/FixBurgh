import 'package:fixburgh/app/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// People whose reports this user chose to hide (App Store guideline 1.2).
/// Stored on the device; reports stay public for everyone else.
final blockedUsersProvider =
    NotifierProvider<BlockedUsersController, Set<String>>(
      BlockedUsersController.new,
    );

class BlockedUsersController extends Notifier<Set<String>> {
  static const _key = 'moderation.blockedUids';

  @override
  Set<String> build() =>
      (ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [])
          .toSet();

  Future<void> block(String uid) => _save({...state, uid});

  Future<void> unblockAll() => _save({});

  Future<void> _save(Set<String> next) async {
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(_key, [...next]);
  }
}
