// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'VendorJet';

  @override
  String get homeTitle => '대시보드';

  @override
  String get ordersTitle => '주문';

  @override
  String get productsTitle => '상품';

  @override
  String get settingsTitle => '설정';

  @override
  String get welcome => '환영합니다';

  @override
  String get subtitle => '도매 주문 관리';

  @override
  String get language => '언어';

  @override
  String get selectLanguage => '언어를 선택하세요';

  @override
  String get english => '영어';

  @override
  String get korean => '한국어';

  @override
  String get signInTitle => '로그인';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get continueLabel => '계속';

  @override
  String get or => '또는';

  @override
  String get signOut => '로그아웃';
}
