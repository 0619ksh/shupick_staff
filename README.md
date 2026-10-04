# SHOEPICK 직원용 앱

고객용 `shupick` 프로젝트의 FastAPI와 Firebase Authentication을 사용합니다. 직원 앱의 로그인은 서버에 등록된 활성 직원과 직책만 허용하며, 소속 지점은 `GET /auth/employee/me`에서 가져옵니다.

## 연결 준비

1. 고객용 앱과 같은 Firebase 프로젝트에 **별도 Android 앱** (`com.example.shupick_staff`)을 등록합니다. iOS를 사용한다면 iOS 앱 (`com.example.shupickStaff`)도 등록합니다. FlutterFire가 생성한 `lib/firebase_options.dart`의 프로젝트와 앱 ID가 직원 앱의 등록값인지 확인합니다.
2. Firebase Authentication에서 직원 계정을 만듭니다. 직원의 Firebase UID를 MySQL `employees.firebase_uid`에 연결하고, `employee_roles` 및 지점 직원의 `employee_branch_assignments`를 등록합니다. 직원은 앱에서 계정을 직접 생성할 수 없습니다.
3. 고객용 프로젝트의 FastAPI를 실행하고 `GET /health`가 정상인지 확인합니다. 백엔드에는 Firebase Admin 프로젝트 설정과 MySQL 연결 설정이 필요합니다.

```powershell
flutter run -d emulator-5556 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Android 에뮬레이터는 `10.0.2.2`로 개발 PC의 서버에 접근합니다. 실제 태블릿은 접근 가능한 서버 주소를 `API_BASE_URL`에 지정하고, 배포 환경에서는 HTTPS를 사용하세요. Firebase 앱은 `lib/firebase_options.dart`의 플랫폼별 설정으로 초기화됩니다. Firebase Authentication에서 이메일/비밀번호 로그인을 활성화하고, 생성한 직원 계정의 UID가 `employees.firebase_uid`와 같은지 확인하세요.

현재 업무 화면의 주문·재고 수치는 시연 데이터입니다. 이번 단계에서는 직원 인증, 활성 직책, 현재 소속 지점 조회만 서버와 연결됩니다.
