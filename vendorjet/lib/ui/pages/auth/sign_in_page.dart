import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';

class SignInPage extends StatefulWidget {
  final Locale? currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const SignInPage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  bool _signingIn = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: widget.onLocaleChanged,
            itemBuilder: (context) => [
              PopupMenuItem(value: const Locale('en'), child: Text(t.english)),
              PopupMenuItem(value: const Locale('ko'), child: Text(t.korean)),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.signInTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        labelText: t.email,
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? t.email : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pwCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: t.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? t.password : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _signingIn ? null : _handleSignIn,
                        child: _signingIn
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(t.continueLabel),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _handlePasswordReset,
                          child: Text(t.forgotPassword),
                        ),
                        TextButton(
                          onPressed: _showRegistrationDialog,
                          child: Text(t.registerVendor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.signInHelperCredentials,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    setState(() => _signingIn = true);
    final ok = await auth.signIn(_emailCtrl.text.trim(), _pwCtrl.text);
    if (!mounted) return;
    setState(() => _signingIn = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invalidCredentials),
        ),
      );
    }
  }

  Future<void> _handlePasswordReset() async {
    final t = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.email)));
      return;
    }
    await context.read<AuthController>().requestPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.passwordResetSent)));
  }

  Future<void> _showRegistrationDialog() async {
    final t = AppLocalizations.of(context)!;
    final auth = context.read<AuthController>();
    final tenantCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.registerVendor),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tenantCtrl,
                  decoration: InputDecoration(labelText: t.tenantName),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? t.tenantName : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: InputDecoration(labelText: t.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? t.email : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pwCtrl,
                  decoration: InputDecoration(labelText: t.password),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 6 ? t.password : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.orderEditCancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text(t.registerVendor),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final ok = await auth.registerTenant(
      tenantName: tenantCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      password: pwCtrl.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? t.registerSuccess : t.registerFailed)),
    );
  }
}
