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
- P0 기본 프레임 구축 완료
  - Flutter 스캐폴딩 및 Material3 테마 구성: 파스텔 주황/파랑/흰색 팔레트 적용 (lib/theme/app_theme.dart)
  - 반응형 내비게이션: 폰/태블릿은 하단탭, 데스크톱은 NavigationRail (lib/ui/widgets/responsive_scaffold.dart)
  - 화면: 대시보드/주문/상품/설정 골격 + 더미 UI (lib/ui/pages/*.dart)
  - 다국어(영/한) 및 런타임 언어 전환: gen_l10n + 설정 화면 드롭다운 (lib/l10n/*.arb, l10n.yaml, lib/main.dart)
  - 로그인 화면 골격 추가: 이메일/비밀번호 입력 + 계속 버튼 (lib/ui/pages/auth/sign_in_page.dart)
  - 인증 상태 관리/복원: Provider + SharedPreferences 기반 목업 Auth 서비스 도입
    - 서비스/컨트롤러: lib/services/auth/auth_service.dart, lib/services/auth/auth_controller.dart
    - 앱 시작 시 로그인 상태 로드(스플래시): lib/main.dart
    - 로그인/로그아웃: SignInPage → AuthController.signIn, SettingsPage → AuthController.signOut
  - 로그인/로그아웃 흐름: 미로그인 시 로그인 화면 → 성공 시 홈, 설정에서 로그아웃 (lib/main.dart, settings_page.dart)
  - 정적 분석 통과: `flutter analyze` 문제 없음
  - 도메인 목업 반영: Product/Order 모델 및 목업 리포지토리 추가, 검색바 UI 연결
    - 모델: lib/models/product.dart, lib/models/order.dart
    - 리포지토리: lib/repositories/mock_repository.dart
    - 화면 반영: 상품/주문 페이지에 검색 입력 + 비동기 로딩 적용

## 다음 실행 과정(체크리스트)
1) 인증 연동(선택지 결정)
- 현재: 목업 Auth + SharedPreferences로 상태 복원
- 다음: Firebase Auth 또는 자체 백엔드(OAuth2/JWT) 중 택1로 서비스 교체
- 비밀번호 재설정/회원가입 플로우, 토큰 보관(보안 스토리지) 설계
- 주의: Firebase 선택 시 flutterfire 설정/환경 키 필요(스토어/프로덕션 분리)

2) 라우팅/보안 가드 정리
- 현재: MaterialApp.home에서 게이트 처리(스플래시/로그인/홈)
- 다음: `GoRouter`로 전환하여 인증 가드/딥링크/명시적 라우트 구성

3) 도메인 모델/목업 저장소
- 엔티티: Product, Variant, Inventory, Customer, Order, OrderLine
- 목업 리포지토리/서비스 주입으로 목록/상세/검색 플로우 연결
- API 연동 시 구현체 교체 전략 수립(인터페이스 유지)
  - 현재: Product/Order 반영 및 검색/목록 연결 완료
  - 다음: 상세 화면 레이아웃 초안(ProductDetail, OrderDetail), 필터/정렬 바 추가

4) 주문/상품 UX 개선
- 검색/필터/정렬 UI 와이어프레임 추가
- 빈 상태/로딩/오류 상태 컴포넌트 공통화

5) 빌드 자산
- 앱 아이콘/스플래시 적용, 패키지명/번들 ID 확정

6) 품질/분석
- Crashlytics/Analytics(선택) 탑재 계획 수립, 최소 이벤트 정의

## 빠른 재시작 가이드
- 데스크톱(Windows): `flutter run -d windows`
- 웹 미리보기: `flutter run -d chrome`
- 디바이스 확인: `flutter devices` → `flutter run -d <deviceId>`
- 문자열 수정 후 로컬라이즈 재생성: `flutter gen-l10n`

## 이어하기(작업 포인터)
- 인증 실제 연동 시작 지점
  - 인증 UI: `lib/ui/pages/auth/sign_in_page.dart`
  - 앱 상태/전환: `lib/main.dart` (스플래시/게이트 + Provider)
  - 컨트롤러/서비스: `lib/services/auth/auth_controller.dart`, `lib/services/auth/auth_service.dart`
- 언어/문구 추가: `lib/l10n/app_en.arb`, `lib/l10n/app_ko.arb` → `flutter gen-l10n`
- 색/스타일 조정: `lib/theme/app_theme.dart`
