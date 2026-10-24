import 'dart:async';
import 'dart:io';

import 'package:fixburgh/app/links.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/map/data/place_search.dart';
import 'package:fixburgh/features/routing/data/routing_providers.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/pickers.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// Overridden in tests.
final findPlaceProvider = Provider<Future<GeoPoint?> Function(String)>(
  (ref) => findPlace,
);

/// Claim a new society as its admin: details, HOA links, photo ID and proof
/// of office. A platform admin checks it before the society goes live.
/// [previous] prefills a resubmission of a rejected claim.
class CreateSocietyScreen extends ConsumerStatefulWidget {
  const CreateSocietyScreen({this.previous, super.key});

  final SocietyClaim? previous;

  @override
  ConsumerState<CreateSocietyScreen> createState() =>
      _CreateSocietyScreenState();
}

class _CreateSocietyScreenState extends ConsumerState<CreateSocietyScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _units = TextEditingController();
  final _applicant = TextEditingController();
  final _company = TextEditingController();
  final _website = TextEditingController();
  final _account = TextEditingController();
  ClaimPosition? _position;
  GeoPoint? _point;
  Municipality? _municipality;
  String? _addressError;
  bool _locating = false;
  List<NearbySociety> _nearby = const [];
  File? _idFile;
  File? _proofFile;
  bool _confirmed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _applicant.text =
        ref.read(authRepositoryProvider).currentUser?.displayName ?? '';
    final d = widget.previous?.data;
    if (d != null) {
      final s = (d['society'] as Map?)?.cast<String, dynamic>() ?? const {};
      final h = (d['hoa'] as Map?)?.cast<String, dynamic>() ?? const {};
      _name.text = s['name'] as String? ?? '';
      _address.text = s['address'] as String? ?? '';
      _units.text = '${s['units'] ?? ''}';
      _applicant.text = d['applicantName'] as String? ?? _applicant.text;
      _company.text = h['company'] as String? ?? '';
      _website.text = h['website'] as String? ?? '';
      _account.text = h['accountUrl'] as String? ?? '';
      _position = ClaimPosition.values
          .where((p) => p.id == d['position'])
          .firstOrNull;
      unawaited(_locate());
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _address,
      _units,
      _applicant,
      _company,
      _website,
      _account,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Finds the address, checks it is inside Allegheny County, and looks
  /// for societies already there.
  Future<void> _locate() async {
    final l10n = AppLocalizations.of(context);
    final q = _address.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _locating = true;
      _addressError = null;
      _nearby = const [];
    });
    final point = await ref.read(findPlaceProvider)(q);
    final locator = await ref.read(municipalityLocatorProvider.future);
    final municipality = point == null ? null : locator.locate(point);
    var nearby = const <NearbySociety>[];
    if (municipality != null) {
      nearby = await ref
          .read(societyRepositoryProvider)
          .checkDuplicates(point!)
          .catchError((_) => const <NearbySociety>[]);
    }
    if (!mounted) return;
    setState(() {
      _locating = false;
      _point = municipality == null ? null : point;
      _municipality = municipality;
      _nearby = nearby;
      _addressError = point == null
          ? l10n.addressNotFound
          : municipality == null
          ? l10n.outsideCountySociety
          : null;
    });
  }

  Future<void> _pickFile({required bool id, ImageSource? image}) async {
    final file = image != null
        ? await ref.read(pickImageProvider)(image)
        : await ref.read(pickFileProvider)(const ['pdf', 'jpg', 'jpeg', 'png']);
    if (file == null || !mounted) return;
    if (await file.length() >= maxClaimFileBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).fileTooLarge(5))),
      );
      return;
    }
    setState(() => id ? _idFile = file : _proofFile = file);
  }

  bool get _ready =>
      _point != null &&
      _municipality != null &&
      _position != null &&
      _idFile != null &&
      _proofFile != null &&
      _confirmed &&
      !_submitting;

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false) || !_ready) return;
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _submitting = true);
    try {
      final id = await ref
          .read(societyRepositoryProvider)
          .submitClaim(
            uid: user.uid,
            email: user.email ?? '',
            draft: ClaimDraft(
              name: _name.text,
              address: _address.text,
              location: _point!,
              municipality: _municipality!,
              units: int.parse(_units.text.trim()),
              position: _position!,
              applicantName: _applicant.text,
              hoa: HoaInfo(
                company: _company.text,
                website: _website.text,
                accountUrl: _account.text,
              ),
              previousClaimId: widget.previous?.id ?? '',
            ),
            idFile: _idFile!,
            proofFile: _proofFile!,
          );
      unawaited(router.pushReplacement(Routes.claim(id)));
      messenger.showSnackBar(SnackBar(content: Text(l10n.claimSubmitted)));
    } on FileTooLarge {
      messenger.showSnackBar(SnackBar(content: Text(l10n.fileTooLarge(5))));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDev = ref.watch(flavorProvider).isDev;
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l10n.requiredField : null;
    String? url(String? v) =>
        isValidHttpsUrl(normalizeUrl(v ?? '')) ? null : l10n.invalidLink;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createSociety)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(l10n.createSocietyIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            _Section(l10n.sectionSociety),
            TextFormField(
              controller: _name,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.societyName),
              validator: (v) =>
                  (v ?? '').trim().length < 2 ? l10n.requiredField : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _address,
              maxLength: 200,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => _locate(),
              onChanged: (_) => setState(() => _point = null),
              decoration: InputDecoration(
                labelText: l10n.societyAddress,
                helperText: _municipality != null && _point != null
                    ? l10n.inMunicipality(_municipality!.name)
                    : l10n.societyAddressHelp,
                errorText: _addressError,
                suffixIcon: _locating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: l10n.checkAddress,
                        icon: Icon(
                          _point != null ? Icons.check_circle : Icons.search,
                        ),
                        onPressed: _locate,
                      ),
              ),
              validator: required,
            ),
            if (_nearby.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DuplicateWarning(nearby: _nearby),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _units,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.numberOfHomes),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return n == null || n < 2 || n > maxSocietyUnits
                    ? l10n.numberOfHomesInvalid
                    : null;
              },
            ),
            const SizedBox(height: 16),
            _Section(l10n.sectionYou),
            TextFormField(
              controller: _applicant,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.yourFullName),
              validator: required,
            ),
            const SizedBox(height: 8),
            Text(l10n.yourPosition, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in ClaimPosition.values)
                  ChoiceChip(
                    label: Text(l10n.position(p)),
                    selected: _position == p,
                    onSelected: (_) => setState(() => _position = p),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(l10n.sectionHoa),
            Text(l10n.hoaHelp, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _company,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.hoaCompany),
            ),
            TextFormField(
              controller: _website,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l10n.hoaWebsite),
              validator: url,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _account,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.hoaAccountLink,
                helperText: l10n.hoaAccountLinkHelp,
                helperMaxLines: 2,
              ),
              validator: url,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Section(l10n.sectionDocuments)),
                if (isDev) const _DraftChip(),
              ],
            ),
            InfoBox(text: l10n.verificationRequirements),
            const SizedBox(height: 12),
            _FileRow(
              title: l10n.photoId,
              help: l10n.photoIdHelp,
              file: _idFile,
              onCamera: () => _pickFile(id: true, image: ImageSource.camera),
              onPhotos: () => _pickFile(id: true, image: ImageSource.gallery),
              onFile: () => _pickFile(id: true),
            ),
            const SizedBox(height: 12),
            _FileRow(
              title: l10n.proofOfOffice,
              help: l10n.proofOfOfficeHelp,
              file: _proofFile,
              onCamera: () => _pickFile(id: false, image: ImageSource.camera),
              onPhotos: () => _pickFile(id: false, image: ImageSource.gallery),
              onFile: () => _pickFile(id: false),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              title: Text(l10n.claimConfirm),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(AppLinks(ref.read(flavorProvider)).privacy),
                  mode: LaunchMode.inAppBrowserView,
                ),
                child: Text(l10n.howWeUseDocuments),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _ready ? _submit : null,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.submitForReview),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewTarget,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

