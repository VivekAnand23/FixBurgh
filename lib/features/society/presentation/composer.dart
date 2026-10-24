import 'dart:io';

import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/channel.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/pickers.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// What the composer sends: text, the members still @mentioned in it, and
/// any photos.
typedef Composed = ({String text, List<String> mentions, List<File> photos});

/// Message box for posts and comments, with an @ member picker that pops
/// up while typing a mention, and optional photos.
class Composer extends ConsumerStatefulWidget {
  const Composer({
    required this.societyId,
    required this.hint,
    required this.onSend,
    this.allowPhotos = false,
    this.replyingTo,
    this.onCancelReply,
    super.key,
  });

  final String societyId;
  final String hint;
  final Future<void> Function(Composed) onSend;
  final bool allowPhotos;

  /// Shown above the box while replying, e.g. "Replying to Ann".
  final String? replyingTo;
  final VoidCallback? onCancelReply;

  @override
  ConsumerState<Composer> createState() => ComposerState();
}

class ComposerState extends ConsumerState<Composer> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _picked = <String, String>{};
  final _photos = <File>[];
  String? _query;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onChanged);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void focus() => _focus.requestFocus();

  void _onChanged() {
    final q = mentionQuery(_text.text, _text.selection.baseOffset);
    if (q != _query) setState(() => _query = q);
  }

  void _pick(Membership m) {
    final name = m.displayName;
    final sel = _text.selection.baseOffset;
    final before = _text.text.substring(0, sel);
    final at = before.lastIndexOf('@');
    final next =
        '${before.substring(0, at)}@$name ${_text.text.substring(sel)}';
    _picked[name] = m.uid;
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: at + name.length + 2),
    );
  }

  Future<void> _addPhoto() async {
    final f = await ref.read(pickImageProvider)(ImageSource.gallery);
    if (f != null && mounted) setState(() => _photos.add(f));
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if ((text.isEmpty && _photos.isEmpty) || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend((
        text: text,
        mentions: mentionedUids(text, _picked),
        photos: [..._photos],
      ));
      _text.clear();
      _picked.clear();
      setState(_photos.clear);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final q = _query?.toLowerCase();
    final members = q == null
        ? const <Membership>[]
        : (ref.watch(membersProvider(widget.societyId)).value ?? const [])
              .where(
                (m) =>
                    m.isApproved &&
                    m.displayName.isNotEmpty &&
                    m.displayName.toLowerCase().contains(q),
              )
              .take(5)
              .toList();
    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (members.isNotEmpty)
              Material(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Column(
                  children: [
                    for (final m in members)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text(m.displayName[0].toUpperCase()),
                        ),
                        title: Text(m.displayName),
                        subtitle: m.unit.isEmpty
                            ? null
                            : Text(l10n.unitLabel(m.unit)),
                        onTap: () => _pick(m),
                      ),
                  ],
                ),
              ),
            if (widget.replyingTo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.replyingTo!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.cancel,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: widget.onCancelReply,
                    ),
                  ],
                ),
              ),
            if (_photos.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  children: [
                    for (final (i, p) in _photos.indexed)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                p,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _photos.removeAt(i)),
                                child: const CircleAvatar(
                                  radius: 10,
                                  child: Icon(Icons.close, size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.allowPhotos)
                    IconButton(
                      tooltip: l10n.addPhoto,
                      icon: const Icon(Icons.photo_outlined),
                      onPressed: _photos.length >= maxPostPhotos
                          ? null
                          : _addPhoto,
                    ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: widget.allowPhotos ? 2000 : 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        counterText: '',
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text with @mentions of society members highlighted in a navy-tint pill.
class MentionText extends StatelessWidget {
  const MentionText({
    required this.text,
    required this.names,
    this.style,
    super.key,
  });

  final String text;

  /// Display names of the members mentioned.
  final Iterable<String> names;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final base = style ?? theme.textTheme.bodyLarge;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (final (part, mention) in splitMentions(text, names))
            if (mention)
              TextSpan(
                text: part,
                style: base?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dark ? theme.colorScheme.primary : AppColors.navy,
                  backgroundColor: dark
                      ? theme.colorScheme.primaryContainer
                      : AppColors.navyTint,
                ),
              )
            else
              TextSpan(text: part),
        ],
      ),
    );
  }
}
