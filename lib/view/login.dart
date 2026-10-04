import 'package:flutter/material.dart';
import 'package:shupick_staff/dashboard/dashboard_page.dart';

class Login extends StatefulWidget {
  const Login({super.key, required this.onSelect});

  final void Function(StaffRole role, String branch) onSelect;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String branch = '강남구';

  static const districts = [
    '강남구',
    '강동구',
    '강북구',
    '강서구',
    '관악구',
    '광진구',
    '구로구',
    '금천구',
    '노원구',
    '도봉구',
    '동대문구',
    '동작구',
    '마포구',
    '서대문구',
    '서초구',
    '성동구',
    '성북구',
    '송파구',
    '양천구',
    '영등포구',
    '용산구',
    '은평구',
    '종로구',
    '중구',
    '중랑구',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEDF2F8),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final branchGroup = _group(
            title: '대리점',
            description: '상품 입고, 고객 수령, 재고·반품·교환',
            children: [
              const Text(
                '대리점 선택',
                style: TextStyle(
                  color: Color(0xFF596A82),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              DropdownButtonFormField<String>(
                key: const Key('branch-selector'),
                initialValue: branch,
                isExpanded: true,
                items: [
                  for (final district in districts)
                    DropdownMenuItem(value: district, child: Text(district)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => branch = value);
                },
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _roleButton(StaffRole.branchStaff),
              const SizedBox(height: 10),
              _roleButton(StaffRole.branchManager),
            ],
          );
          final headquartersGroup = _group(
            title: '본사',
            description: '주문·배송, 고객 관리, 구매 품의와 결재',
            children: [
              _roleButton(StaffRole.hqStaff),
              const SizedBox(height: 10),
              _roleButton(StaffRole.teamLeader),
              const SizedBox(height: 10),
              _roleButton(StaffRole.director),
              const SizedBox(height: 10),
              _roleButton(StaffRole.executive),
            ],
          );
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: EdgeInsets.all(wide ? 32 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3175EE),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Text(
                              'S',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SHOEPICK',
                                style: TextStyle(
                                  color: Color(0xFF12315E),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '직원 태블릿',
                                style: TextStyle(
                                  color: Color(0xFF5F7495),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (wide) const Chip(label: Text('직책별 화면 체험')),
                        ],
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        '업무에 맞는 화면으로 시작하세요',
                        style: TextStyle(
                          color: Color(0xFF132A4B),
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        '대리점과 본사의 직책을 선택하면 해당 업무 화면이 열립니다.',
                        style: TextStyle(
                          color: Color(0xFF6F7E93),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 27),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: branchGroup),
                            const SizedBox(width: 20),
                            Expanded(child: headquartersGroup),
                          ],
                        )
                      else
                        Column(
                          children: [
                            branchGroup,
                            const SizedBox(height: 18),
                            headquartersGroup,
                          ],
                        ),
                      const SizedBox(height: 18),
                      const Text(
                        '이 화면은 기능 시연용입니다. 직책 선택은 실제 계정 인증을 대신하지 않습니다.',
                        style: TextStyle(
                          color: Color(0xFF73849B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _group({
    required String title,
    required String description,
    required List<Widget> children,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(23),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDCE5F0)),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F24436F),
          blurRadius: 35,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF14243E),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(color: Color(0xFF7A899C), fontSize: 12),
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    ),
  );

  Widget _roleButton(StaffRole role) => Material(
    color: const Color(0xFFFAFCFF),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xFFDFE8F3)),
      borderRadius: BorderRadius.circular(11),
    ),
    child: InkWell(
      key: Key('role-${role.name}'),
      borderRadius: BorderRadius.circular(11),
      onTap: () => widget.onSelect(role, branch),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: const TextStyle(
                      color: Color(0xFF193653),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    role.description,
                    style: const TextStyle(
                      color: Color(0xFF718399),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Color(0xFF2872DB), size: 20),
          ],
        ),
      ),
    ),
  );
}
