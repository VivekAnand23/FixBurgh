import 'dart:io';

import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/pickers.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// A notice, with its attachment. Opened from the list or a push.
class NoticeScreen extends ConsumerWidget {
  const NoticeScreen({
    required this.societyId,
    required this.noticeId,
    super.key,
  });

  final String societyId;
  final String noticeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notices = ref.watch(noticesProvider(societyId));
    final me = ref.watch(myMembershipProvider(societyId)).value;
    final society = ref.watch(societyProvider(societyId)).value;
    final notice = notices.value?.where((n) => n.id == noticeId).firstOrNull;
    final canDelete =
        notice != null &&
        me != null &&
        (me.isAdmin || (me.canPostNotices && notice.authorUid == me.uid));
    return Scaffold(
      appBar: AppBar(
        title: Text(society?.name ?? l10n.tabNotices),
        actions: [
          if (canDelete)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final router = GoRouter.of(context);
                await ref
                    .read(societyRepositoryProvider)
                    .deleteNotice(societyId, notice);
                router.pop();
              },
            ),
        ],
      ),
      body: notice == null
          ? Center(
              child: notices.isLoading
                  ? const CircularProgressIndicator()
                  : Text(l10n.noticeGone),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (notice.pinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.pinnedNotice.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  notice.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (notice.authorName.isNotEmpty) notice.authorName,
                    noticeMeta(context, notice),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SelectableText(notice.body, style: theme.textTheme.bodyLarge),
                if (notice.attachment case final a?) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: Icon(
                      a.contentType == 'application/pdf'
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                    ),
                    label: Text(a.name),
                    onPressed: () => openSocietyFile(context, ref, a.path),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Write a notice for every member; it is sent as a push.
class ComposeNoticeScreen extends ConsumerStatefulWidget {
  const ComposeNoticeScreen({required this.societyId, super.key});

  final String societyId;

  @override
  ConsumerState<ComposeNoticeScreen> createState() =>
      _ComposeNoticeScreenState();
}

class _ComposeNoticeScreenState extends ConsumerState<ComposeNoticeScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _pinned = true;
  DateTime? _expires;
  File? _attachment;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _expires ?? now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      // The end of that day.
      setState(
        () =>
            _expires = DateTime(picked.year, picked.month, picked.day, 23, 59),
      );
    }
  }

  Future<void> _pickAttachment() async {
    final file = await ref.read(pickFileProvider)(const ['pdf', 'jpg', 'jpeg']);
    if (file == null) return;
    if (await file.length() >= 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).fileTooLarge(10))),
      );
      return;
    }
    setState(() => _attachment = file);
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authRepositoryProvider).currentUser;
    final me = ref.read(myMembershipProvider(widget.societyId)).value;
    if (user == null || me == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(societyRepositoryProvider)
          .postNotice(
            widget.societyId,
            authorUid: user.uid,
            authorName: me.displayName.isNotEmpty
                ? me.displayName
                : user.displayName ?? '',
            title: _title.text,
            body: _body.text,
            pinned: _pinned,
            expiresAt: _expires,
            attachment: _attachment,
          );
      router.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.noticePosted)));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newNotice)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.noticeTitle),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.requiredField : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _body,
              maxLength: 2000,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.noticeBody,
                alignLabelWithHint: true,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.pinNotice),
              subtitle: Text(l10n.pinNoticeBody),
              value: _pinned,
              onChanged: (v) => setState(() => _pinned = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                _expires == null
                    ? l10n.noExpiry
                    : l10n.expiresOn(DateFormat.yMMMd().format(_expires!)),
              ),
              trailing: _expires == null
                  ? TextButton(
                      onPressed: _pickExpiry,
                      child: Text(l10n.addExpiry),
                    )
                  : IconButton(
                      tooltip: l10n.removeExpiry,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _expires = null),
                    ),
              onTap: _pickExpiry,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file),
              title: Text(
                _attachment?.uri.pathSegments.last ?? l10n.noAttachment,
              ),
              trailing: _attachment == null
                  ? TextButton(
                      onPressed: _pickAttachment,
                      child: Text(l10n.attachFile),
                    )
                  : IconButton(
                      tooltip: l10n.removeAttachment,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _attachment = null),
                    ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: Text(l10n.postNotice),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noticePushNote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Upload a PDF for members: bylaws, minutes, budgets, rules.
class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({required this.societyId, super.key});

  final String societyId;

  @override
  ConsumerState<UploadDocumentScreen> createState() =>
      _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  final _title = TextEditingController();
  DocumentCategory _category = DocumentCategory.bylaws;
  File? _file;
  bool _uploading = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ref.read(pickFileProvider)(const ['pdf']);
    if (file == null) return;
    setState(() {
      _file = file;
      if (_title.text.isEmpty) {
        _title.text = file.uri.pathSegments.last.replaceAll(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        );
      }
    });
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    final file = _file;
    if (uid == null || file == null || _title.text.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _uploading = true);
    try {
      await ref
          .read(societyRepositoryProvider)
          .uploadDocument(
            widget.societyId,
            uid: uid,
            title: _title.text,
            category: _category,
            file: file,
          );
      router.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.documentUploaded)));
    } on FileTooLarge {
      messenger.showSnackBar(SnackBar(content: Text(l10n.fileTooLarge(20))));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ready = _file != null && _title.text.trim().isNotEmpty && !_uploading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadDocument)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_file?.uri.pathSegments.last ?? l10n.choosePdf),
            onPressed: _pick,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.documentTitle),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<DocumentCategory>(
            initialValue: _category,
            decoration: InputDecoration(labelText: l10n.documentCategory),
            items: [
              for (final c in DocumentCategory.values)
                DropdownMenuItem(value: c, child: Text(l10n.docCategory(c))),
            ],
            onChanged: (c) => setState(() => _category = c ?? _category),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: ready ? _upload : null,
            child: _uploading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.upload),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.documentsMembersOnly,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
