import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';
import 'package:vendorjet/services/api/api_client.dart';
import 'package:vendorjet/ui/widgets/app_snackbar.dart';

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
                      style: Theme.of(context).textTheme.headlineSmall
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
                          child: Text(
                            _tr('Sign up', '\uD68C\uC6D0\uAC00\uC785'),
                          ),
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
      AppSnackbar.show(
        context,
        AppLocalizations.of(context)!.invalidCredentials,
      );
    }
  }

  Future<void> _handlePasswordReset() async {
    final t = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      AppSnackbar.show(context, t.email);
      return;
    }
    await context.read<AuthController>().requestPasswordReset(email);
    if (!mounted) return;
    AppSnackbar.show(context, t.passwordResetSent);
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
    final sellerPwConfirmCtrl = TextEditingController();
    bool sellerIsNew = true;
    Map<String, String> selectedSellerCompany = {};

    final buyerFormKey = GlobalKey<FormState>();
    final buyerCompanyCtrl = TextEditingController();
    final buyerAddressCtrl = TextEditingController();
    final buyerPhoneCtrl = TextEditingController();
    final buyerNameCtrl = TextEditingController();
    final buyerEmailCtrl = TextEditingController();
    final buyerPwCtrl = TextEditingController();
    final buyerPwConfirmCtrl = TextEditingController();
    final buyerAttachmentCtrl = TextEditingController();
    final buyerSegmentCtrl = TextEditingController();
    final sellerSearchCtrl = TextEditingController();
    bool buyerCompanyIsNew = true;
    Map<String, String> selectedBuyerCompany = {};
    Map<String, String> selectedTargetSeller = {};
    int tabIndex = 0;
    bool sellerEmailChecked = false;
    bool sellerEmailAvailable = false;
    bool buyerEmailChecked = false;
    bool buyerEmailAvailable = false;

    final companies = await _loadCompanies();
    if (!mounted) return;
    List<Map<String, String>> filteredCompanies(String type) {
      final lower = type.toLowerCase();
      return companies
          .where((c) => ((c['type'] ?? '').toLowerCase()) == lower)
          .toList();
    }

    final sellerCompanies = filteredCompanies('wholesale');
    final buyerCompanies = filteredCompanies('retail');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final viewportHeight = MediaQuery.of(dialogContext).size.height;
        final dialogHeight = (viewportHeight * 0.8).clamp(520.0, 720.0);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_tr('Sign up', '\uD68C\uC6D0\uAC00\uC785')),
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
                          label: Text(
                            _tr('Seller', '\uB3C4\uB9E4\uC5C5\uCCB4'),
                          ),
                          selected: tabIndex == 0,
                          onSelected: (_) => setState(() => tabIndex = 0),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(_tr('Buyer', '\uC18C\uB9E4')),
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
                            pwConfirmCtrl: sellerPwConfirmCtrl,
                            selectedCompany: selectedSellerCompany,
                            onSearchCompany: () async {
                              final picked = await _pickCompany(
                                context,
                                sellerCompanies,
                                _tr(
                                  'Search company',
                                  '\uD68C\uC0AC\uBA85 \uAC80\uC0C9',
                                ),
                              );
                              if (!dialogContext.mounted) return;
                              if (picked != null) {
                                setState(() {
                                  selectedSellerCompany = picked;
                                  sellerCompanyCtrl.text = picked['name'] ?? '';
                                  sellerPhoneCtrl.text = picked['phone'] ?? '';
                                  sellerAddressCtrl.text =
                                      picked['address'] ?? '';
                                });
                              }
                            },
                            emailChecked: sellerEmailChecked,
                            emailAvailable: sellerEmailAvailable,
                            onCheckEmail: () async {
                              final email = sellerEmailCtrl.text.trim();
                              if (email.isEmpty) {
                                _showSnack(
                                  dialogContext,
                                  _tr('Enter email', '???? ?????'),
                                );
                                return;
                              }
                              setState(() {
                                sellerEmailChecked = false;
                              });
                              final available = await _checkEmailAvailable(
                                email,
                              );
                              if (!dialogContext.mounted) return;
                              setState(() {
                                sellerEmailChecked = true;
                                sellerEmailAvailable = available;
                              });
                            },
                            onEmailChanged: () {
                              setState(() {
                                sellerEmailChecked = false;
                                sellerEmailAvailable = false;
                              });
                            },
                          ),
                          _buildBuyerForm(
                            formKey: buyerFormKey,
                            isNewBuyerCompany: buyerCompanyIsNew,
                            onToggleBuyerNew: (v) =>
                                setState(() => buyerCompanyIsNew = v),
                            buyerCompanyCtrl: buyerCompanyCtrl,
                            buyerAddressCtrl: buyerAddressCtrl,
                            buyerPhoneCtrl: buyerPhoneCtrl,
                            buyerSegmentCtrl: buyerSegmentCtrl,
                            buyerNameCtrl: buyerNameCtrl,
                            buyerEmailCtrl: buyerEmailCtrl,
                            buyerPwCtrl: buyerPwCtrl,
                            buyerPwConfirmCtrl: buyerPwConfirmCtrl,
                            attachmentCtrl: buyerAttachmentCtrl,
                            sellerSearchCtrl: sellerSearchCtrl,
                            selectedBuyerCompany: selectedBuyerCompany,
                            selectedSeller: selectedTargetSeller,
                            onSearchBuyerCompany: () async {
                              final picked = await _pickCompany(
                                context,
                                buyerCompanies,
                                _tr(
                                  'Search buyer company',
                                  '\uC18C\uB9E4 \uC5C5\uCCB4 \uAC80\uC0C9',
                                ),
                              );
                              if (!dialogContext.mounted) return;
                              if (picked != null) {
                                setState(() {
                                  selectedBuyerCompany = picked;
                                  buyerCompanyCtrl.text = picked['name'] ?? '';
                                  buyerPhoneCtrl.text = picked['phone'] ?? '';
                                  buyerAddressCtrl.text =
                                      picked['address'] ?? '';
                                  buyerSegmentCtrl.text =
                                      picked['segment'] ?? '';
                                  sellerSearchCtrl.text =
                                      picked['sellerName'] ?? '';
                                });
                              }
                            },
                            onSearchSeller: () async {
                              final picked = await _pickCompany(
                                context,
                                sellerCompanies,
                                _tr(
                                  'Search seller company',
                                  '\uB3C4\uB9E4 \uC5C5\uCCB4 \uAC80\uC0C9',
                                ),
                              );
                              if (!dialogContext.mounted) return;
                              if (picked != null) {
                                setState(() {
                                  selectedTargetSeller = picked;
                                  sellerSearchCtrl.text = picked['name'] ?? '';
                                });
                              }
                            },
                            sellerSelectionVisible: buyerCompanyIsNew,
                            emailChecked: buyerEmailChecked,
                            emailAvailable: buyerEmailAvailable,
                            onCheckEmail: () async {
                              final email = buyerEmailCtrl.text.trim();
                              if (email.isEmpty) {
                                _showSnack(
                                  dialogContext,
                                  _tr('Enter email', '???? ?????'),
                                );
                                return;
                              }
                              setState(() {
                                buyerEmailChecked = false;
                              });
                              final available = await _checkEmailAvailable(
                                email,
                              );
                              if (!dialogContext.mounted) return;
                              setState(() {
                                buyerEmailChecked = true;
                                buyerEmailAvailable = available;
                              });
                            },
                            onEmailChanged: () {
                              setState(() {
                                buyerEmailChecked = false;
                                buyerEmailAvailable = false;
                              });
                            },
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
                  child: Text(_tr('Cancel', '\uCDE8\uC18C')),
                ),
                FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.maybeOf(dialogContext);
                    final navigator = Navigator.of(dialogContext);
                    bool ok = false;
                    try {
                      if (tabIndex == 0) {
                        if (sellerFormKey.currentState?.validate() ?? false) {
                          if (!sellerEmailChecked || !sellerEmailAvailable) {
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  _tr(
                                    'Check email to enable submit',
                                    '\uC911\uBCF5 \uD655\uC778\uC744 \uC644\uB8CC\uD558\uC138\uC694.',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          ok = await auth.registerSeller(
                            companyName: sellerCompanyCtrl.text.trim(),
                            companyAddress: sellerAddressCtrl.text.trim(),
                            companyPhone: sellerPhoneCtrl.text.trim(),
                            name: sellerNameCtrl.text.trim(),
                            phone: sellerUserPhoneCtrl.text.trim(),
                            email: sellerEmailCtrl.text.trim(),
                            password: sellerPwCtrl.text,
                            role: sellerIsNew ? 'owner' : 'staff',
                          );
                        }
                      } else {
                        final sellerForExisting =
                            selectedBuyerCompany['sellerName'] ?? '';
                        if (buyerFormKey.currentState?.validate() ?? false) {
                          if (!buyerEmailChecked || !buyerEmailAvailable) {
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  _tr(
                                    'Check email to enable submit',
                                    '\uC911\uBCF5 \uD655\uC778\uC744 \uC644\uB8CC\uD558\uC138\uC694.',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          final sellerNameToSend = buyerCompanyIsNew
                              ? sellerSearchCtrl.text.trim()
                              : sellerForExisting;
                          if (buyerCompanyIsNew ||
                              sellerNameToSend.isNotEmpty) {
                            ok = await auth.registerBuyer(
                              sellerCompanyName: sellerNameToSend,
                              buyerCompanyName: buyerCompanyCtrl.text.trim(),
                              buyerAddress: buyerAddressCtrl.text.trim(),
                              buyerSegment: buyerSegmentCtrl.text.trim(),
                              name: buyerNameCtrl.text.trim(),
                              phone: buyerPhoneCtrl.text.trim(),
                              email: buyerEmailCtrl.text.trim(),
                              password: buyerPwCtrl.text,
                              attachmentUrl: buyerAttachmentCtrl.text.trim(),
                              role: buyerCompanyIsNew ? 'owner' : 'staff',
                              isNewBuyerCompany: buyerCompanyIsNew,
                            );
                          } else {
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  _tr(
                                    'No linked wholesaler for this company. Please contact admin.',
                                    '선택한 회사에 연결된 도매 업체 정보가 없습니다. 관리자에게 문의해 주세요.',
                                  ),
                                ),
                              ),
                            );
                          }
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
                                : _tr('Registration failed', '등록에 실패했습니다'),
                          ),
                        ),
                      );
                      if (ok) {
                        _emailCtrl.text = tabIndex == 0
                            ? sellerEmailCtrl.text.trim()
                            : buyerEmailCtrl.text.trim();
                        navigator.pop();
                        _pwFocusNode.requestFocus();
                      }
                    } catch (_) {
                      // ignore messenger errors
                    }
                  },
                  child: Text(_tr('Submit', '\uC81C\uCD9C')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, String>>> _loadCompanies() async {
    try {
      final resp =
          await ApiClient.get(
                '/auth/tenants-public',
                query: {'includeRetail': 'true'},
              )
              as List<dynamic>;
      final seen = <String>{};
      final list = <Map<String, String>>[];
      for (final raw in resp) {
        final name = raw['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final type = raw['type']?.toString() ?? '';
        final key = '$name|$type';
        if (seen.contains(key)) continue;
        seen.add(key);
        list.add({
          'id': raw['id']?.toString() ?? '',
          'name': name,
          'phone': raw['phone']?.toString() ?? '',
          'address': raw['address']?.toString() ?? '',
          'type': type,
          'segment': raw['segment']?.toString() ?? '',
          'sellerName': raw['sellerName']?.toString() ?? '',
        });
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<bool> _checkEmailAvailable(String email) async {
    try {
      final resp =
          await ApiClient.get('/auth/check-email', query: {'email': email})
              as Map<String, dynamic>;
      final exists = resp['exists'] as bool? ?? false;
      return !exists;
    } catch (_) {
      return false;
    }
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
    required TextEditingController pwConfirmCtrl,
    required Map<String, String> selectedCompany,
    required VoidCallback onSearchCompany,
    required bool emailChecked,
    required bool emailAvailable,
    required VoidCallback onCheckEmail,
    required VoidCallback onEmailChanged,
  }) {
    final existingLocked = !isNew && selectedCompany.isNotEmpty;
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: Text(_tr('New company', '신규')),
                  selected: isNew,
                  onSelected: (_) => onToggleNew(true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(_tr('Existing company', '\uAE30\uC874')),
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
                      labelText: _tr('Company name', '\uD68C\uC0AC\uBA85'),
                      filled: existingLocked,
                    ),
                    readOnly: existingLocked,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? _tr(
                            'Enter company name',
                            '\uD68C\uC0AC\uBA85\uC744 \uC785\uB825\uD558\uC138\uC694',
                          )
                        : null,
                  ),
                ),
                if (!isNew) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onSearchCompany,
                    child: Text(_tr('Search', '\uAC80\uC0C9')),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              readOnly: existingLocked,
              decoration: InputDecoration(
                labelText: _tr('Company phone', '\uD68C\uC0AC \uC804\uD654'),
                filled: existingLocked,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr(
                      'Enter phone',
                      '\uC804\uD654\uBC88\uD638\uB97C \uC785\uB825\uD558\uC138\uC694',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressCtrl,
              readOnly: existingLocked,
              decoration: InputDecoration(
                labelText: _tr('Company address', '\uC8FC\uC18C'),
                filled: existingLocked,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr(
                      'Enter address',
                      '\uC8FC\uC18C\uB97C \uC785\uB825\uD558\uC138\uC694',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: _tr('Your name', '\uC774\uB984'),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr(
                      'Enter your name',
                      '\uC774\uB984\uC744 \uC785\uB825\uD558\uC138\uC694',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: userPhoneCtrl,
              decoration: InputDecoration(
                labelText: _tr('Your phone', '\uC804\uD654\uBC88\uD638'),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr(
                      'Enter your phone',
                      '\uC804\uD654\uBC88\uD638\uB97C \uC785\uB825\uD558\uC138\uC694',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: _tr('Email', '\uC774\uBA54\uC77C'),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => onEmailChanged(),
                    validator: (v) => v == null || v.isEmpty
                        ? _tr(
                            'Enter email',
                            '\uC774\uBA54\uC77C\uC744 \uC785\uB825\uD558\uC138\uC694',
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onCheckEmail,
                  child: Text(_tr('Check', '\uC911\uBCF5 \uD655\uC778')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              emailChecked
                  ? (emailAvailable
                        ? _tr(
                            'Email is available',
                            '\uC0AC\uC6A9 \uAC00\uB2A5\uD55C \uC774\uBA54\uC77C\uC785\uB2C8\uB2E4.',
                          )
                        : _tr(
                            'Email already exists',
                            '\uC774\uBBF8 \uB4F1\uB85D\uB41C \uC774\uBA54\uC77C\uC785\uB2C8\uB2E4.',
                          ))
                  : _tr(
                      'Check email to enable submit',
                      '\uC911\uBCF5 \uD655\uC778\uC744 \uC644\uB8CC\uD558\uC138\uC694.',
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: pwCtrl,
              decoration: InputDecoration(
                labelText: _tr('Password', '\uBE44\uBC00\uBC88\uD638'),
              ),
              obscureText: true,
              validator: (v) => v == null || v.length < 6
                  ? _tr('Min 6 chars', '6\uC790 \uC774\uC0C1 \uC785\uB825')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: pwConfirmCtrl,
              decoration: InputDecoration(
                labelText: _tr(
                  'Confirm password',
                  '\uBE44\uBC00\uBC88\uD638 \uD655\uC778',
                ),
              ),
              obscureText: true,
              validator: (v) => v != pwCtrl.text
                  ? _tr(
                      'Passwords do not match',
                      '\uBE44\uBC00\uBC88\uD638\uAC00 \uC77C\uCE58\uD558\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4',
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              isNew
                  ? _tr(
                      'New company: you will be registered as owner.',
                      '신규 회사: 신청자가 대표(Owner)로 등록됩니다.',
                    )
                  : _tr(
                      'Existing company: access after owner/manager approval.',
                      '기존 회사: 대표/관리자 승인 후 이용 가능합니다.',
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
    required TextEditingController buyerSegmentCtrl,
    required TextEditingController buyerNameCtrl,
    required TextEditingController buyerEmailCtrl,
    required TextEditingController buyerPwCtrl,
    required TextEditingController buyerPwConfirmCtrl,
    required TextEditingController attachmentCtrl,
    required TextEditingController sellerSearchCtrl,
    required Map<String, String> selectedBuyerCompany,
    required Map<String, String> selectedSeller,
    required VoidCallback onSearchBuyerCompany,
    required VoidCallback onSearchSeller,
    required bool sellerSelectionVisible,
    required bool emailChecked,
    required bool emailAvailable,
    required VoidCallback onCheckEmail,
    required VoidCallback onEmailChanged,
  }) {
    final existingLocked =
        !isNewBuyerCompany && selectedBuyerCompany.isNotEmpty;
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: Text(_tr('New company', '신규')),
                  selected: isNewBuyerCompany,
                  onSelected: (_) => onToggleBuyerNew(true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(_tr('Existing company', '\uAE30\uC874')),
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
                    decoration: InputDecoration(
                      labelText: _tr(
                        'Buyer company',
                        '\uC18C\uB9E4 \uC5C5\uCCB4',
                      ),
                      filled: existingLocked,
                    ),
                    readOnly: existingLocked,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? _tr(
                            'Enter company',
                            '\uC5C5\uCCB4\uBA85\uC744 \uC785\uB825\uD558\uC138\uC694',
                          )
                        : null,
                  ),
                ),
                if (!isNewBuyerCompany) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onSearchBuyerCompany,
                    child: Text(_tr('Search', '\uAC80\uC0C9')),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerAddressCtrl,
              enabled: !existingLocked,
              readOnly: existingLocked,
              decoration: InputDecoration(
                labelText: _tr('Buyer address', '\uC8FC\uC18C'),
                filled: existingLocked,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr(
                      'Enter address',
                      '\uC8FC\uC18C\uB97C \uC785\uB825\uD558\uC138\uC694',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerPhoneCtrl,
              enabled: !existingLocked,
              readOnly: existingLocked,
              decoration: InputDecoration(
                labelText: _tr('Buyer phone', '\uC5F0\uB77D\uCC98'),
                filled: existingLocked,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr(
                      'Enter phone',
                      '\uC804\uD654\uBC88\uD638\uB97C \uC785\uB825\uD558\uC138\uC694',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerSegmentCtrl,
              enabled: isNewBuyerCompany,
              readOnly: existingLocked,
              decoration: InputDecoration(
                labelText: _tr('Buyer segment', '\uC5C5\uCCB4 \uBD84\uB958'),
                filled: existingLocked,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerNameCtrl,
              decoration: InputDecoration(
                labelText: _tr('Your name', '\uC774\uB984'),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr(
                      'Enter your name',
                      '\uC774\uB984\uC744 \uC785\uB825\uD558\uC138\uC694',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: buyerEmailCtrl,
                    decoration: InputDecoration(
                      labelText: _tr('Email', '\uC774\uBA54\uC77C'),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => onEmailChanged(),
                    validator: (v) => v == null || v.isEmpty
                        ? _tr(
                            'Enter email',
                            '\uC774\uBA54\uC77C\uC744 \uC785\uB825\uD558\uC138\uC694',
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onCheckEmail,
                  child: Text(_tr('Check', '\uC911\uBCF5 \uD655\uC778')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              emailChecked
                  ? (emailAvailable
                        ? _tr(
                            'Email is available',
                            '\uC0AC\uC6A9 \uAC00\uB2A5\uD55C \uC774\uBA54\uC77C\uC785\uB2C8\uB2E4.',
                          )
                        : _tr(
                            'Email already exists',
                            '\uC774\uBBF8 \uB4F1\uB85D\uB41C \uC774\uBA54\uC77C\uC785\uB2C8\uB2E4.',
                          ))
                  : _tr(
                      'Check email to enable submit',
                      '\uC911\uBCF5 \uD655\uC778\uC744 \uC644\uB8CC\uD558\uC138\uC694.',
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerPwCtrl,
              decoration: InputDecoration(
                labelText: _tr(
                  'Password (login)',
                  '\uB85C\uADF8\uC778 \uBE44\uBC00\uBC88\uD638',
                ),
              ),
              obscureText: true,
              validator: (v) => v == null || v.isEmpty
                  ? _tr(
                      'Enter password',
                      '\uBE44\uBC00\uBC88\uD638\uB97C \uC785\uB825\uD558\uC138\uC694',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerPwConfirmCtrl,
              decoration: InputDecoration(
                labelText: _tr(
                  'Confirm password',
                  '\uBE44\uBC00\uBC88\uD638 \uD655\uC778',
                ),
              ),
              obscureText: true,
              validator: (v) => v != buyerPwCtrl.text
                  ? _tr(
                      'Passwords do not match',
                      '\uBE44\uBC00\uBC88\uD638\uAC00 \uC77C\uCE58\uD558\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            if (sellerSelectionVisible) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: sellerSearchCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: _tr(
                          'Target seller name',
                          '\uB3C4\uB9E4 \uC5C5\uCCB4\uBA85',
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? _tr(
                              'Select seller company',
                              '\uB3C4\uB9E4 \uC5C5\uCCB4\uB97C \uC120\uD0DD\uD558\uC138\uC694',
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onSearchSeller,
                    child: Text(_tr('Search', '\uAC80\uC0C9')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _tr(
                  'After seller approval, you can view products.',
                  '도매 승인 후 상품을 확인할 수 있습니다.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: attachmentCtrl,
                decoration: InputDecoration(
                  labelText: _tr(
                    'Attachment URL (optional)',
                    '\uCCA8\uBD80\uD30C\uC77C URL (\uC120\uD0DD)',
                  ),
                  helperText: _tr(
                    'Attach your business license if the seller requires it.',
                    '도매업체가 요청한 경우 사업자등록증 등을 첨부하세요.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (selectedSeller.isNotEmpty)
                Text(
                  '${_tr('Seller', '\uB3C4\uB9E4\uC5C5\uCCB4')}: ${selectedSeller['name']} / ${selectedSeller['phone']} / ${selectedSeller['address']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
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
                .where(
                  (c) => c['name']!.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: _tr('Search by name', '회사명 검색'),
                      ),
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

void _showSnack(BuildContext context, String message) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: scheme.inverseSurface,
      content: Text(message, style: TextStyle(color: scheme.onInverseSurface)),
    ),
  );
}
