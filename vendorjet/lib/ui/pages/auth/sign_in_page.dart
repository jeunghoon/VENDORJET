import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';
import 'package:vendorjet/services/api/api_client.dart';
import 'package:vendorjet/ui/widgets/notification_ticker.dart';

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
      _showSnack(context, AppLocalizations.of(context)!.invalidCredentials);
    }
  }

  Future<void> _handlePasswordReset() async {
    final t = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack(context, t.email);
      return;
    }
    await context.read<AuthController>().requestPasswordReset(email);
    if (!mounted) return;
    _showSnack(context, t.passwordResetSent);
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
                            pwConfirmCtrl: sellerPwConfirmCtrl,
                            selectedCompany: selectedSellerCompany,
                            onSearchCompany: () async {
                              final picked = await _pickCompany(
                                context,
                                sellerCompanies,
                                _tr('Search company', '회사명 검색'),
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
                                  _tr('Enter email', '이메일을 입력하세요.'),
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
                                _tr('Search buyer company', '소매 업체 검색'),
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
                                _tr('Search seller company', '도매 업체 검색'),
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
                                  _tr('Enter email', '이메일을 입력하세요.'),
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
                  child: Text(_tr('Cancel', '취소')),
                ),
                FilledButton(
                  onPressed: () async {
                    final navigator = Navigator.of(dialogContext);
                    bool ok = false;
                    try {
                      if (tabIndex == 0) {
                        if (sellerFormKey.currentState?.validate() ?? false) {
                          if (!sellerEmailChecked || !sellerEmailAvailable) {
                            _showSnack(
                              dialogContext,
                              _tr(
                                'Check email to enable submit',
                                '중복 확인을 완료하세요.',
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
                            isNew: sellerIsNew,
                          );
                        }
                      } else {
                        final sellerForExisting =
                            selectedBuyerCompany['sellerName'] ?? '';
                        if (buyerFormKey.currentState?.validate() ?? false) {
                          if (!buyerEmailChecked || !buyerEmailAvailable) {
                            _showSnack(
                              dialogContext,
                              _tr(
                                'Check email to enable submit',
                                '중복 확인을 완료하세요.',
                              ),
                            );
                            return;
                          }
                          final sellerNameToSend = buyerCompanyIsNew
                              ? sellerSearchCtrl.text.trim()
                              : sellerForExisting;
                          if (buyerCompanyIsNew &&
                              sellerNameToSend.isEmpty) {
                            _showSnack(
                              dialogContext,
                              _tr(
                                'Select a wholesaler for new buyer company.',
                                '신규 소매 업체를 등록하려면 연결할 도매 업체를 선택하세요.',
                              ),
                            );
                            return;
                          }
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
                        }
                      }
                    } catch (_) {
                      ok = false;
                    }
                    if (!mounted || !dialogContext.mounted) return;
                    try {
                      _showSnack(
                        dialogContext,
                        ok
                            ? _tr(
                                'Submitted (may require approval)',
                                '제출 완료 (승인 절차가 필요할 수 있음)',
                              )
                            : _tr('Registration failed', '등록에 실패했습니다'),
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
                  child: Text(_tr('Submit', '제출')),
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
    final isExistingMode = !isNew;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bodySmall = theme.textTheme.bodySmall;
    final neutralColor = bodySmall?.color ?? colorScheme.onSurfaceVariant;
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
                  label: Text(_tr('Existing company', '기존')),
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
                    decoration: _readOnlyInputDecoration(
                      label: _tr('Company name', '업체명'),
                      readOnly: isExistingMode,
                      showFill: false,
                      helperText: isExistingMode
                          ? _tr(
                              'Use search to select an existing company.',
                              '기존 업체는 검색 버튼으로 선택하세요.',
                            )
                          : null,
                    ),
                    style: _readOnlyTextStyle(
                      isExistingMode,
                      applyStyle: false,
                    ),
                    readOnly: isExistingMode,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? _tr('Enter company name', '업체명을 입력하세요')
                        : null,
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
            if (!isExistingMode) ...[
              const SizedBox(height: 6),
              Text(
                _tr(
                  'New company: you will be registered as owner.',
                  '신규 회사: 신청자가 대표(Owner)로 등록됩니다.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                _tr(
                  'Existing company: access after owner/manager approval.',
                  '기존 회사: 대표/관리자 승인 후 이용 가능합니다.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              enabled: !isExistingMode,
              readOnly: isExistingMode,
              style: _readOnlyTextStyle(isExistingMode),
              decoration: _readOnlyInputDecoration(
                label: _tr('Company phone', '대표번호'),
                readOnly: isExistingMode,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr('Enter phone', '전화번호를 입력하세요')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressCtrl,
              enabled: !isExistingMode,
              readOnly: isExistingMode,
              style: _readOnlyTextStyle(isExistingMode),
              decoration: _readOnlyInputDecoration(
                label: _tr('Company address', '주소'),
                readOnly: isExistingMode,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr('Enter address', '주소를 입력하세요')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: _tr('Your name', '이름')),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr('Enter your name', '이름을 입력하세요')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: userPhoneCtrl,
              decoration: InputDecoration(labelText: _tr('Your phone', '전화번호')),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr('Enter your phone', '전화번호를 입력하세요')
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: emailCtrl,
                    decoration: InputDecoration(labelText: _tr('Email', '이메일')),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => onEmailChanged(),
                    validator: (v) => v == null || v.isEmpty
                        ? _tr('Enter email', '이메일을 입력하세요')
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onCheckEmail,
                  child: Text(_tr('Check', '중복 확인')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              emailChecked
                  ? (emailAvailable
                        ? _tr('Email is available', '사용 가능한 이메일입니다.')
                        : _tr('Email already exists', '이미 등록된 이메일입니다.'))
                  : _tr('Check email to enable submit', '중복 확인을 완료하세요.'),
              style: (bodySmall ?? const TextStyle()).copyWith(
                color: emailChecked
                    ? (emailAvailable ? colorScheme.primary : colorScheme.error)
                    : neutralColor,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: pwCtrl,
              decoration: InputDecoration(labelText: _tr('Password', '비밀번호')),
              obscureText: true,
              validator: (v) => v == null || v.length < 6
                  ? _tr('Min 6 chars', '6자 이상 입력')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: pwConfirmCtrl,
              decoration: InputDecoration(
                labelText: _tr('Confirm password', '비밀번호 확인'),
              ),
              obscureText: true,
              validator: (v) => v != pwCtrl.text
                  ? _tr('Passwords do not match', '비밀번호가 일치하지 않습니다')
                  : null,
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
    final isExistingMode = !isNewBuyerCompany;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bodySmall = theme.textTheme.bodySmall;
    final neutralColor = bodySmall?.color ?? colorScheme.onSurfaceVariant;
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
                  label: Text(_tr('Existing company', '기존')),
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
                    decoration: _readOnlyInputDecoration(
                      label: _tr('Buyer company', '업체명'),
                      readOnly: isExistingMode,
                      showFill: false,
                      helperText: isExistingMode
                          ? _tr(
                              'Use search to select an existing company.',
                              '기존 업체는 검색 버튼으로 선택하세요.',
                            )
                          : null,
                    ),
                    style: _readOnlyTextStyle(
                      isExistingMode,
                      applyStyle: false,
                    ),
                    readOnly: isExistingMode,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? _tr('Enter company', '업체명을 입력하세요')
                        : null,
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
            if (!isExistingMode) ...[
              const SizedBox(height: 6),
              Text(
                _tr(
                  'New company: you will be registered as owner.',
                  '신규 회사: 신청자가 대표(Owner)로 등록됩니다.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                _tr(
                  'Existing company: access after owner/manager approval.',
                  '기존 회사: 대표/관리자 승인 후 이용 가능합니다.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerAddressCtrl,
              enabled: !isExistingMode,
              readOnly: isExistingMode,
              style: _readOnlyTextStyle(isExistingMode),
              decoration: _readOnlyInputDecoration(
                label: _tr('Buyer address', '주소'),
                readOnly: isExistingMode,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr('Enter address', '주소를 입력하세요')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerPhoneCtrl,
              enabled: !isExistingMode,
              readOnly: isExistingMode,
              style: _readOnlyTextStyle(isExistingMode),
              decoration: _readOnlyInputDecoration(
                label: _tr('Buyer phone', '대표번호'),
                readOnly: isExistingMode,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr('Enter phone', '전화번호를 입력하세요')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerSegmentCtrl,
              enabled: isNewBuyerCompany,
              readOnly: isExistingMode,
              style: _readOnlyTextStyle(isExistingMode),
              decoration: _readOnlyInputDecoration(
                label: _tr('Buyer segment', '업체 분류'),
                readOnly: isExistingMode,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerNameCtrl,
              decoration: InputDecoration(labelText: _tr('Your name', '이름')),
              validator: (v) => v == null || v.trim().isEmpty
                  ? _tr('Enter your name', '이름을 입력하세요')
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: buyerEmailCtrl,
                    decoration: InputDecoration(labelText: _tr('Email', '이메일')),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => onEmailChanged(),
                    validator: (v) => v == null || v.isEmpty
                        ? _tr('Enter email', '이메일을 입력하세요')
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onCheckEmail,
                  child: Text(_tr('Check', '중복 확인')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              emailChecked
                  ? (emailAvailable
                        ? _tr('Email is available', '사용 가능한 이메일입니다.')
                        : _tr('Email already exists', '이미 등록된 이메일입니다.'))
                  : _tr('Check email to enable submit', '중복 확인을 완료하세요.'),
              style: (bodySmall ?? const TextStyle()).copyWith(
                color: emailChecked
                    ? (emailAvailable ? colorScheme.primary : colorScheme.error)
                    : neutralColor,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerPwCtrl,
              decoration: InputDecoration(
                labelText: _tr('Password (login)', '로그인 비밀번호'),
              ),
              obscureText: true,
              validator: (v) => v == null || v.isEmpty
                  ? _tr('Enter password', '비밀번호를 입력하세요')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: buyerPwConfirmCtrl,
              decoration: InputDecoration(
                labelText: _tr('Confirm password', '비밀번호 확인'),
              ),
              obscureText: true,
              validator: (v) => v != buyerPwCtrl.text
                  ? _tr('Passwords do not match', '비밀번호가 일치하지 않습니다')
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
                        labelText: _tr('Target seller name', '도매 업체명'),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? _tr('Select seller company', '도매 업체를 선택하세요')
                          : null,
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
                  labelText: _tr('Attachment URL (optional)', '첨부파일 URL (선택)'),
                  helperText: _tr(
                    'Attach your business license if the seller requires it.',
                    '도매업체가 요청한 경우 사업자등록증 등을 첨부하세요.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (selectedSeller.isNotEmpty)
                Text(
                  '${_tr('Seller', '도매업체')}: ${selectedSeller['name']} / ${selectedSeller['phone']} / ${selectedSeller['address']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _readOnlyInputDecoration({
    required String label,
    required bool readOnly,
    String? helperText,
    bool showFill = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fillAlpha = theme.brightness == Brightness.dark ? 0.35 : 0.2;
    final fillColor = colorScheme.surfaceContainerHighest.withValues(
      alpha: fillAlpha,
    );
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      filled: readOnly && showFill,
      fillColor: readOnly && showFill ? fillColor : null,
    );
  }

  TextStyle? _readOnlyTextStyle(bool readOnly, {bool applyStyle = true}) {
    if (!readOnly || !applyStyle) return null;
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    return base.copyWith(color: color);
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
  context.read<NotificationTicker>().push(message);
}
