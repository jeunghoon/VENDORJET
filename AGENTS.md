# VendorJet 개발 에이전트 가이드 (한국어)

이 파일은 도매-소매 주문 앱(VendorJet)의 개발/배포 전 과정을 계획하고, 코드 스타일과 작업 절차를 정리한 가이드입니다. 이 디렉토리 트리 전체에 적용됩니다.

- 이 문서는 **코드 작성 일지/작업 로그** 역할을 겸한다. 변경 시 날짜를 명시하고 *계획 → 실행 → 결과* 순으로 짧게 기록한다.
- 기본 언어는 **한국어**, 파일 인코딩은 **UTF-8**로 유지한다.
- 에이전트가 코드를 작성하거나 설계를 바꿀 때마다 본 문서에 근거/의도/다음 액션을 반영한다.
- 파일/커밋/주석 작성 시 기존 가이드(UpperCamelCase 등 네이밍, 주석 한글 우선)를 따른다.

## 프로젝트 개요
- 도매업체가 소매업체 주문을 접수·관리하고 구매자 미리보기(BuyerPortal)로 장바구니→주문 플로우를 시뮬레이션할 수 있는 크로스 플랫폼 앱
- 지원 플랫폼: Android / iOS / macOS / Windows / Web(preview)
- 배포 목표: Google Play, App Store(iOS·macOS), Microsoft Store(선택), 패키지명 com.vendorjet.app
- 기본 언어: 영어·한국어 토글, ARB 기반으로 추가 언어 확장 가능

## 기술·설계 요약
- Flutter (stable) + Dart, Material3 테마, Provider(ChangeNotifier) 기반 상태관리
- 라우팅: GoRouter + ShellRoute (Dashboard/Orders/Products/Customers/Settings + Buyer 프리뷰, Profile/Admin 포함)
- API: 로컬 Node/Express + SQLite (server/), Flutter는 ApiClient/ApiAuthService를 통해 REST 호출
- 로컬라이제이션: l10n/ ARB, lutter gen_l10n
- 주요 모듈: Dashboard, Orders, Products, Customers, Settings, Profile, Admin, BuyerPortal

