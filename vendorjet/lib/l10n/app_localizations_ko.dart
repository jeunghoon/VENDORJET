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
  String get appTooNarrowTitle => '창 너비를 늘려 주세요';

  @override
  String appTooNarrowMessage(int pixels) {
    return 'VendorJet은 최소 ${pixels}px 이상에서 최적화됩니다. 창을 확장하거나 최대화해 주세요.';
  }

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
  String get orderUpdateNote => '업데이트 메모';

  @override
  String get orderBuyerSectionTitle => '구매자 정보';

  @override
  String get orderBuyerName => '매장명';

  @override
  String get orderBuyerContact => '담당자';

  @override
  String get orderBuyerNote => '구매자 메모';

  @override
  String get orderBuyerUnknown => '제공되지 않음';

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
  String get dashboardMonthlySales => '월간 매출';

  @override
  String get dashboardReceivables => '미수금';

  @override
  String get dashboardReturns => '반품';

  @override
  String get dashboardIncomingShipments => '입고 예정';

  @override
  String get dashboardExpiringProducts => '유통기한 임박';

  @override
  String get dashboardTopProducts => '매출 상위 상품';

  @override
  String get dashboardTopCustomers => '매출 상위 거래처';

  @override
  String get dashboardStaffStatus => '직원 상태';

  @override
  String get dashboardStaffOnDuty => '근무 중';

  @override
  String get dashboardStaffOnLeave => '휴가';

  @override
  String get dashboardStaffOnSick => '병가';

  @override
  String get dashboardEtaLabel => '도착예정';

  @override
  String dashboardDaysLeft(int days) {
    return '$days일 남음';
  }

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
  String get notProvided => '미입력';

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
  String get productTradeSectionTitle => '무역·물류 정보';

  @override
  String get productIncoterm => '인코텀즈';

  @override
  String get productHsCode => 'HS 코드';

  @override
  String get productOriginCountry => '원산지';

  @override
  String get productUom => '단위';

  @override
  String get productPerishable => '유통기한 관리';

  @override
  String get productPerishableYes => '신선/유통기한 관리';

  @override
  String get productPerishableNo => '일반 상품';

  @override
  String get productPackagingSectionTitle => '포장·물류 스펙';

  @override
  String get productPackagingType => '포장 단위';

  @override
  String get productPackagingDimensions => '포장 규격(㎝)';

  @override
  String get productPackagingWeight => '중량(순/총)';

  @override
  String get productPackagingUnitsPerPack => '묶음당 수량';

  @override
  String get productPackagingCbm => '부피(CBM)';

  @override
  String get productTradeTermSectionTitle => '거래조건/가격';

  @override
  String get productTradePrice => '조건가';

  @override
  String get productTradeFreight => '운임';

  @override
  String get productTradeInsurance => '보험';

  @override
  String get productTradeLeadTime => '리드타임';

  @override
  String get productTradeMoq => '최소 주문(MOQ)';

  @override
  String get productEtaSectionTitle => '선적/도착(ETD/ETA)';

  @override
  String get productEtaEtd => 'ETD';

  @override
  String get productEtaEta => 'ETA';

  @override
  String get productEtaVessel => '선박/항차';

  @override
  String get productEtaStatus => '상태';

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
  String get signUpButtonLabel => '회원가입';

  @override
  String get signUpTabSeller => '판매자';

  @override
  String get signUpTabBuyer => '구매자';

  @override
  String get signUpModeNew => '신규 회사';

  @override
  String get signUpModeExisting => '기존 회사';

  @override
  String get signUpSearchCompany => '회사 검색';

  @override
  String get signUpSearchBuyerCompany => '구매자 회사 검색';

  @override
  String get signUpSearchSellerCompany => '판매자 회사 검색';

  @override
  String get signUpSearchByName => '이름으로 검색';

  @override
  String get signUpCompanyNameLabel => '회사명';

  @override
  String get signUpCompanyNameHint => '회사명을 입력하세요';

  @override
  String get signUpCompanyPhoneLabel => '회사 전화번호';

  @override
  String get signUpCompanyPhoneHint => '전화번호를 입력하세요';

  @override
  String get signUpCompanyAddressLabel => '회사 주소';

  @override
  String get signUpCompanyAddressHint => '주소를 입력하세요';

  @override
  String get signUpUserNameLabel => '담당자 이름';

  @override
  String get signUpUserNameHint => '담당자 이름을 입력하세요';

  @override
  String get signUpUserPhoneLabel => '담당자 전화번호';

  @override
  String get signUpUserPhoneHint => '담당자 전화번호를 입력하세요';

  @override
  String get signUpEmailHint => '이메일을 입력하세요';

  @override
  String get signUpPasswordLabel => '비밀번호';

  @override
  String get signUpPasswordHint => '최소 6자 이상 입력하세요';

  @override
  String get signUpSellerNewHint => '신규 회사: 소유자(Owner) 권한으로 등록됩니다.';

  @override
  String get signUpSellerExistingHint => '기존 회사: 소유자/관리자 승인 후 접근할 수 있습니다.';

  @override
  String get signUpBuyerCompanyLabel => '구매자 회사';

  @override
  String get signUpBuyerCompanyHint => '구매자 회사를 입력하세요';

  @override
  String get signUpBuyerAddressLabel => '구매자 주소';

  @override
  String get signUpBuyerPhoneLabel => '구매자 전화번호';

  @override
  String get signUpBuyerSegmentLabel => '업종 분류';

  @override
  String get signUpBuyerSegmentHint => '업종을 입력하세요';

  @override
  String get signUpLoginPasswordLabel => '로그인 비밀번호';

  @override
  String get signUpLoginPasswordHint => '비밀번호를 입력하세요';

  @override
  String get signUpSellerTargetLabel => '연결할 판매자 회사명';

  @override
  String get signUpAttachmentLabel => '첨부 링크(선택)';

  @override
  String get signUpAttachmentHelper => '판매자가 요구할 경우 사업자등록증 등을 첨부하세요(선택)';

  @override
  String get signUpSellerSummary => '판매자';

  @override
  String get signUpBuyerApprovalHint => '판매자 승인 후 상품을 열람할 수 있습니다.';

  @override
  String get signUpSubmitAction => '제출';

  @override
  String get signUpSubmitSuccess => '제출되었습니다(승인이 필요할 수 있음)';

  @override
  String get signUpSubmitFailure => '가입에 실패했습니다';

  @override
  String get signUpSelectSellerPrompt => '먼저 판매자 회사를 선택하세요';

  @override
  String get signUpSelectExistingPrompt => '기존 회사를 선택하세요';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSearch => '검색';

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
  String get roleOwner => '대표';

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
  String get ordersChangeStatus => '상태 변경';

  @override
  String get ordersStatusUpdated => '상태가 업데이트되었습니다.';

  @override
  String get ordersFormCode => '주문 코드';

  @override
  String get ordersFormItems => '품목 수';

  @override
  String get ordersFormTotal => '주문 금액';

  @override
  String get ordersFormDate => '주문 날짜';

  @override
  String get ordersFormBuyerName => '매장명';

  @override
  String get ordersFormBuyerContact => '구매 담당자';

  @override
  String get ordersFormBuyerNote => '구매자 메모';

  @override
  String get ordersFormBuyerNoteHint => '판매자에게 공유될 선택 메모입니다.';

  @override
  String get ordersFormBuyerLockedHint => '구매자가 작성한 정보로 판매자가 수정할 수 없습니다.';

  @override
  String get ordersFormQuantityLockedHint => '상품에서 자동 계산됩니다.';

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

  @override
  String get customersTitle => '고객';

  @override
  String get customersSearchHint => '고객 검색';

  @override
  String get customersFilterAll => '전체 등급';

  @override
  String get customersTierPlatinum => '플래티넘';

  @override
  String get customersTierGold => '골드';

  @override
  String get customersTierSilver => '실버';

  @override
  String get customersCreate => '고객 추가';

  @override
  String get customersEdit => '고객 편집';

  @override
  String get customersDelete => '고객 삭제';

  @override
  String customersDeleteConfirm(String name) {
    return '$name 고객을 삭제할까요?';
  }

  @override
  String get customersCreated => '고객이 생성되었습니다.';

  @override
  String get customersUpdated => '고객이 업데이트되었습니다.';

  @override
  String get customersDeleted => '고객이 삭제되었습니다.';

  @override
  String get customersFormName => '업체명';

  @override
  String get customersFormContact => '담당자';

  @override
  String get customersFormEmail => '이메일';

  @override
  String get customersFormTier => '등급';

  @override
  String get customersFormSegment => '고객 분류';

  @override
  String get customersEmptyMessage => '등록된 고객이 없습니다.';

  @override
  String customersEmptyFiltered(String tier) {
    return '$tier 고객이 없습니다.';
  }

  @override
  String get customersManageSegments => '분류 관리';

  @override
  String get customersSegmentFilterAll => '전체 분류';

  @override
  String get customersSegmentNone => '분류 없음';

  @override
  String get customersNoSegmentsHint => '식당·호텔·마트 등 분류를 추가해 관리하세요.';

  @override
  String get customersSegmentManagerTitle => '고객 분류';

  @override
  String get customersSegmentManagerDescription => '거래처 유형을 추가하거나 수정합니다.';

  @override
  String get customerWithdrawnLabel => '탈퇴한 회원';

  @override
  String get ordersFilterToday => '오늘';

  @override
  String get ordersFilterOpen => '진행 중';

  @override
  String get ordersCodeAutoHint => '저장 시 자동으로 생성됩니다.';

  @override
  String get productsLowStockFilter => '재고 부족만 보기';

  @override
  String get productsXlsxUpload => '.xlsx 업로드';

  @override
  String get productsXlsxNoData => '선택한 파일에 데이터가 없습니다.';

  @override
  String productsXlsxImported(int success, int processed) {
    return '$processed개 중 $success개가 반영되었습니다(모의).';
  }

  @override
  String get productsManageCategories => '카테고리 관리';

  @override
  String get productCategoryUnassigned => '카테고리 미지정';

  @override
  String get productCategoryNone => '없음';

  @override
  String get productCategoriesManageHint =>
      '다른 카테고리가 필요하면 시트를 닫고 ‘카테고리 관리’를 열어 추가하세요.';

  @override
  String get productTagFeatured => '이벤트';

  @override
  String get productTagDiscounted => '할인';

  @override
  String get productTagNew => '신제품';

  @override
  String productCategoryLevel(int level) {
    return '카테고리 $level단계';
  }

  @override
  String get productCategoryLevelRequired => '최소 한 단계 이상의 카테고리를 입력하세요.';

  @override
  String get productSettingsCategories => '카테고리 구조';

  @override
  String get productTagsSection => '상품 플래그';

  @override
  String get productTabOverview => '정보';

  @override
  String get productTabSettings => '설정';

  @override
  String get categoryManagerTitle => '카테고리 라이브러리';

  @override
  String get categoryManagerDescription => '상품에서 재사용할 1~3단계 카테고리를 추가/편집합니다.';

  @override
  String get categoryManagerAdd => '카테고리 추가';

  @override
  String get categoryManagerUpdate => '카테고리 수정';

  @override
  String get categoryManagerCancel => '편집 취소';

  @override
  String get categoryManagerDelete => '삭제';

  @override
  String categoryManagerDeleteConfirm(String path) {
    return '$path을(를) 삭제할까요?';
  }

  @override
  String get categoryManagerSaved => '카테고리를 저장했습니다.';

  @override
  String get categoryManagerDeleted => '카테고리를 삭제했습니다.';

  @override
  String get categoryManagerEmpty => '등록된 카테고리가 없습니다.';

  @override
  String get categoryManagerPrimaryRequired => '최소 1단계 카테고리를 입력하세요.';

  @override
  String get buyerPortalTitle => '구매처 포털';

  @override
  String get buyerPortalTabDashboard => '대시보드';

  @override
  String get buyerPortalTabCatalog => '카탈로그';

  @override
  String get buyerPortalTabOrder => '주문서';

  @override
  String get buyerPendingTitle => '도매 업체 승인 대기 중입니다';

  @override
  String get buyerPendingMessage => '담당 도매 업체에서 승인을 완료하면 상품 조회와 주문이 가능합니다.';

  @override
  String buyerPendingSeller(String sellerName) {
    return '$sellerName에서 승인 대기 중입니다.';
  }

  @override
  String get buyerMenuProfile => '개인 설정';

  @override
  String get buyerMenuSettings => '설정';

  @override
  String get buyerMenuLogout => '로그아웃';

  @override
  String get profileTitle => '개인 설정';

  @override
  String get profileSectionPersonal => '계정 정보';

  @override
  String get profileFieldName => '이름';

  @override
  String get profileFieldEmail => '이메일';

  @override
  String get profileFieldPhone => '전화번호';

  @override
  String get profileFieldPasswordNew => '새 비밀번호(선택)';

  @override
  String get profileFieldPasswordConfirm => '새 비밀번호 확인';

  @override
  String get profileSave => '저장';

  @override
  String get profileDelete => '계정 탈퇴';

  @override
  String get profileDeleteTitle => '계정 탈퇴';

  @override
  String get profileDeleteConfirm => '삭제 후 되돌리지 않습니다. 계정을 삭제할까요?';

  @override
  String get profilePasswordMismatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get profileSaveSuccess => '개인 설정을 저장했습니다.';

  @override
  String get profileSaveFailure => '개인 설정을 저장하지 못했습니다.';

  @override
  String get settingsProfileTitle => '프로필 및 개인 정보';

  @override
  String get settingsProfileSubtitle => '로그인, 연락처, 비밀번호를 관리합니다';

  @override
  String get buyerSettingsSectionTitle => '매장 설정';

  @override
  String get buyerSettingsCompanyFallback => '등록된 매장이 없습니다';

  @override
  String get buyerSettingsCompanyMissing => '저장된 매장 정보가 없습니다';

  @override
  String get settingsMembersSectionTitle => '구성원';

  @override
  String get settingsMembersSelfBadge => '나';

  @override
  String get settingsMembersRoleLabel => '역할';

  @override
  String get settingsMembersOwnerHint => '대표만 역할을 변경할 수 있습니다.';

  @override
  String get settingsMembersUpdateSuccess => '구성원 역할을 변경했습니다.';

  @override
  String get settingsMembersUpdateError => '구성원 역할을 변경하지 못했습니다.';

  @override
  String get settingsMembersPositionLabel => '직책';

  @override
  String get settingsMembersPositionNone => '미지정';

  @override
  String get settingsMembersPositionSaved => '직책을 저장했습니다.';

  @override
  String settingsPositionsSectionTitle(Object tenant) {
    return '$tenant · 직책';
  }

  @override
  String get settingsPositionsEmpty => '등록된 직책이 없습니다.';

  @override
  String get settingsPositionsAdd => '직책 추가';

  @override
  String get settingsPositionsEdit => '직책 수정';

  @override
  String get settingsPositionsDelete => '직책 삭제';

  @override
  String settingsPositionsDeleteConfirm(Object title) {
    return '\"$title\" 직책을 삭제할까요? 해당 구성원은 미지정으로 전환됩니다.';
  }

  @override
  String get settingsPositionsFieldLabel => '직책 이름';

  @override
  String get settingsPositionsRequired => '직책 이름을 입력하세요.';

  @override
  String get settingsPositionsSave => '저장';

  @override
  String get settingsPositionsSaved => '직책을 저장했습니다.';

  @override
  String get settingsPositionsDeleted => '직책을 삭제했습니다.';

  @override
  String get buyerSettingsConnectionsTitle => '연결된 도매업체';

  @override
  String get buyerSettingsNoConnections => '활성화된 도매 연결이 없습니다.';

  @override
  String get buyerSettingsPendingTitle => '대기 중 요청';

  @override
  String get buyerSettingsPendingLoading => '요청 상태를 불러오는 중...';

  @override
  String get buyerSettingsPendingNone => '대기 중인 연결 요청이 없습니다.';

  @override
  String buyerSettingsPendingWithSeller(Object seller) {
    return '$seller 승인 대기 중';
  }

  @override
  String get buyerSettingsRequestButton => '새 연결 요청';

  @override
  String get buyerSettingsRequestOwnerOnly => '소유자만 새 도매 연결을 요청할 수 있습니다.';

  @override
  String get buyerSettingsSheetTitle => '도매 연결 요청';

  @override
  String get buyerSettingsSellerFieldLabel => '연결할 도매업체';

  @override
  String get buyerSettingsSearchSeller => '도매업체 검색';

  @override
  String get buyerSettingsSearchAction => '검색';

  @override
  String get buyerSettingsSearchFieldLabel => '업체명으로 검색';

  @override
  String buyerSettingsSellerSummary(Object phone, Object address) {
    return '전화: $phone · 주소: $address';
  }

  @override
  String get buyerSettingsBuyerFieldLabel => '매장명';

  @override
  String get buyerSettingsBuyerAddressLabel => '매장 주소';

  @override
  String get buyerSettingsBuyerSegmentLabel => '업태/분류';

  @override
  String get buyerSettingsContactNameLabel => '담당자 이름';

  @override
  String get buyerSettingsContactPhoneLabel => '담당자 연락처';

  @override
  String get buyerSettingsAttachmentLabel => '첨부 URL(선택)';

  @override
  String get buyerSettingsRequiredField => '필수 입력 항목입니다.';

  @override
  String get buyerSettingsSubmit => '요청 보내기';

  @override
  String buyerSettingsRequestSuccess(Object seller) {
    return '$seller에 요청을 전송했습니다';
  }

  @override
  String buyerSettingsRequestAlreadyPending(Object seller) {
    return '$seller 승인 대기 중입니다.';
  }

  @override
  String buyerSettingsRequestAlreadyConnected(Object seller) {
    return '$seller와 이미 연결되어 있습니다.';
  }

  @override
  String get buyerSettingsActiveSellerTitle => '활성 도매업체';

  @override
  String get buyerSettingsActiveSellerHint => '카탈로그와 주문에 사용할 도매업체를 선택하세요.';

  @override
  String buyerSettingsActiveSellerSaved(Object seller) {
    return '$seller로 전환했습니다.';
  }

  @override
  String get buyerSettingsConnectionsSwitchAction => '이 도매업체 사용';

  @override
  String get buyerSettingsConnectionsActiveLabel => '현재 사용 중';

  @override
  String get buyerCatalogConnectHint => '설정에서 도매업체와 연결하면 카탈로그를 볼 수 있습니다.';

  @override
  String buyerCatalogPendingMessage(Object seller) {
    return '$seller이(가) 요청을 검토 중입니다. 승인되면 접근이 열립니다.';
  }

  @override
  String get buyerOrderConnectHint => '도매업체와 연결하면 주문을 작성할 수 있습니다.';

  @override
  String buyerOrderPendingMessage(Object seller) {
    return '$seller이(가) 주문 요청을 검토 중입니다. 승인 후 주문이 가능합니다.';
  }

  @override
  String get settingsCompanyInfoTitle => '업체 정보';

  @override
  String get settingsCompanyRepresentativeLabel => '대표자';

  @override
  String get settingsCompanyPhoneLabel => '대표번호';

  @override
  String get settingsCompanyAddressLabel => '주소';

  @override
  String get settingsCompanyRoleLabel => '내 역할';

  @override
  String get settingsCompanyPrimaryBadge => '기본 업체';

  @override
  String get settingsCompanySetPrimary => '기본 업체로 지정';

  @override
  String get settingsStoreCurrentLabel => '현재 선택된 매장';

  @override
  String get settingsStoreSwitchAction => '이 매장으로 전환';

  @override
  String get settingsCompanyPrimarySaved => '기본 업체를 변경했습니다.';

  @override
  String get settingsCompanyPrimaryRequired =>
      '기본 매장을 지정하면 주문서 기본값으로 사용할 수 있습니다.';

  @override
  String get settingsCompanyEditAction => '편집';

  @override
  String get settingsCompanyDeleteAction => '삭제';

  @override
  String settingsCompanyDeleteConfirm(Object name) {
    return '$name 업체를 삭제할까요? 연결된 매장 정보가 제거됩니다.';
  }

  @override
  String get settingsCompanyAddButton => '업체 추가';

  @override
  String get settingsCompanyFormTitleAdd => '업체 추가';

  @override
  String get settingsCompanyFormTitleEdit => '업체 수정';

  @override
  String get settingsCompanyFormSave => '업체 저장';

  @override
  String get settingsCompanyFormNameLabel => '업체명';

  @override
  String get settingsCompanyFormRepresentativeLabel => '대표자';

  @override
  String get settingsCompanyFormPhoneLabel => '대표번호';

  @override
  String get settingsCompanyFormAddressLabel => '주소';

  @override
  String get settingsCompanyFormNameRequired => '업체명을 입력하세요.';

  @override
  String get settingsCompanyFormSaved => '업체 정보를 저장했습니다.';

  @override
  String get settingsCompanyFormSaveError => '업체 정보를 저장하지 못했습니다.';

  @override
  String get settingsCompanyFormDeleteSuccess => '업체를 삭제했습니다.';

  @override
  String get settingsCompanyFormDeleteError => '업체를 삭제하지 못했습니다.';

  @override
  String get settingsLanguageSaved => '언어 설정을 저장했습니다.';

  @override
  String get settingsLanguageApplyHint => '다음 로그인 시 자동으로 적용됩니다.';

  @override
  String get buyerPreviewTitle => '구매자 미리보기';

  @override
  String get buyerPreviewSubtitle => '소매상 화면에서 상품 탐색과 주문을 테스트합니다.';

  @override
  String get buyerCatalogSearchHint => '상품 검색';

  @override
  String get buyerCatalogEmptyHint => '조건에 맞는 상품이 없습니다.';

  @override
  String buyerCatalogPrice(String price) {
    return '₩ $price / 단위';
  }

  @override
  String get buyerCatalogAdd => '장바구니 담기';

  @override
  String buyerCatalogAddWithQty(String count) {
    return '$count 장바구니 담기';
  }

  @override
  String buyerCatalogAdded(String name) {
    return '$name을(를) 장바구니에 담았습니다.';
  }

  @override
  String buyerCartSummary(int count) {
    return '$count개';
  }

  @override
  String get buyerCartEmpty => '장바구니가 비었습니다';

  @override
  String get buyerCartEmptyHint => '카탈로그에서 상품을 추가하세요.';

  @override
  String buyerCartLineTotal(String amount) {
    return '₩ $amount';
  }

  @override
  String get buyerCartRemove => '제거';

  @override
  String buyerCartTotal(String amount) {
    return '소계: ₩ $amount';
  }

  @override
  String get buyerCartClear => '장바구니 비우기';

  @override
  String get buyerCartProceed => '주문서로 이동';

  @override
  String get buyerDeliveryDateLabel => '희망 배송일';

  @override
  String get buyerDeliveryDatePick => '배송 날짜 선택';

  @override
  String get buyerDeliveryDateEdit => '변경';

  @override
  String buyerOrderSummary(int uniqueCount, int totalCount) {
    return '$uniqueCount개 품목 : 총수량 $totalCount';
  }

  @override
  String get buyerDashboardGreeting => '최근 주문 내역을 기반으로 빠르게 재주문하세요.';

  @override
  String get buyerDashboardMetricTotalOrdersLabel => '총 주문 건수';

  @override
  String get buyerDashboardMetricMonthlySpendLabel => '이번 달 주문액';

  @override
  String get buyerDashboardMetricLastOrderLabel => '마지막 주문';

  @override
  String get buyerDashboardMetricTopStoreLabel => '주문이 많은 매장';

  @override
  String get buyerDashboardMetricEmptyValue => '없음';

  @override
  String get buyerDashboardHistoryTitle => '지난 주문 내역';

  @override
  String get buyerDashboardHistoryEmpty => '아직 주문 내역이 없습니다';

  @override
  String get buyerDashboardHistoryEmptyHint => '첫 주문을 제출하면 이곳에서 바로 불러올 수 있습니다.';

  @override
  String get buyerDashboardHistoryLoad => '주문서로 불러오기';

  @override
  String buyerDashboardLoaded(String label) {
    return '$label 주문을 주문서로 불러왔습니다.';
  }

  @override
  String buyerCheckoutItems(int count) {
    return '$count개 품목';
  }

  @override
  String get buyerCheckoutStore => '매장명';

  @override
  String get buyerCheckoutContact => '구매 담당자';

  @override
  String get buyerCheckoutNote => '구매자 메모';

  @override
  String get buyerCheckoutNoteHint => '판매자에게 전달할 선택 메모';

  @override
  String get buyerCheckoutSubmit => '주문 제출';

  @override
  String get buyerCheckoutCartEmpty => '먼저 장바구니에 상품을 추가하세요.';

  @override
  String buyerCheckoutSuccess(String code) {
    return '주문이 접수되었습니다. 코드 $code';
  }

  @override
  String get buyerOrderEmptyHint => '폼을 작성하기 전에 카탈로그에서 품목을 담아주세요.';

  @override
  String get buyerOrderBrowseCatalog => '카탈로그 보기';

  @override
  String get buyerOrderPrefillMissing => '이 주문에는 품목 정보가 없어 복사할 수 없습니다.';

  @override
  String get buyerOrderStoreEmptyHint => '등록한 매장을 선택해 주세요.';

  @override
  String buyerOrderStoreLoadError(String error) {
    return '매장 목록을 불러오지 못했습니다: $error';
  }

  @override
  String get settingsPositionsTierLabel => '직책 그룹';

  @override
  String get settingsPositionsTierOwner => '대표';

  @override
  String get settingsPositionsTierManager => '관리자';

  @override
  String get settingsPositionsTierStaff => '직원';

  @override
  String get settingsPositionsLockedBadge => '기본';

  @override
  String get settingsPositionsHierarchyHint =>
      '권한은 대표 → 관리자 → 직원 → 미승인 순으로 내려갑니다.';

  @override
  String get settingsPositionsTierPending => '미승인';
}
