import 'package:flutter/material.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';

// 로그인 화면 (골격) — 이메일/비밀번호 입력 + 계속 버튼
// 실제 인증 로직은 추후 Firebase/Auth 서버 연동 시 교체 예정
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
          // 간단한 언어 변경 메뉴 (로그인 화면에서도 제공)
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (loc) => widget.onLocaleChanged(loc),
            itemBuilder: (context) => [
              PopupMenuItem(value: const Locale('en'), child: Text(t.english)),
              PopupMenuItem(value: const Locale('ko'), child: Text(t.korean)),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.signInTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        labelText: t.email,
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.isEmpty) ? t.email : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pwCtrl,
                      decoration: InputDecoration(
                        labelText: t.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      obscureText: _obscure,
                      validator: (v) => (v == null || v.isEmpty) ? t.password : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          // TODO: 실제 인증 연동 시 컨트롤러의 signIn을 해당 서비스로 연결
                          if (_formKey.currentState?.validate() ?? false) {
                            final auth = context.read<AuthController>();
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await auth.signIn(
                              _emailCtrl.text.trim(),
                              _pwCtrl.text,
                            );
                            if (!ok) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Invalid credentials')),
                              );
                            }
                          }
                        },
                        child: Text(t.continueLabel),
                      ),
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
}
