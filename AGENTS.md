# VendorJet 개발 에이전트 가이드 (한국어)

이 파일은 도매-소매 주문 앱(VendorJet)의 개발/배포 전 과정을 계획하고, 코드 스타일과 작업 절차를 정리한 가이드입니다. 이 디렉토리 트리 전체에 적용됩니다.

- 이 문서는 **코드 작성 일지/작업 로그** 역할을 겸한다. 변경 시 날짜를 명시하고 *계획 → 실행 → 결과* 순으로 짧게 기록한다.
- 기본 언어는 **한국어**, 파일 인코딩은 **UTF-8**로 유지한다.
- 에이전트가 코드를 작성하거나 설계를 바꿀 때마다 본 문서에 근거/의도/다음 액션을 반영한다.
- 파일/커밋/주석 작성 시 기존 가이드(UpperCamelCase 등 네이밍, 주석 한글 우선)를 따른다.

## 목표
- 도매업체가 소매업체로부터 주문을 접수/관리할 수 있는 크로스 플랫폼 앱
- 지원 플랫폼: Android, iOS, macOS, Windows, Web (개발/미리보기 용)
- 배포: Google Play, Apple App Store(iOS), Mac App Store, Microsoft Store(선택)
- 기본 사용자 언어: 영어, 한국어 토글 가능 (추가 언어 확장 용이)

## 기술 스택
- Flutter (Stable) + Dart
- 상태: Flutter 기본 상태/Provider 중 하나 선택 (초기에는 간단한 상태만 상위에서 전달)
- 로컬라이제이션: Flutter gen_l10n (ARB 기반)

## 코드 규칙
- 모든 주석/문서/커밋 메시지는 한국어를 우선합니다.
- 파일/클래스/메서드 명은 일관성 있게 `UpperCamelCase`(클래스), `lowerCamelCase`(메서드/변수), `snake_case`(파일) 사용.
- 위젯은 기능 단위로 `ui/pages`, `ui/widgets` 하위에 분리합니다.
- 테마/색상은 `lib/theme`에서 중앙 관리합니다.
- 문자열은 반드시 ARB에 정의하고 `AppLocalizations`를 통해 접근합니다.

