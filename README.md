# SHOEPICK 직원용 앱

서울 대리점과 본사 직원이 사용하는 Flutter 태블릿 앱입니다. 고객용 `shupick` 프로젝트의 **Firebase Authentication, FastAPI, MySQL `shupick_v2`**를 공유합니다. 이 저장소에는 직원용 Flutter 코드만 있으며, 백엔드·DB 스키마와 마이그레이션은 별도 `shupick` 프로젝트에 있습니다.

## 현재 구현 범위

| 사용자 | 서버에 연결된 업무 |
| --- | --- |
| 대리점 직원·점장 | 소속 지점 주문 입고, 픽업 결제 코드 확인 및 고객 수령 완료, 방문 고객의 반품 접수·상태 조회, 현재/날짜별 지점 보관 수량 |
| 본사 사원 | 주문·배송 조회와 발송 처리, 고객 목록·구매/반품 내역·문의 답변, 반품 검수, 본사 재고 조회, 구매 품의 작성·상신 |
| 본사 팀장·이사 | 단계별 구매 품의 승인·반려, 본사 재고 조회 |
| 본사 임원 | 최근 28일 판매 분석, 재고 및 결재 현황 조회 |

직책별 첫 대시보드의 카드와 알림도 서버 데이터를 사용합니다. 알림을 누르면 해당 업무 화면으로 이동하며 **새로고침**으로 다시 조회할 수 있습니다. 지점 직원의 수치는 선택한 소속 지점 기준입니다. 주문·반품·문의·품의 수치는 각 API가 반환하는 **최근 100건**, 임원 판매 수치는 **최근 28일** 기준입니다. 가용 재고가 목표의 30% 미만인 제품 옵션은 재고 부족으로 표시합니다.

직원 등록 화면에서 Firebase 계정을 만들고 MySQL에 직원·직책·지점 배정을 즉시 저장합니다. 현재는 테스트 단계의 즉시 활성화 정책이며 이메일 인증이나 관리자 승인 절차는 없습니다.

반품은 고객이 수령한 대리점에 방문하면 직원 또는 점장이 **반품 → 반품 접수**에서 주문번호(픽업 결제 코드)를 조회하고 상품·수량·사유를 입력해 접수합니다. 단순변심은 수령 후 7일 이내, 미착용·훼손 없음·구성품 및 포장 유지 조건을 확인합니다. 상품 하자·오배송은 별도 사유로 접수할 수 있습니다. 구매확정 주문과 중복 접수는 서버에서 차단합니다. 고객 앱은 방문 안내와 처리 내역 조회만 제공합니다. 접수 후 본사 검수·승인 단계로 이어지며 접수만으로 환불·재고 복구가 실행되지는 않습니다.

본사 사원은 **반품 검수 → 반품 환불 처리**에서 승인된 반품을 선택해 서버가 계산한 환불 금액과 배분 적립금을 확인하고 테스트 환불을 처리할 수 있습니다. 현재 고객 앱에서 생성한 `flutter-payment-` 거래 키의 테스트 결제만 대상으로 합니다. 실제 결제사 호출이나 송금은 수행하지 않습니다. 성공 시 기존 환불 API가 반품 완료, 결제 상태 및 적립금 복원을 기록합니다. 만료된 적립금은 복원되지 않으며 쿠폰 할인은 현금 환불액에 포함되지 않습니다. 같은 반품의 재시도는 기존 환불 기록을 사용합니다.

**현재 범위 밖:** 교환 기능은 운영 계획에서 제외했습니다. 직원 간 업무 대화와 고객 혜택 승인은 DB/API가 없어 메뉴에서 제외했습니다. 실제 결제사 환불 연동, 제조사 실제 발주, 직원 계정 삭제·권한 변경, 수동 재고 조정 화면도 아직 없습니다.

## 팀원이 처음 받을 때

### 1. 앱 코드와 개발 도구

Flutter SDK, Android Studio/Android SDK를 설치합니다. iOS를 빌드할 팀원은 macOS와 Xcode도 필요합니다. `pubspec.yaml`은 Dart SDK `^3.12.2`를 요구합니다.

```powershell
git clone https://github.com/0619ksh/shupick_staff.git
cd shupick_staff
flutter doctor
flutter pub get
```

### 2. 같은 Firebase 프로젝트에 앱 연결

고객용 앱과 **같은 Firebase 프로젝트**를 사용하되, Firebase에 등록한 직원용 Android 앱(`com.example.shupick_staff`)과 iOS 앱(`com.example.shupickStaff`)의 구성을 선택합니다. Firebase Authentication에서 이메일/비밀번호 로그인을 활성화합니다.

