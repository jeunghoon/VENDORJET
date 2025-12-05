# 로컬 API 서버 가이드

VendorJet 로컬 백엔드는 Express + SQLite 조합으로 구성되어 있으며, 가입/주문/BuyerPortal 플로우를 빠르게 확인하기 위한 목업 API를 제공합니다. 아래 내용을 참고해 환경을 준비하고 필요 시 데이터를 리셋하세요.

## 사전 준비

- Node.js 18 LTS 이상 (ts-node-dev 사용)
- npm 종속성 설치: `npm install`
- SQLite DB 파일: 기본 경로는 `server/vendorjet.db` ( seed 스크립트가 자동 생성 )

## 환경 변수(.env)

루트 `server/.env` 파일에서 다음 값을 설정할 수 있습니다.

```
PORT=4110                  # API 포트
ADMIN_EMAIL=alex@vendorjet.com
ADMIN_PASSWORD=welcome1
JWT_SECRET=local-vendorjet  # 토큰 서명 키
```

포트나 관리자 계정이 필요에 맞지 않다면 여기서 수정 후 서버를 재시작하세요.

## 주요 npm 스크립트

| 명령어          | 설명 |
| -------------- | ---- |
| `npm run dev`  | ts-node-dev로 핫리로드 개발 서버 실행 |
| `npm run seed` | `src/seed.ts`를 통해 SQLite를 초기화(스키마 + 데모 데이터) |
| `npm run build`| TypeScript를 `dist`로 트랜스파일 |
| `npm start`    | 빌드 결과(`dist/server.js`) 실행 |

> **Tip**: 테이블 구조를 초기화하거나 시드 데이터를 다시 채우고 싶을 때는 `vendorjet.db`를 삭제한 뒤 `npm run seed`를 돌리면 됩니다. (자동으로 새 파일 생성)

## 디렉터리 구조

- `src/server.ts` : Express 앱 엔트리, 모듈 라우터 연결, 미들웨어 구성
- `src/modules/*` : 도메인 단위 라우터 (auth/orders/products/customers/buyer/admin)
- `src/utils`     : 응답 포맷, 에러 핸들러 등 공용 유틸
- `src/db`        : SQLite 커넥터 래퍼
- `src/seed.ts`   : 기본 테넌트, 상품, 주문, 사용자 데이터를 삽입

## 핵심 엔드포인트 요약

- `POST /auth/login`, `POST /auth/register-seller`, `POST /auth/register-buyer`
- `GET /auth/tenants-public` : 가입 다이얼로그에서 도매/소매 업체 검색 시 사용
- `GET /auth/check-email` : 이메일 중복 확인
- `GET /orders`, `POST /orders`, `DELETE /orders/:id` 등 주문 CRUD
- `GET /buyer/portal/summary`, `GET /buyer/portal/orders` : BuyerPortal 더미 데이터
- `POST /auth/buyer/reapply` : ì—°ê²ƒ ìœ„ì—ì„œ ìˆ˜ì¦�ìœ¼ë¡œ ë“±ë¡í•œ ì†Œë§¤ê°€ í•œ ëŒë¡œ ë™ë„ ìš”ì²­ì„ í•œ ë²ˆ ë?•ìƒí•˜ì—¬ ë³¸ ì„œë²ˆë¡œ ì •ë ¬ë§Œ ë°›ìŒ

각 모듈의 세부 스키마/응답은 `src/modules/**` 하위 컨트롤러를 참고하면 됩니다.

## 개발 워크플로 추천

1. `npm run seed`로 DB 초기화 → `npm run dev` 실행
2. Flutter 앱 `.env` 혹은 API 클라이언트에서 `http://localhost:4110`으로 호출
3. 가입/주문/BuyerPortal 플로우를 테스트하고 필요 시 `seed.ts` 데이터를 수정
4. 변경된 시드/스키마를 공유하려면 본 문서를 업데이트하고 커밋 메시지에 언급

> 앞으로 서버 플래그나 추가 모듈이 생기면 꼭 이 문서를 갱신해 주세요. 신규 에이전트가 빠르게 환경을 재현할 수 있습니다.