## 브랜치/작업 흐름(권장)
- main: 안정 릴리스용
- develop: 통합 개발용
- feature/*: 기능 단위 분기

## UI/디자인 가이드
- 컬러: 파스텔 주황(#FFA26B), 파스텔 하늘(#5AA9E6), 흰색 기반
- 톤: 심플/세련, 여백 충분히 확보, 카드/리스트 중심
- 반응형: 폰/태블릿은 하단탭, 데스크톱은 NavigationRail 사용

## BuyerPortal UX 가이드
- 장바구니와 주문서를 구매자용 주문서 탭 하나로 통합하고, 동일 화면에서 품목 편집과 주문 정보 입력을 모두 처리합니다.
- 주문서의 매장명은 사용자가 등록한 매장 목록을 드롭다운으로 노출하며, 목록은 고객/매장 데이터와 동기화합니다.
- 구매 담당자 필드는 로그인한 사용자 정보를 기본값으로 채우고 필요 시 수정만 허용합니다.
- 지난 주문 히스토리를 기반으로 한 대시보드를 제공해 요약 지표(총 주문, 이번 달 주문액 등)와 최근 주문 카드 리스트를 보여줍니다.
- 지난 주문 카드에서 "주문서로 불러오기"를 누르면 해당 주문의 품목/메모/매장 메타가 즉시 주문서에 복사되어 재주문 또는 수정이 가능합니다.
- Tab 전환 시 Controller null 오류가 없도록 대시보드→주문서 이동은 DefaultTabController 존재 여부를 확인한 뒤 애니메이션을 실행합니다.
- 장바구니/주문서 품목 정렬은 담은 순서를 그대로 유지하고, 주문서 카드에서는 "N개 품목 : 총수량 M" 형식으로 품목 수와 총 수량을 동시에 노출합니다.
- 앱바 우측 액션에는 희망 배송일 선택기를 배치하며 기본값은 익일, 주문서 카드에서도 동일한 날짜를 표시하고 언제든 변경할 수 있어야 합니다.
- 관련 구현: `lib/ui/pages/buyer/buyer_portal_page.dart`, `lib/repositories/mock_repository.dart`

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
- 번들 ID/패키지명 정리: `com.vendorjet.app`
- 앱 아이콘/스플래시 이미지 확정 및 적용
- 개인정보 처리방침/이용약관 링크 준비
- 스토어 스크린샷/설명(영/한) 작성

6) P5 — 릴리스/스토어 등록
- Android: `flutter build appbundle` → Play Console 업로드
- iOS: `flutter build ipa`(Xcode/맥 필요) → App Store Connect 업로드, 심사 대응
- macOS: `flutter build macos` + 서명/노터라이즈 → Mac App Store 제출
- Windows: `flutter build windows` + MSIX 패키징(선택)

## 실행/개발 방법
- Windows/웹에서 빠르게 UI 확인: `flutter run -d windows` 또는 `flutter run -d chrome`
- 모바일 장치: `flutter devices`로 확인 후 `flutter run -d <deviceId>`
- 핫리로드: 저장 시 즉시 UI 반영

## 배포 체크리스트
- 앱 이름/아이콘 현행화 및 빌드 넘버 증가
- 앱 권한 최소화, 개인정보/서드파티 SDK 점검
- 다국어 번역 확인(영어 기본, 한국어 검수)
- 스토어 정책/가이드라인 준수 여부 확인

## 파일 구조(요약)
- `lib/main.dart`: 앱 엔트리, 라우팅/로케일 상태
- `lib/theme/app_theme.dart`: 색상/Material3 테마
- `lib/ui/pages/*`: 화면 모듈(대시보드/주문/상품/설정)
- `lib/ui/widgets/*`: 공용 위젯(반응형 스캐폴드 등)
- `lib/l10n/*.arb`: 다국어 문자열(영/한)

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
- 대시보드 지표·최근 주문 데이터 반영
- 주문/상품 상세 화면 확장: 편집 액션, 메타데이터 섹션, 내부 메모/재고 정보 표시
- 주문 상태(반품) 추가 및 필터 반영
- 구매자 미리보기 플로우(BuyerPortal) 추가: 카탈로그·장바구니·주문 제출과 판매자 데이터 동기화 시뮬레이션
- 주문 모델/목록/대시보드에 buyerName·buyerContact·buyerNote 노출
- 로컬 API 서버 안정화 및 확장 전략 문서 초안 작성(추후 선택할 배포 서버 비교 포함)
- 회원가입 UX 개선 진행 중: 이메일 중복 확인/비밀번호 확인 로직 추가, 도매·소매 검색 필터 일부 정리, 공용 스낵바 헬퍼(app_snackbar) 도입(전체 교체는 미완료), 기존 업체 선택 시 필드 읽기 전용/회색 처리 작업 일부 적용(추가 정리 필요)
- 코드 재사용성 개선 요구(예정): 회사 검색(도매/소매/글로벌), 알림창, 공통 다이얼로그 등 반복되는 패턴을 공용 함수/위젯으로 모듈화하고, 인수만 받아 호출하는 형태로 단순화 필요(현재는 중복 코드 다수).

## 다음 실행 과정(체크리스트)
(상세 진행 상황은 `TODO.md` 참조)
1) 로컬 API 서버 종단 테스트: AuthController/API 연동을 로컬 Node/Express 사양에 맞춰 안정화하고, 가입/권한/주문 CRUD 흐름을 점검
2) 배포 서버 후보 비교 문서화: 로컬 서버를 완결한 뒤 Firebase/Supabase/자체 호스팅 등 후보의 장단점/비용을 정리해 선택할 수 있도록 준비
3) BuyerPortal v2 설계: 구매자 주문 내역/재주문 템플릿/배송지 캡처 흐름 정의 및 UI 목업 반영

## 이어하기(작업 포인터)
- 로컬 API 서버(Express + SQLite): `server/src/server.ts`, `server/src/modules/*`, `server/src/seed.ts` — CRUD/회원가입/BuyerPortal 라우트 정상 구동. `.env` 세팅 후 `npm run seed`, `npm run dev`.
- 클라이언트 API 전환: `lib/services/auth/api_auth_service.dart`, `lib/services/api/api_client.dart`, `lib/repositories/mock_repository.dart`(API 분기) 정리 및 UI 연결 상태 점검.
- BuyerPortal 확장: `lib/ui/pages/buyer/buyer_portal_page.dart`, `lib/ui/pages/buyer/buyer_cart_controller.dart` — API 데이터 기준 히스토리/스토어/장바구니 검증.
- 주문/상품/고객 CRUD UI와 API 동기화 확인: `lib/ui/pages/orders_page.dart`, `lib/ui/pages/products_page.dart`, `lib/ui/pages/customers_page.dart`.
- 문서/운영 자료: 로컬 API 사용법/플래그 정리(add .vscode/launch.json 안내).
- 가입/승인 확장: 판매자/구매자 가입 탭 UI, 회사 신규/기존 검색, 역할(대표/관리자/직원), 승인 대기/요청 테이블(membership_requests, buyer_requests) 반영.
- 회원가입 공통 알림/검색/스타일 정리: app_snackbar 헬퍼로 스낵바 통일, 회사 검색 필터(도매/소매) 공용 함수화, 기존 업체 선택 시 회사명/주소/전화 회색 읽기 전용 스타일 마무리.
- 코드 중복/가독성 개선(다음 차수):
  - 회사 검색 공용 헬퍼(도매/소매/관리자 등 type 인수만 받는 함수)로 일원화.
  - 알림창 공용 헬퍼(app_snackbar)로 전면 교체, 흰색 스낵바 제거.
  - 공통 다이얼로그/창 레이아웃을 재사용 위젯으로 분리, 내용만 인수로 주입하는 형태로 정리.
  - ChoiceChip 라벨, read-only 필드 스타일 등 UI 깨짐/중복된 로직 정리.

## 진행 상황 체크리스트
- [x] P0 기본 프레임 구축 및 다국어 적용
- [x] GoRouter 기반 라우팅과 주문/상품 상세 페이지 초안
- [x] 주문·상품 목록 로딩/빈/오류 상태 공통 UI 정비
- [x] 대시보드 지표·최근 주문 데이터 반영
- [x] 주문/상품 상세 편집 UI 및 메타데이터 확장
- [x] 주문 상태(반품) 추가 및 필터 반영
- [x] 주문·상품 편집 결과를 목록/대시보드에 동기화
- [x] 상품 상세 편집 플로우 구현
- [x] 로컬 테넌시/권한 시뮬레이션 (관리자/직원 역할, 초대/비밀번호 재설정 목업)
- [x] 주문·상품 CRUD/필터/정렬 흐름을 목업 데이터로 완결
- [x] CSV 업로드/검증/처리 모의 기능 및 UI 연결
- [x] 고객 CRUD/필터/정렬 UI 완성
- [x] 대시보드 카드 딥링크 및 주문번호 자동 생성
- [x] 상품 다단계 카테고리/태그 설정 + XLSX 업로드 플로우
- [x] 고객 CRUD/필터/정렬 UI 완성
- [x] 오류/로딩/빈 상태·접근성·다크모드·공통 알림 등 운영 품질 보강
- [x] 앱 아이콘/스플래시/정책 문서/스토어 설명 초안 준비
- [x] 구매자 미리보기(카탈로그·장바구니·주문 제출) 플로우 구현
- [x] 주문 데이터에 buyerName/contact/note 추가 및 UI 연동
- [x] 로컬 API 인증/권한 흐름 1차 점검 및 개선 과제 도출

## 향후 진행 체크리스트
- [ ] 로컬 API 기반 CRUD/회원가입 종단 테스트(상품·고객·주문·테넌트)
- [ ] 판매자/구매자 구분 회원가입 플로우 구현: 새 회사=소유자 자동 승인, 기존 회사=관리자 승인/알림 설정(관리자만 또는 관리자 이상)
- [ ] 구매자 가입/승인 흐름: 구매자 회사+판매자 회사 입력, 첨부파일 업로드 후 판매자 승인 시 거래 가능, 승인 후 판매자 상품 조회
- [ ] 초대/승인 알림/권한 설정: 관리자에게만 또는 관리자 이상 모두에게 알림 옵션 추가
- [ ] BuyerPortal v2: 주문 내역/배송지/템플릿 설계 및 API 연동 리팩터링
- [ ] 코드/이벤트 로그 정비 및 에러 핸들링(토큰 만료, CORS/네트워크 예외)
- [ ] 핵심 플로우 위젯/통합 테스트 시나리오 작성 및 일부 자동화
- [ ] Firestore/Firebase 전환 설계 재정리(필요 시) 및 문서 업데이트

## 작업 로그 (2025-12-03)
- 계획: BuyerPortal 탭 전환 시 DefaultTabController null 오류 방지 및 MockOrderRepository의 API 삭제 경로 검증
- 실행: `lib/ui/pages/buyer/buyer_portal_page.dart`에서 `_navigateToTab` 호출 전에 `DefaultTabController` 존재 여부를 확인하도록 수정하고, `lib/repositories/mock_repository.dart`의 `MockOrderRepository.delete`가 `/orders/{id}` 엔드포인트를 호출하도록 정정
- 결과: BuyerPortal 탭 이동 시 Null 오류를 예방하여 UX 지침을 준수하고 로컬 API 기반 주문 삭제 흐름이 올바른 경로를 사용하도록 정상화됨

## 작업 로그 (2025-12-03-2)
- 계획: BuyerPortal 지난 주문 카드에 “N개 품목 : 총수량 M” 요약을 노출하기 위해 주문 API/모델에 lineCount 정보를 추가
- 실행: `server/src/modules/orders/controller.ts`에서 주문 목록 조회 시 `line_count`를 반환하고 상세 응답에도 반영, Flutter `Order` 모델(`lib/models/order.dart`)과 관련 매퍼(`lib/repositories/order_repository.dart`, `lib/repositories/mock_repository.dart`)를 lineCount 필드를 지원하도록 확장, BuyerPortal 카드(`lib/ui/pages/buyer/buyer_portal_page.dart`)에서 `buyerOrderSummary` 문자열을 사용해 요약 표시
- 결과: API/클라이언트가 모두 품목 수와 총수량을 제공·표시하게 되어 BuyerPortal UX 가이드의 요구사항을 충족하며 재주문 시 참고 정보가 강화됨

## 작업 로그 (2025-12-03-3)
- 계획: 회원가입 다이얼로그에서 남아 있던 개별 SnackBar 알림을 AppSnackbar로 통합하고 메시지를 자연스러운 한국어로 정비
- 실행: `lib/ui/pages/auth/sign_in_page.dart`의 `messenger?.showSnackBar` 호출을 모두 `AppSnackbar.show`로 대체하고, 이메일 중복 확인/판매자 선택/제출 결과 등의 안내 문구를 AppSnackbar를 통해 노출되도록 수정
- 결과: 회원가입 오류/안내 알림이 공통 스타일(AppSnackbar)로 일관되게 표시되어 UX 지침을 충족하며, 번역도 자연스러운 한글 문장으로 정비됨

## 작업 로그 (2025-12-03-4)
- 계획: 비밀번호 재설정/프로필 수정 등 남은 SnackBar 호출을 모두 AppSnackbar로 교체
- 실행: `lib/ui/pages/auth/sign_in_page.dart`의 `_showSnack` 헬퍼를 AppSnackbar 사용으로 변경해 비밀번호 재설정/탐색 메시지가 통합되도록 하고, `lib/ui/pages/profile/profile_modal.dart` 저장 알림도 AppSnackbar로 교체
- 결과: 앱 전반에서 `ScaffoldMessenger.showSnackBar` 직접 호출이 제거되어 알림 스타일이 통일되었고, 추가 번역 문자열도 자연스러운 한국어로 정리됨

## 작업 로그 (2025-12-03-5)
- 계획: 모든 알림을 NotificationTicker 기반 실시간 알림으로 통일하고 AppSnackbar 유틸 제거
- 실행: `lib/ui/pages/auth/sign_in_page.dart`와 `lib/ui/pages/profile/profile_modal.dart`의 `AppSnackbar` 호출을 `NotificationTicker.push`로 교체하고, `_showSnack` 헬퍼를 NotificationTicker 사용으로 변경, 마지막으로 `lib/ui/widgets/app_snackbar.dart` 파일 삭제
- 결과: 앱 전체 알림이 NotificationTicker 영역 하나로 통합되어 중복 토스트 UI가 사라졌고, 유지보수가 단순해짐

## 작업 로그 (2025-12-04-10)
- 계획: 도매 고객 목록에서 신규 소매사가 연결되면 해당 업체에 종속된 데이터를 매장 카드로 단순하게 보여주도록 정리
- 실행: `server/src/modules/customers/controller.ts`에서 고객 자료 동기화 시 신규 소매/도매 연결이 완료되면 스토어 카드가 즉시 생성되도록 로직을 보강하고 BuyerPortal/권한 체크 로직에 반영
- 결과: 도매 관리자에게 고객 검색/승인 흐름이 즉시 반영되어 구매자 측과 데이터를 공유할 수 있음

## 작업 로그 (2025-12-04-11)
- 계획: 결제/정산 관련 화면에서 필수 항목 누락 시 오류 메시지가 사용자에게 분명히 안내되도록 UI/서버 합동 개선
- 실행: `server/src/modules/auth/controller.ts`의 `/auth/buyer/reapply` 입력 검증을 강화하고, `ApiAuthService·AuthController`가 서버 응답 메시지를 전달하도록 갱신, SettingsPage에 프로필 카드·구매자 미리보기 카드·로그아웃 버튼을 재배치
- 결과: 소매/도매 선택·매장 관리 화면에서 필수 정보 누락 시 즉시 안내되며, 서버/클라이언트 전반에 정합성 체크가 반영됨

## 작업 로그 (2025-12-04-12)
- 계획: 구배포/개인·언어 설정을 손쉽게 모바일/태블릿 오류와 경고를 제거하고, 앱 설정 화면 UI를 간소화
- 실행: BuyerPortal 그리드/오버레이에서 경계선을 정리하고, SettingsPage에서 프로필 카드/구매자 미리보기·언어 선택/로그아웃 버튼을 카드 레이아웃으로 구성, 모바일/태블릿에서도 정렬이 유지되도록 구성
- 결과: 설정 화면이 한눈에 들어오며, 오버레이 분리 덕분에 Section별 위치가 명확해짐

## 작업 로그 (2025-12-04-13)
- 계획: 도매 결제 기반 흐름에서 신규 소매 등록시 우선순위가 반영되도록 하고, 소매가 승인되면 판매자/소매 데이터를 공유할 수 있게 로직 보강
- 실행: POST `/auth/register-buyer`가 기존 소매 업체 등록을 지원하고, `/auth/buyer/reapply` 경로에서 소매-판매자 관계를 재검증하도록 변경. BuyerPortal에서 신규요청을 같은 컨트롤러/화면에서 제출하도록 수정.
- 결과: 신규 소매 회사가 API 단에서 소유자/관리자 역할을 자동 획득하고, 서버 측에서 중복/권한 검사 후 바로 반영되도록 정리됨

## 작업 로그 (2025-12-04-14)
- 계획: BuyerPortal에서 “No active wholesaler connections”가 계속 뜨는 현상과 lint 경고(use_build_context_synchronously 등)를 해소
- 실행: `server/src/modules/admin/controller.ts`에서 연결 요청이 승인되면 소매 측 memberships와 seller memberships에 owner 권한이 포함되도록 보강하고, Flutter 코드에서 mounted/context.mounted 체크를 추가. 주문 모델/리포지토리의 `lineCount` 게터를 정리하고 lint 경고를 제거.
- 결과: 소매 사용자가 도매에서 승인되면 BuyerPortal 화면에 즉시 연결이 반영되고, analyzer 경고가 대부분 해소됨

## 작업 로그 (2025-12-04-15)
- 계획: 구매자/도매 회사 구성이 모두 동일 주문 내역을 공유하고, 주문 상세에서 담당자 정보를 확인할 수 있도록 개선
- 실행: orders 테이블에 `buyer_tenant_id/buyer_user_id/buyer_user_name/buyer_user_email` 컬럼을 추가하고, `/orders` API 응답에서 해당 정보를 반환하도록 변경. Flutter `Order` 모델과 UI를 모두 업데이트해 주문 복사/대시보드 카드에서 담당자 이름과 메모를 표시.
- 결과: 회사 구성원 누구나 동일한 주문 데이터를 공유하고, 주문 상세와 대시보드에서 주문자 정보가 보이도록 일원화됨

## 작업 로그 (2025-12-04-16)
- 계획: BuyerPortal 방문형·개인 설정·언어 토글 선호도 동기화를 정리하고, 서버/클라이언트 전반에 대표자/기본 매장 지정 기능을 추가
- 실행: BuyerPortal 그리드/오버레이 여백 로직을 손본 모바일·태블릿 오류 경고를 제거하고, 앱 설정에 “프로필·개인 설정” 카드와 “매장 설정” 섹션을 추가. 설정 화면에서 매장 목록·언어·로그아웃을 카드 하나로 묶고, 기본 매장은 AuthController/ApiAuthService에서 저장하도록 구현.
- 결과: 도매 사용자/소매 사용자가 모두 설정 화면에서 매장 정보를 직접 관리하고 기본 매장을 지정할 수 있으며, 변경 사항이 저장되면 전체 앱에 즉시 반영됨

## 작업 로그 (2025-12-04-17)
- 계획: BuyerPortal 주문서에서 매장 선택을 자동으로 기본값으로 채우고, 프로필/설정 메뉴를 “개인정보”로 단순화하며, 설정 화면의 불필요한 항목을 제거
- 실행: `buyer_portal_page.dart`에서 주문 로딩 완료 시 `_selectedStore`로 이전 선택을 복원하고, `BuyerMenuProfile`를 “개인설정”으로 갱신. SettingsPage에서 프로필 카드·구매자 미리보기 카드·로그아웃 버튼을 삭제하고 필요한 섹션만 남김.
- 결과: 장바구니/주문 제출 시 항상 기본 매장이 선택된 상태로 시작하며, 프로필 및 설정 화면도 간결한 UX로 정돈됨

## 작업 로그 (2025-12-04-18)
- 계획: BuyerPortal 반응형/개인·언어 설정·업체 설정 동기화를 정비하고, 서버/클라이언트 전반에 대표자/기본 매장 토글을 추가
- 실행: BuyerPortal 그리드/오버레이/탭 로직을 손봐 모바일·태블릿 오류 경고를 제거하고, 개인 설정 화면에서 로컬라이즈된 이름/직원 분류/연락처를 편집하도록 수정. Buyer Settings 섹션을 언어/업체/연결 카드로 분리하고, `auth/tenants` 응답에 representative/isPrimary 필드를 포함시켜 primaryTenantId·언어 설정을 저장.
- 결과: 소매/도매 구분 없이 설정 화면에서 업체 정보를 직접 관리하고 기본 매장을 지정할 수 있으며, 서버/앱 전반에서 저장된 선호도와 언어가 유지됨

## 작업 로그 (2025-12-04-19)
- 계획: BuyerPortal 설정·개인 설정/업체 설정 탭에서 네비게이션이 사라지는 문제와 장바구니/주문서 전환 애니메이션 오류를 해결
- 실행: `buyer_portal_page.dart`에서 헤더/탭을 유지한 채 설정·개인설정 페이지를 표시하도록 Navigator 구조를 조정하고, `settings_page.dart`에서 프로필 카드/업체 카드/로그아웃 버튼을 AppBar 밑으로 이동. 언어 버튼과 로그인 메뉴를 동일한 AppBar 메뉴에서 노출하도록 정리.
- 결과: 개인 설정·설정 페이지에서도 상단 네비게이션이 유지되고, 소매 사용자 경험이 일관성을 되찾음

## 작업 로그 (2025-12-04-20)
- 계획: 소매/도매 각각 회사/직원 정보를 공유하고 대표/관리자가 직책을 지정하며, 대기 요청/로그아웃 버튼이 사라진 문제를 해결
- 실행: `server/src/modules/auth/controller.ts`에서 구성원 목록과 역할 업데이트 API를 추가하고, `vendorjet/lib/services/auth/*.dart`와 SettingsPage에 구성원 목록/직책 편집/로그아웃 버튼을 배치해 매장/업체 카드를 선택/삭제할 수 있도록 보강
- 결과: 새로 가입한 직원도 즉시 기존 도매/소매 연결을 공유하며, 오너는 설정 화면에서 구성원 직책을 조정하고 자신의 직책을 확인할 수 있음

## 작업 로그 (2025-12-04-21)
- 계획: 도매 설정 화면에서 매장 전환·구성원 정보·로그아웃 버튼이 사라진 문제와 BuyerPortal 주문서 오류를 동시에 해결
- 실행: SettingsPage에 매장/업체 카드와 전환 버튼을 복구하고 구성원 API에 전달한 이메일·연락처를 모두 보여주도록 보강, 로그아웃 버튼을 추가. BuyerPortal에서 “주문서로 불러오기” 버튼이 Provider 컨텍스트 밖에서 Cart를 참조하던 문제를 cart 인스턴스 전달 방식으로 수정.
- 결과: 도매 사용자는 설정 화면에서 여러 매장을 명확히 선택·관리하고, 소매 측 주문서 불러오기 시 Provider 오류가 발생하지 않음

## 작업 로그 (2025-12-08-01)
- 계획: SettingsPage에서 `_StoreTile` 위젯 정의가 누락되어 발생한 다트 분석 오류 37건을 해결해 앱이 다시 빌드될 수 있도록 한다.
- 실행: `_buildStoreSelector` 내부에 잘못 위치했던 `_StoreTile` 선언을 제거하고, `_SettingsPageState` 클래스 외부 하단에 전용 위젯으로 재정의해 재사용 UI를 복구했다. 수정 후 `dart analyze lib/ui/pages/settings_page.dart`를 실행해 오류 여부를 확인했다.
- 결과: `_StoreTile` 관련 컴파일 오류가 모두 사라졌고, SettingsPage가 정상적으로 컴파일된다(use_build_context_synchronously 권고만 잔존). Analyzer 결과는 정보 메시지 3건만 남았다.

## 작업 로그 (2025-12-08-02)
- 계획: 도매 업체 검색 시 중복 노출과 소매 연결 재요청 오류를 해소하고, Settings 화면에서 사용자 매장 정보가 항상 표시되도록 서버/클라이언트를 정비한다.
- 실행: `/auth/tenants-public` 쿼리에 `SELECT DISTINCT`를 적용하고, 클라이언트에서도 이름/전화/주소 조합 기준으로 중복을 제거했다. `ApiAuthService.fetchTenants`가 `tenant_type`·`is_primary` 필드를 모두 파싱하도록 보강했으며, SettingsPage의 재연결 폼에서 업태/분류 필수 검증을 추가했다.
- 결과: 도매 검색 팝업에 중복 항목이 나타나지 않고, 각 사용자 계정에서 내 매장 정보가 정상적으로 노출된다. 소매 재연결 시 필수 값 누락으로 인한 서버 400 오류도 사전에 차단됐다.

## 작업 로그 (2025-12-08-03)
- 계획: 도매 Settings 화면의 구성원 목록에서 연결된 소매 사용자까지 노출되는 문제를 해결해 도매/소매 권한을 명확히 분리한다.
- 실행: `/auth/members` API가 테넌트의 유형(도매/소매)을 계산한 뒤, 해당 유형과 일치하는 `user_type`을 가진 사용자만 반환하도록 필터링 로직을 추가했다. 이로써 도매 테넌트는 `wholesale` 사용자만, 소매 테넌트는 `retail` 사용자만 목록에 포함된다.
- 결과: 도매 Settings 페이지에서는 자사 직원만 구성원으로 보여지고, 연결된 소매 업체는 고객 관리 화면에서만 확인할 수 있게 되어 권한 구분이 명확해졌다.

## 작업 로그 (2025-12-08-04)
- 계획: 신규 업체/매장 추가 시 기존 직원이 자동으로 접근권을 얻지 않도록 “사장 승인 기반” 정책(1안)을 적용하고, 소매 승인 시 생성되던 교차 멤버십을 제거한다.
- 실행: `/auth/register-buyer`와 `/admin/requests/:id`에서 소매 사용자에게 도매 테넌트 멤버십을 자동 부여하던 로직과 싱크 함수를 삭제하고, 연결 승인 시에는 고객/세그먼트 데이터만 갱신하도록 조정했다.
- 결과: 새로 등록된 업체는 소유자만 접근할 수 있으며, 직원은 초대/승인을 거쳐야 한다. 도매·소매 계정이 서로의 테넌트에 자동 가입하지 않아 권한 경계가 명확해졌다.

## 작업 로그 (2025-12-08-05)
- 계획: 소매 사용자가 연결된 여러 도매 업체 중 원하는 업체를 선택해 전환하고, 주문/상품 목록을 해당 업체 기준으로 불러올 수 있도록 BuyerPortal·Settings UI를 확장한다.
- 실행: Settings의 “연결된 도매업체” 목록을 ChoiceChip으로 바꿔 선택 시 `switchTenant`를 호출하도록 했고, BuyerPortal AppBar에 도매 선택 드롭다운을 추가했다. 선택/전환 시 `AuthController.switchTenant`를 호출해 API 클라이언트의 tenantId를 바꾸고, 상품/주문/매장 목록을 다시 불러오도록 `_ensureActiveSellerTenant`/`_switchSellerTenant` 헬퍼를 구현했다.
- 결과: 소매 사용자는 승인된 도매 업체들을 목록에서 즉시 선택해 전환할 수 있으며, 전환 후 해당 도매의 카탈로그와 주문 내역이 로드된다. 도매별 오더링 시나리오를 한 화면에서 처리할 수 있게 되었다.

## 작업 로그 (2025-12-08-06)
- 계획: 도매와 이미 연결된 소매 계정이 추가 연결 요청을 보낼 때 Settings 하단 시트에서 `_dependents.isEmpty` assertion이 발생하는 문제를 해결한다.
- 실행: `SettingsPage._openBuyerReconnectSheet`에서 임의로 추출해 사용하던 `rootNavigator.context` 대신, 기존 페이지 `context`에 `useRootNavigator: true` 옵션만 부여해 모달을 호출하도록 수정했다. 이로써 Provider 의존성이 올바른 위계에 유지되고, 시트 종료 시 불필요한 컨텍스트 해제가 발생하지 않도록 했다.
- 결과: 이미 도매에 연결된 상태에서도 추가 연결 요청 시트가 안정적으로 열리고 닫히며, 요청 완료 후 더 이상 붉은 화면(assertion)이 나타나지 않는다.
