import 'package:flutter/material.dart';

class StaffRegistrationPage extends StatefulWidget {
  const StaffRegistrationPage({super.key});

  @override
  State<StaffRegistrationPage> createState() => _StaffRegistrationPageState();
}

class _StaffRegistrationPageState extends State<StaffRegistrationPage> {
  String affiliation = '대리점';
  bool hidePassword = true;
  bool hideConfirmation = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('직원 등록')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDCE5F0)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '직원 정보 입력',
                    style: TextStyle(
                      color: Color(0xFF14243E),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '계정에 사용할 정보와 소속을 입력해주세요.',
                    style: TextStyle(color: Color(0xFF6F7E93)),
                  ),
                  const SizedBox(height: 28),
                  const TextField(
                    key: Key('registration-email'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    key: Key('registration-name'),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '이름',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('registration-password'),
                    obscureText: hidePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: hidePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                        onPressed: () =>
                            setState(() => hidePassword = !hidePassword),
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('registration-password-confirmation'),
                    obscureText: hideConfirmation,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '비밀번호 확인',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: hideConfirmation ? '비밀번호 표시' : '비밀번호 숨기기',
                        onPressed: () => setState(
                          () => hideConfirmation = !hideConfirmation,
                        ),
                        icon: Icon(
                          hideConfirmation
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('registration-affiliation'),
                    initialValue: affiliation,
                    decoration: const InputDecoration(
                      labelText: '소속 구분',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '대리점', child: Text('대리점')),
                      DropdownMenuItem(value: '본사', child: Text('본사')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => affiliation = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('registration-affiliation-detail'),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: affiliation == '대리점' ? '소속 지점' : '소속 부서',
                      hintText: affiliation == '대리점' ? '예: SHOEPICK 강남점' : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const FilledButton(
                    key: Key('registration-submit'),
                    onPressed: null,
                    child: Text('직원 등록'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '현재는 화면만 제공하며 계정 등록은 아직 사용할 수 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6F7E93)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