Firebase CLI로 로그인하고 [FlutterFire CLI 설정 절차](https://firebase.google.com/docs/flutter/setup)에 따라 프로젝트 루트에서 `flutterfire configure`를 실행합니다. 이미 등록된 직원용 앱과 패키지 ID가 일치하는지 확인하세요. 이 과정에서 `lib/firebase_options.dart`를 생성합니다. Android 빌드에 필요한 `android/app/google-services.json`도 있는지 확인하고, 없다면 Firebase 콘솔에서 직원용 Android 앱의 구성 파일을 받아 해당 위치에 둡니다. iOS를 사용하는 경우 직원용 `GoogleService-Info.plist`를 `ios/Runner/`에 둡니다.

이 세 구성 파일은 **Git 추적 대상이 아닙니다.** 각 팀원이 로컬에서 준비하세요. 서버용 Firebase 서비스 계정 JSON은 앱 폴더에 넣지 않습니다. 이전 커밋에 노출된 API 키는 파일을 최신 커밋에서 제거해도 Git 기록에 남으므로, Firebase/Google Cloud에서 제한·교체 상태를 별도로 확인해야 합니다.

### 3. 호환되는 FastAPI와 MySQL 준비

별도 `shupick` 프로젝트의 **직원 등록·주문/수령·반품·재고·품의·고객 문의·판매 분석 API가 포함된 최신 백엔드**가 필요합니다. 이 직원 앱 저장소만 받아서는 서버가 실행되지 않습니다. 팀에서 받은 `shupick/backend`의 `.env.example`을 `.env`로 복사한 뒤 MySQL 접속값, `FIREBASE_PROJECT_ID`, 저장소 밖의 `FIREBASE_CREDENTIALS_PATH`를 설정합니다. 서버의 Firebase 프로젝트 ID는 직원 앱과 같아야 합니다.

MySQL `shupick_v2`에 해당 백엔드의 스키마·마이그레이션이 적용돼 있어야 합니다. 기존 DB라면 `shupick/database/migrations/`의 적용 이력을 확인하고 **누락된 파일만 순서대로** 적용하세요. 직원 직책·서울 지점·등록 정책과 관련된 파일은 `018_staff_display_roles.sql`부터 `024_branch_manager_pickup_permission.sql`까지입니다. `shupick_schema_v2.sql`은 테이블을 다시 생성하므로 **데이터가 있는 DB에 실행하지 마세요.**

백엔드 준비 예시(Windows PowerShell):

```powershell
cd ..\shupick\backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
Copy-Item .env.example .env
# .env를 실제 MySQL·Firebase 설정으로 수정한 뒤:
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

다른 터미널에서 `http://127.0.0.1:8000/health`가 `status: ok`를 반환하는지 확인합니다. 특히 `GET /auth/employee/me`, `POST /auth/employee/register`, `GET /staff/orders`, `GET /staff/inventory`, `GET /staff/returns`, `GET /staff/analytics` 경로가 서버의 `/docs`에 있어야 합니다. 404가 나오면 앱 문제가 아니라 백엔드 코드 버전 또는 서버 재시작을 확인하세요.

새 반품 접수 기능에는 `GET /staff/returns/order`와 `POST /staff/orders/{order_id}/returns`가 포함된 백엔드가 필요합니다. 기존 고객 직접 접수 API는 403으로 차단합니다. 이 변경에는 DB 마이그레이션이 필요하지 않습니다.

환불 기능에는 `GET /staff/returns/{return_id}/refund`와 `POST /staff/returns/{return_id}/refund/test`도 필요합니다. 권한은 `REFUND_MANAGE`이며, 실제 결제 거래는 테스트 환불을 차단합니다. 코드를 받은 뒤 백엔드를 재시작하세요. 추가 DB 마이그레이션은 없습니다.

### 4. 앱 실행과 확인

Android 에뮬레이터에서는 개발 PC의 서버 주소가 `10.0.2.2`입니다. 앱 기본값도 이 주소를 사용합니다.

```powershell
cd ..\..\shupick_staff
flutter devices
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

실제 태블릿은 `API_BASE_URL`에 기기에서 접근 가능한 서버 주소를 지정합니다. Android 디버그 빌드에서만 로컬 HTTP 테스트를 허용하며, 배포 환경은 HTTPS로 구성하세요. 주소를 바꾸면 앱을 다시 실행합니다.

앱에서 직원 등록 또는 기존 계정 로그인 → 직책·소속 지점 확인 → 대시보드 새로고침 → 업무 메뉴 진입 순서로 점검합니다. 대리점 직원은 `employee_branch_assignments`에 종료되지 않은 지점 배정이 있어야 로그인 후 업무 화면을 사용할 수 있습니다. Firebase 계정 UID는 MySQL `employees.firebase_uid`와 일치해야 합니다.

## 개발 검증

품의 작성은 본사 재고 보충용으로 제품 옵션·수량·제목·사유만 입력합니다. 대리점은 선택하지 않습니다. 백엔드에서 지점 없이 저장할 수 있도록 `shupick/database/migrations/027_hq_procurement_without_branch.sql`을 먼저 적용하세요. 기존 품의의 지점 연결은 유지됩니다.

```powershell
flutter analyze
flutter test
```

백엔드 변경 사항은 별도 `shupick/backend`에서 `python -m pytest tests -q`로 검증합니다. Firebase 계정, MySQL 데이터, 백엔드 코드는 이 저장소의 `git pull`만으로 동기화되지 않으므로 팀에서 각각 같은 버전을 사용해야 합니다.
