import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';
import 'package:vendorjet/services/api/api_client.dart';

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
  final _pwFocusNode = FocusNode();
  bool _obscure = true;
  bool _signingIn = false;

  String _tr(String en, String ko) =>
      Localizations.localeOf(context).languageCode == 'ko' ? ko : en;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pwFocusNode.dispose();
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.email,
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_pwFocusNode),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? t.email : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pwCtrl,
                      focusNode: _pwFocusNode,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
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
                      onFieldSubmitted: (_) => _handleSignIn(),
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
                          child: Text(_tr('Sign up', '회원가입')),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.email)));
      return;
    }
    await context.read<AuthController>().requestPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.passwordResetSent)));
  }

  Future<void> _showRegistrationDialog() async {
    final auth = context.read<AuthController>();
    final sellerFormKey = GlobalKey<FormState>();
    final sellerCompanyCtrl = TextEditingController();
    final sellerAddressCtrl = TextEditingController();
    final sellerPhoneCtrl = TextEditingController();
    final sellerNameCtrl = TextEditingController();
    final sellerUserPhoneCtrl = TextEditingController();
    final sellerEmailCtrl = TextEditingController();
    final sellerPwCtrl = TextEditingController();
    final sellerRole = ValueNotifier<String>('staff');
    bool sellerIsNew = true;
    Map<String, String> selectedSellerCompany = {};

    final buyerFormKey = GlobalKey<FormState>();
    final buyerCompanyCtrl = TextEditingController();
    final buyerAddressCtrl = TextEditingController();
    final buyerPhoneCtrl = TextEditingController();
    final buyerNameCtrl = TextEditingController();
    final buyerEmailCtrl = TextEditingController();
    final buyerAttachmentCtrl = TextEditingController();
    final sellerSearchCtrl = TextEditingController();
    final buyerRole = ValueNotifier<String>('staff');
    bool buyerCompanyIsNew = true;
    Map<String, String> selectedBuyerCompany = {};
    Map<String, String> selectedTargetSeller = {};
    int tabIndex = 0;

    List<Map<String, String>> companies = [];
    try {
      final resp = await ApiClient.get('/auth/tenants-public') as List<dynamic>;
      companies = resp
          .map((e) => {
                'id': e['id']?.toString() ?? '',
                'name': e['name']?.toString() ?? '',
                'phone': e['phone']?.toString() ?? '',
                'address': e['address']?.toString() ?? '',
              })
          .where((e) => (e['name'] ?? '').isNotEmpty)
          .toList();
    } catch (_) {
      companies = [];
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final viewportHeight = MediaQuery.of(dialogContext).size.height;
        final dialogHeight = (viewportHeight * 0.8).clamp(520.0, 720.0);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_tr('Sign up', '회원가입')),
              content: SizedBox(
                width: 560,
                height: dialogHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: Text(_tr('Seller', '도매')),
                          selected: tabIndex == 0,
                          onSelected: (_) => setState(() => tabIndex = 0),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(_tr('Buyer', '소매')),
                          selected: tabIndex == 1,
                          onSelected: (_) => setState(() => tabIndex = 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: IndexedStack(
                        index: tabIndex,
                        children: [
                          _buildSellerForm(
                            formKey: sellerFormKey,
                            isNew: sellerIsNew,
                            onToggleNew: (v) => setState(() => sellerIsNew = v),
                            companyCtrl: sellerCompanyCtrl,
                            addressCtrl: sellerAddressCtrl,
                            phoneCtrl: sellerPhoneCtrl,
                            nameCtrl: sellerNameCtrl,
                            userPhoneCtrl: sellerUserPhoneCtrl,
                            emailCtrl: sellerEmailCtrl,
                            pwCtrl: sellerPwCtrl,
                            selectedCompany: selectedSellerCompany,
                            onSearchCompany: () async {
                              final picked = await _pickCompany(
                                context,
                                companies,
                                _tr('Search company', '회사명 검색'),
                              );
                              if (!dialogContext.mounted) return;
                              if (picked != null) {
                                setState(() {
                                  selectedSellerCompany = picked;
                                  sellerCompanyCtrl.text =
                                      picked['name'] ?? '';
                                  sellerPhoneCtrl.text =
                                      picked['phone'] ?? '';
                                  sellerAddressCtrl.text =
                                      picked['address'] ?? '';
                                });
                              }
                            },
                            roleNotifier: sellerRole,
                          ),
                          _buildBuyerForm(
                            formKey: buyerFormKey,
                            isNewBuyerCompany: buyerCompanyIsNew,
                            onToggleBuyerNew: (v) =>
                                setState(() => buyerCompanyIsNew = v),
                            buyerCompanyCtrl: buyerCompanyCtrl,
                            buyerAddressCtrl: buyerAddressCtrl,
                            buyerPhoneCtrl: buyerPhoneCtrl,
                            buyerNameCtrl: buyerNameCtrl,
                            buyerEmailCtrl: buyerEmailCtrl,
                            attachmentCtrl: buyerAttachmentCtrl,
                            sellerSearchCtrl: sellerSearchCtrl,
                            selectedBuyerCompany: selectedBuyerCompany,
                            selectedSeller: selectedTargetSeller,
                            onSearchBuyerCompany: () async {
                              final picked = await _pickCompany(
                                context,
                                companies,
                                _tr('Search buyer company', '구매 업체 검색'),
                              );
                              if (!dialogContext.mounted) return;
                              if (picked != null) {
                                setState(() {
                                  selectedBuyerCompany = picked;
                                  buyerCompanyCtrl.text =
                                      picked['name'] ?? '';
                                  buyerPhoneCtrl.text =
                                      picked['phone'] ?? '';
                                  buyerAddressCtrl.text =
                                      picked['address'] ?? '';
                                });
                              }
                            },
                            onSearchSeller: () async {
                              final picked = await _pickCompany(
                                context,
                                companies,
                                _tr('Search seller company', '도매 업체 검색'),
                              );
                              if (!dialogContext.mounted) return;
                              if (picked != null) {
                                setState(() {
                                  selectedTargetSeller = picked;
                                  sellerSearchCtrl.text =
                                      picked['name'] ?? '';
                                });
                              }
                            },
                            roleNotifier: buyerRole,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_tr('Cancel', '취소')),
                ),
                FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.maybeOf(dialogContext);
                    final navigator = Navigator.of(dialogContext);
                    bool ok = false;
                    try {
                      if (tabIndex == 0) {
                        if (sellerFormKey.currentState?.validate() ?? false) {
                          ok = await auth.registerSeller(
                            companyName: sellerCompanyCtrl.text.trim(),
                            companyAddress: sellerAddressCtrl.text.trim(),
                            companyPhone: sellerPhoneCtrl.text.trim(),
                            name: sellerNameCtrl.text.trim(),
                            phone: sellerUserPhoneCtrl.text.trim(),
                            email: sellerEmailCtrl.text.trim(),
                            password: sellerPwCtrl.text,
                            role: sellerIsNew ? 'owner' : sellerRole.value,
                          );
                        }
                      } else {
                        if ((buyerFormKey.currentState?.validate() ?? false) &&
                            sellerSearchCtrl.text.isNotEmpty) {
                          final roleToUse =
                              buyerCompanyIsNew ? 'owner' : buyerRole.value;
                          ok = await auth.registerBuyer(
                            sellerCompanyName: sellerSearchCtrl.text.trim(),
                            buyerCompanyName: buyerCompanyCtrl.text.trim(),
                            buyerAddress: buyerAddressCtrl.text.trim(),
                            name: buyerNameCtrl.text.trim(),
                            phone: buyerPhoneCtrl.text.trim(),
                            email: buyerEmailCtrl.text.trim(),
                            attachmentUrl: buyerAttachmentCtrl.text.trim(),
                            role: roleToUse,
                          );
                        }
                      }
                    } catch (_) {
                      ok = false;
                    }
                    if (!mounted) return;
                    try {
                      messenger?.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? _tr(
                                    'Submitted (may require approval)',
                                    '제출 완료 (승인 대기일 수 있음)',
                                  )
                                : _tr(
                                    'Registration failed',
                                    '등록에 실패했습니다',
                                  ),
                          ),
                        ),
                      );
                      if (ok) navigator.pop();
                    } catch (_) {
                      // ignore messenger errors
                    }
                  },
                  child: Text(_tr('Submit', '등록')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSellerForm({
    required GlobalKey<FormState> formKey,
    required bool isNew,
    required ValueChanged<bool> onToggleNew,
    required TextEditingController companyCtrl,
    required TextEditingController addressCtrl,
    required TextEditingController phoneCtrl,
    required TextEditingController nameCtrl,
    required TextEditingController userPhoneCtrl,
    required TextEditingController emailCtrl,
    required TextEditingController pwCtrl,
    required Map<String, String> selectedCompany,
    required VoidCallback onSearchCompany,
    required ValueNotifier<String> roleNotifier,
  }) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: Text(_tr('New company', '신규 회사')),
                  selected: isNew,
                  onSelected: (_) => onToggleNew(true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(_tr('Existing', '기존')),
                  selected: !isNew,
                  onSelected: (_) => onToggleNew(false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: companyCtrl,
                    decoration: InputDecoration(
                      labelText: _tr('Company name', '회사명'),
                    ),
                    readOnly: !isNew && selectedCompany.isNotEmpty,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? _tr('Enter company name', '회사명을 입력하세요') : null,
                  ),
                ),
                if (!isNew) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onSearchCompany,
                    child: Text(_tr('Search', '검색')),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              decoration: InputDecoration(
                labelText: _tr('Company phone', '대표번호'),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? _tr('Enter phone', '대표번호를 입력하세요') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressCtrl,
              decoration: InputDecoration(
                labelText: _tr('Company address', '주소'),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? _tr('Enter address', '주소를 입력하세요') : null,
            ),
            const SizedBox(height: 12),
            if (!isNew)
              ValueListenableBuilder<String>(
                valueListenable: roleNotifier,
                builder: (context, value, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: value,
                    decoration: InputDecoration(labelText: _tr('Role', '역할')),
                    items: [
                      DropdownMenuItem(value: 'manager', child: Text(_tr('Manager', '관리자'))),
                      DropdownMenuItem(value: 'staff', child: Text(_tr('Staff', '직원'))),
                    ],
                    onChanged: (v) {
                      if (v != null) roleNotifier.value = v;
                    },
                  );
                },
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: _tr('Your name', '이름')),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? _tr('Enter your name', '이름을 입력하세요') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: userPhoneCtrl,
              decoration: InputDecoration(labelText: _tr('Your phone', '전화번호')),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? _tr('Enter your phone', '전화번호를 입력하세요') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: _tr('Email', '이메일')),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || v.isEmpty ? _tr('Enter email', '이메일을 입력하세요') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: pwCtrl,
              decoration: InputDecoration(labelText: _tr('Password', '비밀번호')),
              obscureText: true,
              validator: (v) =>
                  v == null || v.length < 6 ? _tr('Min 6 chars', '6자 이상 입력') : null,
            ),
            const SizedBox(height: 8),
            Text(
              isNew
                  ? _tr(
                      'New company: you will be registered as owner.',
                      '신규 회사: 가입자가 사장(소유자)로 등록됩니다.',
                    )
                  : _tr(
                      'Existing company: access after owner/manager approval.',
                      '기존 회사: 관리자/사장 승인 후 이용 가능합니다.',
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerForm({
    required GlobalKey<FormState> formKey,
    required bool isNewBuyerCompany,
    required ValueChanged<bool> onToggleBuyerNew,
    required TextEditingController buyerCompanyCtrl,
    required TextEditingController buyerAddressCtrl,
    required TextEditingController buyerPhoneCtrl,
    required TextEditingController buyerNameCtrl,
    required TextEditingController buyerEmailCtrl,
    required TextEditingController attachmentCtrl,
    required TextEditingController sellerSearchCtrl,
    required Map<String, String> selectedBuyerCompany,
    required Map<String, String> selectedSeller,
    required VoidCallback onSearchBuyerCompany,
    required VoidCallback onSearchSeller,
    required ValueNotifier<String> roleNotifier,
  }) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: Text(_tr('New company', '신규 회사')),
                  selected: isNewBuyerCompany,
                  onSelected: (_) => onToggleBuyerNew(true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(_tr('Existing', '기존')),
                  selected: !isNewBuyerCompany,
                  onSelected: (_) => onToggleBuyerNew(false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: buyerCompanyCtrl,
                    decoration: InputDecoration(labelText: _tr('Buyer company', '구매자 회사명')),
                    readOnly: !isNewBuyerCompany && selectedBuyerCompany.isNotEmpty,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? _tr('Enter company', '회사명을 입력하세요') : null,
                  ),
                ),
                if (!isNewBuyerCompany) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onSearchBuyerCompany,
                    child: Text(_tr('Search', '검색')),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerAddressCtrl,
              decoration: InputDecoration(labelText: _tr('Buyer address', '주소')),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? _tr('Enter address', '주소를 입력하세요') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerPhoneCtrl,
              decoration: InputDecoration(labelText: _tr('Buyer phone', '대표번호')),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? _tr('Enter phone', '대표번호를 입력하세요') : null,
            ),
            const SizedBox(height: 12),
            if (!isNewBuyerCompany)
              ValueListenableBuilder<String>(
                valueListenable: roleNotifier,
                builder: (context, value, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: value,
                    decoration: InputDecoration(labelText: _tr('Role', '역할')),
                    items: [
                      DropdownMenuItem(value: 'manager', child: Text(_tr('Manager', '관리자'))),
                      DropdownMenuItem(value: 'staff', child: Text(_tr('Staff', '직원'))),
                    ],
                    onChanged: (v) {
                      if (v != null) roleNotifier.value = v;
                    },
                  );
                },
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerNameCtrl,
              decoration: InputDecoration(labelText: _tr('Your name', '이름')),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? _tr('Enter your name', '이름을 입력하세요') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerEmailCtrl,
              decoration: InputDecoration(labelText: _tr('Email', '이메일')),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || v.isEmpty ? _tr('Enter email', '이메일을 입력하세요') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: attachmentCtrl,
              decoration: InputDecoration(
                labelText: _tr('Attachment URL (optional)', '첨부파일 URL (선택)'),
                helperText: _tr(
                  'Business license if the seller requires it (optional)',
                  '판매자가 요구하는 경우 사업자등록증 등 첨부 (선택)',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: sellerSearchCtrl,
                    decoration: InputDecoration(labelText: _tr('Target seller name', '도매 업체명')),
                    readOnly: selectedSeller.isNotEmpty,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onSearchSeller,
                  child: Text(_tr('Search', '검색')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedSeller.isNotEmpty)
              Text(
                '${_tr('Seller', '도매업체')}: ${selectedSeller['name']} / ${selectedSeller['phone']} / ${selectedSeller['address']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Text(
              _tr(
                'After seller approval, you can view products.',
                '도매 승인 후 상품을 볼 수 있습니다.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>?> _pickCompany(
    BuildContext context,
    List<Map<String, String>> companies,
    String title,
  ) async {
    String query = '';
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final list = companies
                .where((c) => c['name']!.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: _tr('Search by name', '회사명 검색')),
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return ListTile(
                            title: Text(item['name'] ?? ''),
                            subtitle: Text(
                              '${item['phone'] ?? ''} · ${item['address'] ?? ''}',
                            ),
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