/// Marks wording that still needs the owner's approval (dev builds only).
class _DraftChip extends StatelessWidget {
  const _DraftChip();

  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    label: Text(AppLocalizations.of(context).draftWording),
  );
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.title,
    required this.help,
    required this.file,
    required this.onCamera,
    required this.onPhotos,
    required this.onFile,
  });

  final String title;
  final String help;
  final File? file;
  final VoidCallback onCamera;
  final VoidCallback onPhotos;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final f = file;
    return SocietyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                f == null ? Icons.upload_file : Icons.check_circle,
                color: f == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            f == null ? help : f.uri.pathSegments.last,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.takePhoto),
                onPressed: onCamera,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.choosePhoto),
                onPressed: onPhotos,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text(l10n.chooseFile),
                onPressed: onFile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DuplicateWarning extends ConsumerWidget {
  const _DuplicateWarning({required this.nearby});

  final List<NearbySociety> nearby;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SocietyCard(
      borderColor: theme.colorScheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.societyDuplicateTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final s in nearby)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                s.pending
                    ? l10n.societyDuplicatePending(
                        s.name,
                        formatDistance(s.distanceM.toDouble()),
                      )
                    : l10n.societyDuplicateActive(
                        s.name,
                        formatDistance(s.distanceM.toDouble()),
                      ),
              ),
            ),
          const SizedBox(height: 4),
          Text(l10n.societyDuplicateBody, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
