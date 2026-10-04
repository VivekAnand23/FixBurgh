import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String authFailureMessage(AppLocalizations l10n, AuthFailure f) => switch (f) {
  AuthFailure.cancelled => '',
  AuthFailure.invalidEmail => l10n.errorInvalidEmail,
  AuthFailure.weakPassword => l10n.errorWeakPassword,
  AuthFailure.invalidCredentials => l10n.errorInvalidCredentials,
  AuthFailure.emailInUse => l10n.errorEmailInUse,
  AuthFailure.credentialInUse => l10n.errorCredentialInUse,
  AuthFailure.requiresRecentLogin => l10n.errorRequiresRecentLogin,
  AuthFailure.network => l10n.errorNetwork,
  AuthFailure.unknown => l10n.errorGeneric,
};

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      _toast(success ?? '');
      if (mounted) context.pop();
    } on AuthException catch (e) {
      _toast(authFailureMessage(l10n, e.failure));
      if (e.failure == AuthFailure.credentialInUse && mounted) context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(authRepositoryProvider);
    final email = _email.text.trim();
    await _run(
      () => _creating
          ? repo.createEmailAccount(email, _password.text)
          : repo.signInWithEmail(email, _password.text),
      success: _creating ? l10n.verifyEmailSent(email) : null,
    );
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!email.contains('@')) {
      _toast(l10n.errorInvalidEmail);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      _toast(l10n.resetEmailSent(email));
    } on AuthException catch (e) {
      _toast(authFailureMessage(l10n, e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.signInBody, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                        ref.read(authRepositoryProvider).signInWithGoogle,
                      ),
                icon: const Icon(Icons.account_circle_outlined),
                label: Text(l10n.continueWithGoogle),
              ),
              // Sign in with Apple is added once the Apple Developer account
              // is set up (required by App Store guideline 4.8 before release).
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l10n.orUseEmail),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: l10n.email),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').trim().contains('@')
                    ? null
                    : l10n.errorInvalidEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  helperText: _creating ? l10n.passwordHint : null,
                ),
                obscureText: true,
                autofillHints: [
                  if (_creating)
                    AutofillHints.newPassword
                  else
                    AutofillHints.password,
                ],
                validator: (v) =>
                    (v ?? '').length >= 8 ? null : l10n.errorWeakPassword,
                onFieldSubmitted: (_) => _submitEmail(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submitEmail,
                child: Text(_creating ? l10n.createAccount : l10n.signIn),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _creating = !_creating),
                child: Text(_creating ? l10n.haveAccount : l10n.needAccount),
              ),
              if (!_creating)
                TextButton(
                  onPressed: _busy ? null : _resetPassword,
                  child: Text(l10n.forgotPassword),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