## 코드/문서 규칙
- 주석·문서·커밋 메시지는 한국어 우선, UTF-8
- 명명 규칙: UpperCamelCase(클래스), lowerCamelCase(메서드/변수), snake_case(파일)
- 위젯 분리: 페이지(ui/pages/*) vs 공용 위젯(ui/widgets/*)
- 문자열은 반드시 ARB에 정의 후 AppLocalizations로 접근
- 테마·색상·타이포는 lib/theme/app_theme.dart에서 일괄 관리

## 브랜치/작업 흐름(권장)
- main: 안정 릴리스, develop: 통합 개발, feature/*: 기능 단위 브랜치

## UI/디자인 가이드
- 컬러 팔레트: 파스텔 주황(#F08A4A), 파스텔 하늘(#5AA9E6), 짙은 남색·화이트 배경
- 톤: 심플·세련, 카드형 레이아웃, 충분한 여백, 반응형 컴포넌트(ResponsiveScaffold)
- 모바일은 하단탭, 데스크톱/태블릿은 NavigationRail, NotificationTicker로 글로벌 알림 제공

## BuyerPortal UX 지침
- 장바구니·주문서를 단일 탭으로 통합, 품목 편집과 주문 정보 입력을 한 화면에서 처리
- 매장명은 고객 데이터와 동기화된 드롭다운, 구매 담당자는 로그인 사용자 기본값 사용
- 히스토리 카드에서 “주문서로 불러오기” 시 품목/메모/매장 메타 즉시 복사, “N개 품목 · 총수량 M” 요약 제공
- 앱바 우측에 희망 배송일 선택기, 기본값 익일, 카드와 주문서에 동일 날짜 반영
- DefaultTabController 존재 여부 확인 후 탭 이동, 장바구니 품목 순서 보존
- 관련 구현: lib/ui/pages/buyer/buyer_portal_page.dart, lib/ui/pages/buyer/buyer_cart_controller.dart, lib/repositories/mock_repository.dart

## 기능 로드맵 (앱스토어 등록 가능한 완성본)

1) P0 — 기초 UI 프레임 (완료 기준)
- 앱 스캐폴딩, 테마/내비게이션, i18n(영/한) 적용
- 대시보드/주문/상품/설정 기본 골격 및 더미 데이터

2) P1 — 인증/테넌시
- 이메일+비밀번호 로그인/회원가입, 비밀번호 재설정
- 도매업체 계정(테넌트) 생성/초대/권한(관리자/직원)
- 로컬 Node/Express 인증 흐름을 완성한 뒤, 상용 서버(Firebase/Supabase/자체 백엔드 등) 중 적합한 대상을 비교해 선택

3) P2 — 핵심 도메인
- 상품: 카탈로그(카테고리, 가격, 재고, 옵션), 일괄 업로드(CSV)
- 고객: 소매업체 관리(거래처), 등급/가격규칙
- 주문: 장바구니→주문서 발행→상태 관리(신규/확정/출고/완료/취소)
- 결제(선택): 송장/외부 PG 연동 계획 수립

4) P3 — 운영/품질
- 검색/필터/정렬, 페이지네이션
- 오류/로딩/빈 상태 화면, 접근성(폰트 스케일 대응)
- 다크모드, 앱 아이콘/스플래시, 공용 다이얼로그/토스트
- 분석(Analytics), 크래시(단계적)

5) P4 — 배포 준비
- 번들 ID/패키지명 정리: com.vendorjet.app
- 앱 아이콘/스플래시 이미지 확정 및 적용
- 개인정보 처리방침/이용약관 링크 준비
- 스토어 스크린샷/설명(영/한) 작성

6) P5 — 릴리스/스토어 등록
- Android: lutter build appbundle → Play Console 업로드
- iOS: lutter build ipa(Xcode/맥 필요) → App Store Connect 업로드, 심사 대응
- macOS: lutter build macos + 서명/노터라이즈 → Mac App Store 제출
- Windows: lutter build windows + MSIX 패키징(선택)

## 실행/개발 방법
- Windows/웹에서 빠르게 UI 확인: lutter run -d windows 또는 lutter run -d chrome
- 모바일 장치: lutter devices로 확인 후 lutter run -d <deviceId>
- 핫리로드: 저장 시 즉시 UI 반영

## 배포 체크리스트
- 앱 이름/아이콘 현행화 및 빌드 넘버 증가
- 앱 권한 최소화, 개인정보/서드파티 SDK 점검
- 다국어 번역 확인(영어 기본, 한국어 검수)
- 스토어 정책/가이드라인 준수 여부 확인

## 파일 구조(요약)
- lib/main.dart: 앱 엔트리, 라우팅/로케일 상태
- lib/theme/app_theme.dart: 색상/Material3 테마
- lib/ui/pages/*: 화면 모듈(대시보드/주문/상품/설정)
- lib/ui/widgets/*: 공용 위젯(반응형 스캐폴드 등)
- lib/l10n/*.arb: 다국어 문자열(영/한)

## 테스트/품질(차후 확장)
- 단위 테스트: 도메인 로직 위주
- 위젯 테스트: 중요 UI 플로우(주문 생성 등)
- Lints 준수, 포맷팅 고정

---
본 가이드는 실제 작업 중 업데이트될 수 있습니다. 변경 시 릴리즈 노트에 반영하세요.

## 진행 이력(요약)
- P0 기본 프레임 구축 완료: Material3 테마, 반응형 내비게이션, 다국어 전환, 로그인 플로우 골격 확립
- GoRouter 기반 라우팅 전환 및 주문/상품 상세 라우트·딥링크 정비
- 주문/상품 목록에 상태·카테고리 필터와 공통 상태 뷰(StateMessageView) 도입
- 대시보드 지표·최근 주문 UI 구축 및 DashboardService 계층 분리
- 주문/상품 상세 화면 확장: 편집 액션, 메타데이터 섹션, 내부 메모/재고 정보 표시
- 주문 상태(반품) 추가 및 필터 반영
- 구매자 미리보기 플로우(BuyerPortal) 추가: 카탈로그·장바구니·주문 제출과 판매자 데이터 동기화 시뮬레이션
- 주문 모델/목록/대시보드에 buyerName·buyerContact·buyerNote 노출
- 로컬 API 서버 안정화 및 확장 전략 문서 초안 작성(추후 선택할 배포 서버 비교 포함)
- 회원가입 UX 개선 진행 중: 이메일 중복 확인/비밀번호 확인 로직 추가, 도매·소매 검색 필터 일부 정리, 공용 스낵바 헬퍼(app_snackbar) 도입(전체 교체는 미완료), 기존 업체 선택 시 필드 읽기 전용/회색 처리 작업 일부 적용(추가 정리 필요)
- 코드 재사용성 개선 요구(예정): 회사 검색(도매/소매/글로벌), 알림창, 공통 다이얼로그 등 반복되는 패턴을 공용 함수/위젯으로 모듈화하고, 인수만 받아 호출하는 형태로 단순화 필요(현재는 중복 코드 다수).

## 진행 상황 체크리스트
- [x] Flutter 앱 골격(테마, 라우트, 다국어, 로그인)
- [x] Orders/Products/Customers CRUD + 상세/편집 + 상태 뷰
- [x] Dashboard 지표·최근 주문 카드·딥링크·주문번호 자동 생성
- [x] BuyerPortal 프리뷰(카탈로그·장바구니·주문 제출·재주문 카드)
- [x] Auth/회원가입 UX 개선(이메일 중복, NotificationTicker, 검색/읽기 전용)
- [x] 로컬 API 서버 + seed + docs/local_api.md 문서화
- [x] NotificationTicker, 프로필, 관리자, DataRefreshCoordinator 등 보조 모듈
- [x] 앱 아이콘/스플래시/정책 초안, 라이트·다크 테마 색상 정리

## 이어하기(작업 포인터)
1. **로컬 API 종단 테스트 & 하드닝**
   - server/src/modules/* CRUD/Auth 경로 검증, 오류/토큰 만료/로그 처리 강화
   - Flutter 앱이 주문/상품/고객/BuyerPortal/가입 API를 모두 호출하도록 서비스 레이어 점검
2. **회원가입/권한 고도화**
   - 판매자/구매자 승인 테이블(membership_requests, buyer_requests) 구현, 관리자 승인/알림 UX
   - Seller/Buyer 플로우에 승인 상태·첨부파일·자동 승인 규칙 연결
3. **BuyerPortal v2**
   - 주문 내역 기반 재주문 템플릿, 배송지/메모/희망일 동기화
   - BuyerCartController와 서버 상태 양방향 싱크, 오류/빈 상태/알림 정비
4. **운영/품질 강화**
   - NotificationTicker 메시지 표준화, 에러 핸들링/로깅 개선, 핵심 플로우 테스트 작성
   - CI/빌드 스크립트·스토어 자산(스크린샷/정책) 정비
5. **배포/장기 로드맵**
   - Firebase/Supabase/자체 백엔드 비교 문서화, 상용 전환 전략 수립
   - 앱 권한/정책 검토, 개인정보/약관 확정, 스토어 심사 대비

## 향후 진행 체크리스트
- [x] 로컬 API 기반 CRUD/회원가입 종단 테스트(상품·고객·주문·테넌트)
- [x] 판매자/구매자 구분 회원가입 플로우 구현: 새 회사=소유자 자동 승인, 기존 회사=관리자 승인/알림 설정(관리자만 또는 관리자 이상)
- [x] 구매자 가입/승인 흐름: 구매자 회사+판매자 회사 입력, 첨부파일 업로드 후 판매자 승인 시 거래 가능, 승인 후 판매자 상품 조회
- [ ] 초대/승인 알림/권한 설정: 관리자에게만 또는 관리자 이상 모두에게 알림 옵션 추가
- [ ] BuyerPortal v2: 주문 내역/배송지/템플릿 설계 및 API 연동 리팩터링
- [ ] 코드/이벤트 로그 정비 및 에러 핸들링(토큰 만료, CORS/네트워크 예외)
- [ ] 핵심 플로우 위젯/통합 테스트 시나리오 작성 및 일부 자동화
- [ ] Firestore/Firebase 전환 설계 재정리(필요 시) 및 문서 업데이트

## 작업 로그 (2025-12-04-10)
- 계획: 도매 고객 목록에서 소매업체를 삭제하면 두 회사 간 연결도 함께 끊기도록 처리
- 실행: server/src/modules/customers/controller.ts에서 고객 삭제 후 해당 도매/소매 조합의 uyer_requests 기록과 memberships를 찾아 제거하도록 로직을 확장
- 결과: 도매 관리자가 고객에서 소매업체를 삭제하면 소매 측 membership이 즉시 해제되고 BuyerPortal/권한 상태가 정확히 반영됨

## 작업 로그 (2025-12-04-11)
- 계획: 연결이 끊긴 소매 계정이 설정 화면에서 다시 도매 연결을 요청할 수 있도록 API/클라이언트를 확장
- 실행: server/src/modules/auth/controller.ts에 /auth/buyer/reapply 엔드포인트와 /auth/tenants 타입 정보를 추가하고, ApiAuthService·AuthController에 재신청 메서드를 추가, SettingsPage에 구매자 전용 섹션(연결 현황/대기 상태/연결 요청 시트)을 구현, 라우터에서 구매자도 /settings 접근을 허용, 신규 문자열을 ARB/lutter gen-l10n으로 반영, docs/local_api.md/AGENTS.md를 업데이트
- 결과: 소매 사용자가 설정 → “새 연결 요청”을 통해 다시 원하는 도매업체에 승인 요청을 제출할 수 있고 서버도 중복/권한을 검증하며, 문서와 체크리스트에 최신 진행 내용이 반영됨

## 작업 로그 (2025-12-04-12)
- 계획: 구매자 프로필/설정 화면 진입 시 도매 네비게이션이 보이는 문제를 해결하고, 구매자 네비게이션 컨텍스트 안에서 페이지를 재활용
- 실행: /buyer 라우트에 로케일 정보를 전달하고 BuyerPortalPage에서 프로필/설정을 전용 오버레이 스캐폴드로 띄우도록 수정, SettingsPage에 onProfileTap을 추가해 소매 모드에서도 내부에서 프로필을 모달로 열 수 있게 조정, 새 오버레이 스캐폴드를 도입해 구매자 상단 AppBar를 유지
- 결과: 구매자 메뉴에서 프로필/설정을 열어도 도매 NavigationRail이 나타나지 않고, 상단 탭 네비게이션(또는 백버튼) 컨텍스트를 유지한 상태로 동일한 페이지 콘텐츠를 재사용하게 됨

## 작업 로그 (2025-12-04-13)
- 계획: 도매 연결이 끊긴 기존 소매 회사에 대해 추가 가입을 허용하고, 도매가 승인되면 소속 직원 전체에 연결이 일괄 적용되도록 서버 로직을 수정
- 실행: POST /auth/register-buyer가 기존 소매 업체 등록 시 sellerCompany 없이도 가입할 수 있도록 허용하고, 이 경우 소매 테넌트 멤버십만 생성하도록 수정. PATCH /admin/requests/:id에서 구매자 요청 승인 시 해당 소매 테넌트의 모든 구성원에게 도매 멤버십을 자동 부여하도록 로직을 확장
- 결과: 도매 연결 이전이라도 소매 대표·직원이 가입할 수 있으며, 나중에 도매가 연결되면 동일 업체의 모든 사용자에게 도매 멤버십이 일괄로 적용되어 BuyerPortal 접근 권한이 맞춰짐

## 작업 로그 (2025-12-04-14)
- 계획: 소매 승인 후에도 BuyerPortal에서 “No active wholesaler connections”가 뜨는 현상을 해결하고, 린트 경고(use_build_context_synchronously, surfaceVariant 등)를 정리
- 실행: server/src/modules/admin/controller.ts에서 구매자 승인 시 소매 사용자가 도매 테넌트에 owner 권한으로 추가되지 않도록 역할을 manager/staff로 정규화하고, 기존 데이터도 UPDATE로 정리하도록 server/src/server.ts에 롤 정규화 루틴을 추가. Flutter 측에서는 SettingsPage와 SignInPage에 mounted/context.mounted 체크를 보강하고, Order 모델에 lineCount 게터를 도입해 lint를 해소했으며 surfaceContainerHighest.withValues를 사용해 색상 경고를 제거.
- 결과: 도매가 소매를 승인하면 /auth/tenants에 정상적으로 seller 타입이 반영되어 BuyerPortal 카탈로그/주문서가 열리고, 연결 해제 시에도 즉시 차단된다. 동시에 analyzer 경고가 사라져 코드 품질이 개선되었다.

## 작업 로그 (2025-12-04-15)
- 계획: 소매·도매 회사 구성원 모두가 동일한 주문 내역을 공유하고, 주문 생성 시 “어느 회사의 어느 직원이 접수했는지”를 도매가 확인할 수 있도록 서버/클라이언트를 확장
- 실행: orders 테이블에 uyer_tenant_id/buyer_user_id/buyer_user_name/buyer_user_email 컬럼을 추가하고(db/client.ts), /orders API가 소매 사용자의 buyer 테넌트 기준으로 조회/등록하도록 server/src/modules/orders/controller.ts를 수정했으며 서버 기동 시 과거 주문 메타데이터를 보정하는 
ormalizeBuyerOrderMeta를 server.ts에 추가. Flutter Order 모델과 OrderRepository·MockRepository를 새 필드를 지원하도록 확장하고, 주문 상세 화면에 주문 담당자(이름+이메일)를 노출하도록 UI를 보강.
- 결과: 동일 소매 회사 구성원이라면 누구나 BuyerPortal에서 동일한 주문 히스토리를 확인할 수 있고, 도매 화면에서도 주문 상세에 담당자 정보가 표시되어 어떤 매장의 어떤 직원이 주문했는지를 즉시 파악할 수 있다.

## 작업 로그 (2025-12-04-16)
- 계획: BuyerPortal에서 지난 주문 복사가 실패하는 문제를 수정하고, 도매 측 주문 편집 시 상호명/주문상태/주문자 정보가 요구된 UI로 노출되도록 정비
- 실행: uyer_portal_page.dart에서 히스토리 카드 클릭 시 주문 상세 데이터를 재조회한 뒤 장바구니를 채우도록 _handleLoadFromHistory를 보강했고, orders/order_edit_sheet.dart 상단 영역을 재배치해 상호명과 주문 상태를 한 줄에서 7:3 비율로 보여주며 주문자 이름·메모가 읽기 전용 카드로 나타나도록 수정
- 결과: 구매자 대시보드에서 “주문서로 불러오기”가 정상 동작해 재주문이 가능해졌고, 도매 주문 편집 화면에서도 주문자 정보가 즉시 확인되는 요구 레이아웃을 충족했다.

## 작업 로그 (2025-12-04-17)
- 계획: (1) BuyerPortal 주문서에서 매장 선택을 자동으로 기본값으로 채우고, (2) 프로필/설정 메뉴를 “개인정보” 중심으로 단순화해 프로필/사업장 혼용을 정리하며, (3) 설정 화면의 불필요한 항목(프로필 카드, 구매자 미리보기, 로그아웃 버튼)을 제거
- 실행: uyer_portal_page.dart의 매장 로딩 로직에서 옵션 목록이 비어 있지 않으면 첫 매장을 _selectedStore로 자동 지정하도록 수정했다. ProfilePage는 개인 정보 입력/저장/탈퇴만 남기고 업체 관리 섹션을 제거했으며, BuyerPortal 메뉴 문자열(uyerMenuProfile)을 “개인정보”로 갱신했다. 마지막으로 SettingsPage에서 프로필 카드·구매자 미리보기 카드·로그아웃 버튼을 제거하고, 필요한 섹션만 남기도록 정리했다.
- 결과: 장바구니 주문 제출 시 항상 기본 매장이 선택된 상태로 시작해 번거로운 선택을 줄였고, 프로필 및 설정 화면도 개인 정보 관리에 집중된 UX로 정돈되었다.

## 작업 로그 (2025-12-04-18)
- 계획: BuyerPortal 반응형·개인 설정·업체 관리·언어 선호도 동기화를 정비하고, 서버/클라이언트 전반에 대표자/기본 업체 필드를 추가해 주문 플로우를 안정화한다.
- 실행: BuyerPortal 그리드/오버레이/주문서 기본 매장 로직을 손봐 모바일·태블릿 오류와 경고를 제거하고, 개인 설정 화면을 로컬라이즈된 이름/이메일/전화/비밀번호 입력만 남겼다. Buyer Settings 섹션은 업체 카드·메인 업체 지정·편집/삭제/추가 시트를 제공하도록 확장했으며, 언어 드롭다운이 서버에 저장되도록 AuthController/ApiAuthService를 갱신했다. 서버 /auth/tenants·/admin/tenants·가입 API에는 representative/isPrimary 필드를 포함시키고 primaryTenantId·언어 선호를 페르시스트하도록 수정했다.
- 결과: 소매 설정 화면에서도 상단 네비를 유지한 채 업체 정보를 직접 관리하고 기본 매장을 지정할 수 있게 되었으며, 선호 언어와 대표자 정보가 API/DB에 일관되게 저장돼 로그인/주문 기본값에 반영된다.

## 작업 로그 (2025-12-04-19)
- 계획: BuyerPortal 설정·개인설정 패널의 한글 텍스트 깨짐과 매장/도매 연결 정보 미표시 문제를 동시에 해결하고 용어를 “매장” 중심으로 통일
- 실행: `app_en.arb`, `app_ko.arb`, `app_localizations*.dart`에서 Buyer Settings 관련 문자열을 모두 매장 기준 표현으로 수정해 재생성 시에도 깨지지 않도록 했으며, `BuyerPortalPage`가 설정 패널을 열 때마다 `AuthController.refreshTenants()`를 호출해 매장/도매 연결 목록을 즉시 다시 불러온 뒤 매장 선택 목록을 재계산하도록 변경
- 결과: 소매 사용자가 개인설정·설정 화면을 열면 즉시 자연스러운 한글 문구가 표시되고 최신 매장 카드·연결된 도매업체 칩이 로딩되어 더 이상 “미등록 업체”만 보이지 않으며, 주문서 기본 매장도 최신 설정을 그대로 따름
