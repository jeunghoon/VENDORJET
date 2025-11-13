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

  @override
  String get edit => '편집';

  @override
  String get editComingSoon => '편집 기능은 곧 제공될 예정입니다.';

  @override
  String get invalidCredentials => '유효하지 않은 로그인 정보입니다';

  @override
  String get ordersSearchHint => '주문 검색';

  @override
  String get productsSearchHint => '상품 검색';

  @override
  String get ordersDetailTitle => '주문 상세';

  @override
  String get orderPlacedOn => '주문 일자';

  @override
  String get orderTotal => '주문 금액';

  @override
  String get orderItems => '품목 내역';

  @override
  String get orderMetaTitle => '주문 메타데이터';

  @override
  String get orderMetaPlannedShip => '예정 출고일';

  @override
  String get orderMetaLastUpdated => '최종 업데이트';

  @override
  String get orderMetaOwner => '담당자';

  @override
  String get orderMetaNote => '내부 메모';

  @override
  String get orderEditTitle => '주문 편집';

  @override
  String get orderEditStatusLabel => '주문 상태';

  @override
  String get orderEditPlannedShip => '예정 출고일';

  @override
  String get orderEditNote => '내부 메모';

  @override
  String get orderEditNoteHint => '팀 메모를 입력하세요';

  @override
  String get orderEditSave => '저장';

  @override
  String get orderEditCancel => '취소';

  @override
  String get orderEditSaved => '주문이 업데이트되었습니다.';

  @override
  String get dashboardTodayOrders => '오늘 주문';

  @override
  String get dashboardOpenOrders => '진행 중 주문';

  @override
  String get dashboardLowStock => '재고 부족';

  @override
  String get dashboardPreviewSubtitle => '레이아웃 미리보기 항목';

  @override
  String get dashboardRecentOrders => '최근 주문';

  @override
  String get dashboardRecentOrdersEmpty => '표시할 최근 주문이 없습니다.';

  @override
  String get ordersEmptyMessage => '주문을 찾을 수 없습니다.';

  @override
  String ordersEmptyFiltered(String status) {
    return '$status 주문이 없습니다.';
  }

  @override
  String get productsEmptyMessage => '상품을 찾을 수 없습니다.';

  @override
  String productsEmptyFiltered(String category) {
    return '$category 분류에 해당하는 상품이 없습니다.';
  }

  @override
  String get stateErrorMessage => '문제가 발생했습니다.';

  @override
  String get stateRetry => '다시 시도';

  @override
  String get ordersFilterAll => '전체';

  @override
  String get ordersStatusPending => '대기';

  @override
  String get ordersStatusConfirmed => '확정';

  @override
  String get ordersStatusShipped => '출고';

  @override
  String get ordersStatusCompleted => '완료';

  @override
  String get ordersStatusCanceled => '취소';

  @override
  String get ordersStatusReturned => '반품';

  @override
  String get ordersStatusLabel => '주문 상태';

  @override
  String get productsFilterAll => '전체';

  @override
  String get productsCategoryBeverages => '음료';

  @override
  String get productsCategorySnacks => '스낵';

  @override
  String get productsCategoryHousehold => '생활용품';

  @override
  String get productsCategoryFashion => '패션';

  @override
  String get productsCategoryElectronics => '전자제품';

  @override
  String get productLowStockTag => '재고 부족';

  @override
  String orderListSubtitle(int count, String total) {
    return '$count개 품목 · $total';
  }

  @override
  String orderLinePlaceholder(int position) {
    return '샘플 품목 $position번';
  }

  @override
  String get notFound => '내용을 찾을 수 없습니다';

  @override
  String get productsDetailTitle => '상품 상세';

  @override
  String get productSku => 'SKU';

  @override
  String get productPrice => '기준 단가';

  @override
  String get productVariants => '옵션 수';

  @override
  String get productHighlights => '주요 정보';

  @override
  String get productMetaTitle => '재고 및 속성';

  @override
  String get productMetaCategory => '카테고리';

  @override
  String get productMetaStockLow => '재고 부족';

  @override
  String get productMetaStockHealthy => '재고 양호';

  @override
  String get productMetaLastSync => '재고 동기화';

  @override
  String productCardSummary(String name, int count) {
    return '$name · 옵션 $count개';
  }

  @override
  String get productAvailabilityInStock => '재고 보유';

  @override
  String get productAvailabilityLowStock => '재고 부족';

  @override
  String get productAvailabilityBackordered => '백오더 진행';

  @override
  String get productLeadTimeSameDay => '당일 출고';

  @override
  String get productLeadTimeTwoDays => '2일 내 출고';

  @override
  String get productLeadTimeWeek => '1주 이내 출고';

  @override
  String get productBadgeBestseller => '베스트셀러';

  @override
  String get productBadgeNew => '신상품';

  @override
  String get productBadgeSeasonal => '시즌 추천';

  @override
  String get productHighlightAvailabilityNote => '오늘 기준 재고 동기화 완료.';

  @override
  String get productHighlightLeadTimeNote => '도매 주문 기본 리드타임입니다.';

  @override
  String get productHighlightBadgeNote => '상위 파트너에게 노출 중입니다.';

  @override
  String get productEditTitle => '상품 편집';

  @override
  String get productEditName => '상품명';

  @override
  String get productEditPrice => '단가';

  @override
  String get productEditVariants => '버전 수';

  @override
  String get productEditCategory => '카테고리';

  @override
  String get productEditLowStock => '저재고 표시';

  @override
  String get productEditSave => '저장';

  @override
  String get productEditCancel => '취소';

  @override
  String get productEditSaved => '상품 정보가 업데이트되었어요.';

  @override
  String get productEditNameRequired => '상품명을 입력하세요.';

  @override
  String get productEditPriceInvalid => '유효한 가격을 입력하세요.';

  @override
  String get productEditVariantsInvalid => '1 이상의 버전 수를 입력하세요.';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get registerVendor => '도매 계정 만들기';

  @override
  String get tenantName => '업체명';

  @override
  String get passwordResetSent => '비밀번호 재설정 안내를 전송했습니다(모의).';

  @override
  String get registerSuccess => '계정이 생성되었습니다. 로그인해 주세요.';

  @override
  String get registerFailed => '계정을 생성할 수 없습니다.';

  @override
  String get signInHelperCredentials =>
      '체험용으로 alex@vendorjet.com / welcome1을 입력해 보세요.';

  @override
  String get tenantSectionTitle => '조직';

  @override
  String get tenantRoleLabel => '역할';

  @override
  String get tenantSwitchTitle => '업체 전환';

  @override
  String get tenantSwitchFailed => '이 업체에 접근할 수 없습니다.';

  @override
  String get tenantInviteTitle => '팀원 초대';

  @override
  String get inviteEmailPlaceholder => '팀원 이메일';

  @override
  String get inviteSend => '초대 전송';

  @override
  String get inviteSuccess => '초대가 기록되었습니다(모의).';

  @override
  String get roleOwner => '소유자';

  @override
  String get roleManager => '관리자';

  @override
  String get roleStaff => '직원';

  @override
  String get ordersCreate => '주문 추가';

  @override
  String get ordersEdit => '주문 편집';

  @override
  String get ordersDelete => '주문 삭제';

  @override
  String ordersDeleteConfirm(String code) {
    return '$code 주문을 삭제할까요?';
  }

  @override
  String get ordersCreated => '주문이 생성되었습니다.';

  @override
  String get ordersUpdated => '주문이 업데이트되었습니다.';

  @override
  String get ordersDeleted => '주문이 삭제되었습니다.';

  @override
  String get ordersFormCode => '주문 코드';

  @override
  String get ordersFormItems => '품목 수';

  @override
  String get ordersFormTotal => '주문 금액';

  @override
  String get ordersFormDate => '주문 날짜';

  @override
  String get productsCreate => '상품 추가';

  @override
  String get productsDelete => '상품 삭제';

  @override
  String productsDeleteConfirm(String name) {
    return '$name 상품을 삭제할까요?';
  }

  @override
  String get productsDeleted => '상품이 삭제되었습니다.';

  @override
  String get productsCsvMock => 'CSV 목업 업로드';

  @override
  String productsCsvImported(int success, int processed) {
    return '$processed개 중 $success개가 반영되었습니다(모의).';
  }

  @override
  String get productEditSku => 'SKU';

  @override
  String get productsCreated => '상품이 생성되었습니다.';
}
