# VendorJet DB 설계 v2 (무역 확장)

## 핵심 철학
- User(계정)와 Organization(도매/소매/창고)을 분리하고 OrgMember로 연결해 멀티테넌시를 명확히 관리한다.
- Role/Permission으로 RBAC를 구성하고, org_id 스코프 제약을 둔다.
- 주문·재고·정산은 모두 이벤트/원장 형태(ledger/txn)로 남겨 재계산과 감사가 가능하게 한다.

## 주요 도메인/테이블 묶음
- 인증/RBAC: `users`, `organizations`, `roles`, `permissions`, `role_permissions`, `org_members`.
- 파트너/원장: `partner_requests`(연결 요청), `partners`(승인된 관계), `partner_ledger_entries`(미수/입금 이벤트).
- 상품/무역: `products`(incoterm/HS코드/원산지/UOM 등), `product_i18n`, `product_packaging`(CBM/중량/pack), `product_trade_terms`(FOB/CIF 가격·리드타임·항구), `product_eta`(선적/입항 스케줄).
- 창고/재고: `warehouses`, `inventory`(합계), `inventory_lot`(유통기한/로트), `inventory_txn`(입출고 원장), `stock_transfers`+`stock_transfer_lines`, `inventory_adjustments`.
- 주문/정산: `orders`, `order_items`(trade_term/packaging/lot/Freight/Insurance 단위별 금액), `order_events`, `payments`(입금/결제), `customers`(B2C).
- HR: `employees`, `attendance`, `leave_requests`, `payroll`, `payroll_items`.
- 감사/운영: `audit_logs`.

## 무역/상품 필드 정리
- Incoterm/무역조건: `products.incoterm`, `product_trade_terms`에 포워딩/항구/화폐/가격/보험/운임/리드타임/유효기간 저장.
- CBM/중량/팩 단위: `product_packaging`에 길이·너비·높이·CBM·순/총중량·묶음 수량·바코드. CBM은 L*W*H/1,000,000으로 계산.
- HS 코드/원산지/UOM/Tax: `products.hs_code`, `origin_country`, `uom`, `tax_class`, `is_perishable`.
- ETA/선적 스케줄: `product_eta`에 ETD/ETA/선박/보야지/항구/상태 기록 후 주문 아이템에 연결(필요 시 `order_items.lot_id`와 함께 사용).
- 유통기한/로트: `inventory_lot`으로 창고별 로트와 제조/유통기한, 상태(HOLD/EXPIRED) 관리. 실거래는 `inventory_txn`에 delta로 적재하고 `inventory`는 합계 캐시.

## 적용 방법
- SQLite 기준 예시: `sqlite3 server/vendorjet.db < server/schema_v2.sql` (덮어쓰기 전 기존 DB 백업 권장).
- PostgreSQL 사용 시 타입/시퀀스만 맞추면 동일 구조로 적용 가능하며, 모든 금액은 minor 단위 정수(`*_minor`)와 통화 코드(`currency`)를 함께 저장한다.
- 테넌트/파트너/주문/재고 변경 시 `audit_logs`에 행위/타깃/변경분(diff_json)을 남겨 추적성을 확보한다.

## 참고
- 자세한 컬럼/제약은 `server/schema_v2.sql`을 확인하고, 추가 작업 로그는 `docs/backend/work_log.md`에 기록한다.
