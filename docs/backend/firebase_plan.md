# Firebase Auth · Firestore 통합 계획

## 1. 목표 요약
- P1 단계에서 이메일/비밀번호 기반 Firebase Auth로 판매자/직원 로그인·초대 플로우를 실제 백엔드에 연결
- Firestore 다중 테넌트 스키마를 설계해 현재 Mock Repository가 제공하는 데이터(대시보드, 주문, 상품, 고객)를 순차적으로 대체
- 동일한 캐싱/오프라인 전략을 모바일·데스크톱에서 재사용할 수 있도록 서비스 계층 인터페이스를 유지

## 2. 인증 전략
1. **워크스페이스(테넌트) 분리**
   - Auth 커스텀 클레임에 `tenantId`, `role`(owner/manager/staff)를 포함
   - Tenant 전환 시 Cloud Function으로 신규 토큰을 발급하여 권한 상승·강등을 즉시 반영
2. **초대/가입 플로우**
   - 초대 이메일 → Firebase Dynamic Link → `SignInPage`에서 매직 코드 검증 후 비밀번호 설정
   - 비밀번호 재설정은 기본 Firebase 처리 사용하되, 완료 후 앱 내 `AuthController`에서 토큰 재요청
3. **향후 확장**
   - SSO(B2B), OTP 로그인을 고려해 AuthController 인터페이스를 Provider 기반으로 유지

## 3. Firestore 스키마 초안
| 컬렉션 | 주요 필드 | 비고 |
| --- | --- | --- |
| `tenants` | name, plan, locale, createdAt | 테넌트 메타
| `tenantMembers` | tenantId, userId, role, inviteStatus | 복합 인덱스 (tenantId, role)
| `products` | tenantId, sku, name, price, categories[array], tags, lowStock | 카테고리는 1~3단계 문자열 배열
| `productSettings` | productId, mediaRefs, bulkUploadMeta | 대용량 필드 분리
| `customers` | tenantId, name, contactName, email, tier | 검색용 lowerCase name 필드 추가
| `orders` | tenantId, code, buyerName, buyerContact, buyerNote, status, amount, itemCount, placedAt | 코드 중복 방지 위해 `code`에 unique 인덱스
| `orderLines` | orderId, productRef, quantity, unitPrice | UI 목업용 MockLine 대체
| `dashboards` | tenantId, snapshot(json), cachedAt | 캐시 TTL 관리

- `tenantId`는 모든 컬렉션에 존재하며 Firestore 규칙에서 `request.auth.token.tenantId`와 일치 여부를 확인
- 대용량 XLSX 업로드는 Cloud Functions Storage Trigger → Firestore batch write 로 처리 (P2)

## 4. 보안 규칙 개념
```text
match /databases/(default)/documents {
  match /{collection}/{docId} {
    allow read, write:
      if request.auth != null
      && request.auth.token.tenantId == resource.data.tenantId
      && hasRole(request.auth.token.role, collection, request.method);
  }
}
```
- `hasRole` 헬퍼를 Rules Functions로 정의하여 owner/manager/staff 권한을 세분화
- 주문 코드 자동 생성은 클라이언트가 아닌 Cloud Function에서 진행하여 충돌 제거

## 5. 서비스 계층 연동 계획
1. `AuthService` → FirebaseAuth 래퍼 구현, MockAuthService와 동일한 인터페이스 유지
2. `MockRepository`를 `Repository` 인터페이스로 추상화하고 Firestore 버전(`FirestoreOrderRepository` 등)을 추가
3. `DashboardService`는 Firestore `dashboards` 컬렉션과 Cloud Function(집계) 병행 지원
4. `DataRefreshCoordinator`는 Firestore Snapshot Listener를 구독해 자동으로 버전 증가 처리

## 6. 단계별 TODO
| 단계 | 작업 | 세부 내용 |
| --- | --- | --- |
| P1-a | Firebase 프로젝트/앱 등록 | Android/iOS/Web/Windows 패키지명 `com.vendorjet.app` 정리, google-services 설정
| P1-b | AuthController 연결 | FirebaseAuth SDK, Multi-tenant 커스텀 클레임 발급 Function 작성
| P1-c | Firestore 스키마 시드 | Mock 데이터 → Firestore 마이그레이션 스크립트 작성(Cloud Functions callable)
| P1-d | 대시보드/주문 read-only | Repository 인터페이스 전환, 캐시/오프라인 정책 검증
| P1-e | 쓰기 플로우 마이그레이션 | 주문·상품·고객 CRUD를 Firestore 트랜잭션 기반으로 교체

## 7. 참고
- Cloud Functions: Node 20, 지역 `asia-northeast3` 권장
- App Check: 웹·데스크톱 테스트 단계에서는 Debug Provider, 릴리스 시 DeviceCheck/PlayIntegrity 적용
- 로깅: Firebase Analytics + Crashlytics를 P3에서 활성화 예정
