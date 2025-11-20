# VendorJet 개발 에이전트 가이드 (한국어)

이 파일은 도매-소매 주문 앱(VendorJet)의 개발/배포 전 과정을 계획하고, 코드 스타일과 작업 절차를 정리한 가이드입니다. 이 디렉토리 트리 전체에 적용됩니다.

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
- Firebase Auth 또는 자체 백엔드(OAuth2) 중 하나 선택

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
- 대시보드 지표·최근 주문 UI 구축 및 DashboardService 계층 분리
- 주문/상품 상세 화면 확장: 편집 액션, 메타데이터 섹션, 내부 메모/재고 정보 표시
- 주문 상태(반품) 추가 및 필터 반영
- 구매자 미리보기 플로우(BuyerPortal) 추가: 카탈로그·장바구니·주문 제출과 판매자 데이터 동기화 시뮬레이션
- 주문 모델/목록/대시보드에 buyerName·buyerContact·buyerNote 노출
- Firebase Auth·Firestore 통합 계획 문서 초안 작성(docs/backend/firebase_plan.md)
## 다음 실행 과정(체크리스트)
1) Firebase Auth SDK 연동 준비: AuthController에 Firebase 모드 스위치 추가 및 커스텀 클레임 발급 Function 스켈레톤 작성
2) Firestore Repository 1차 구현: 주문/상품/고객 read-only 계층 도입 후 UI 병행 주입
3) BuyerPortal v2 설계: 구매자 주문 내역/재주문 템플릿/배송지 캡처 흐름 정의 및 UI 목업 반영
## 이어하기(작업 포인터)
- Firebase Auth 연동: lib/services/auth/*, lib/ui/pages/auth/*
- Firestore Repository 인터페이스 전환: lib/repositories/mock_repository.dart, lib/services/dashboard/dashboard_service.dart
- BuyerPortal 확장: lib/ui/pages/buyer/buyer_portal_page.dart, lib/ui/pages/buyer/buyer_cart_controller.dart
- 주문 buyer 메타 유지보수: lib/ui/pages/orders_page.dart, lib/ui/pages/orders/order_detail_page.dart, lib/ui/pages/orders/order_form_sheet.dart
- 문서/운영 자료: docs/backend/firebase_plan.md, docs/*
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
- [x] Firebase Auth·Firestore 통합 계획 문서화
## 향후 진행 체크리스트
- [ ] Firebase Auth SDK 연동 및 커스텀 클레임 발급 Function 작성
- [ ] Firestore Repository(주문/상품/고객) read-only 계층 도입 및 캐싱 전략 검증
- [ ] BuyerPortal v2: 구매자 주문 내역/배송지/템플릿 설계 및 UI 반영
- [ ] Cloud Functions 기반 주문 코드 생성·XLSX 업로드 파이프라인 설계
- [ ] 핵심 플로우 위젯/통합 테스트 시나리오 명세


