import 'package:fixburgh/features/society/data/channel_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Notification settings > Muted channels, across the person's societies,
/// with Edit to unmute.
class MutedChannelsList extends ConsumerStatefulWidget {
  const MutedChannelsList({super.key});

  @override
  ConsumerState<MutedChannelsList> createState() => _MutedChannelsListState();
}

class _MutedChannelsListState extends ConsumerState<MutedChannelsList> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final rows = <Widget>[];
    for (final sid
        in ref.watch(mySocietyIdsProvider).value ?? const <String>[]) {
      final me = ref.watch(myMembershipProvider(sid)).value;
      final society = ref.watch(societyProvider(sid)).value;
      final channels = ref.watch(channelsProvider(sid)).value ?? const [];
      if (me == null) continue;
      for (final c in channels) {
        final mute = me.mutes[c.id];
        if (mute == null || !mute.isActive(now)) continue;
        rows.add(
          ListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: 72,
              end: 16,
            ),
            title: Text('# ${c.name}'),
            subtitle: Text(
              [
                if (society != null) society.name,
                if (mute.always)
                  l10n.mutedAlways
                else
                  l10n.mutedUntil(
                    DateFormat.MMMd().add_jm().format(mute.until!),
                  ),
              ].join(' · '),
            ),
            trailing: _editing
                ? TextButton(
                    onPressed: () => ref
                        .read(channelRepositoryProvider)
                        .setMute(sid, c.id, me.uid, null),
                    child: Text(l10n.unmute),
                  )
                : const Icon(Icons.notifications_off_outlined),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.notifications_off_outlined),
          title: Text(l10n.mutedChannels),
          subtitle: rows.isEmpty
              ? Text(l10n.noMutedChannels)
              : Text(l10n.mutedChannelsBody),
          trailing: rows.isEmpty
              ? null
              : TextButton(
                  onPressed: () => setState(() => _editing = !_editing),
                  child: Text(_editing ? l10n.done : l10n.edit),
                ),
        ),
        ...rows,
        if (rows.isNotEmpty) Divider(color: theme.dividerColor),
      ],
    );
  }
}
