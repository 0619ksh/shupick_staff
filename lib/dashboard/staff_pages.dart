import 'package:flutter/material.dart';
import 'package:shupick_staff/dashboard/staff_views.dart';

const _blue = Color(0xFF1768E9);
const _ink = Color(0xFF14243E);
const _muted = Color(0xFF718098);
const _line = Color(0xFFDCE5F0);
const _red = Color(0xFFCF3948);
const _green = Color(0xFF126D66);

class StaffPage extends StatefulWidget {
  const StaffPage({
    super.key,
    required this.view,
    required this.roleKey,
    required this.isBranch,
  });

  final StaffView view;
  final String roleKey;
  final bool isBranch;

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final pickupCodeController = TextEditingController();
  String? verifiedPickupCode;
  String? pickupError;
  String query = '';
  String selectedCustomer = '김민수';
  String customerTab = '구매 내역';
  String customerMode = '승인 요청';
  String selectedThread = '수령 대기 상품 보관함 확인';
  String sort = '최신 접수순';
  String period = '최근 28일';
  String selectedProduct = '전체 제품';
  String selectedBranch = '전체 대리점';

  @override
  void dispose() {
    pickupCodeController.dispose();
    super.dispose();
  }

  void _useDemoPickupCode(String code) {
    pickupCodeController.text = code;
    setState(() {
      verifiedPickupCode = null;
      pickupError = null;
    });
  }

  void _verifyPickupCode() {
    final code = pickupCodeController.text.trim().toUpperCase();
    setState(() {
      verifiedPickupCode = const ['PICKUP-1038', 'PICKUP-1032'].contains(code)
          ? code
          : null;
      pickupError = verifiedPickupCode == null
          ? '일치하는 수령 대기 주문이 없습니다. 픽업 결제 코드를 다시 확인하세요.'
          : null;
    });
  }

  void _demoAction() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('업무 처리는 다음 단계에서 연결됩니다.')));
  }

  @override
  Widget build(BuildContext context) => switch (widget.view) {
    StaffView.inbound => _inbound(),
    StaffView.pickup => _pickup(),
    StaffView.returns => _returns(),
    StaffView.exchanges =>
      widget.isBranch ? _branchExchanges() : _hqExchanges(),
    StaffView.inventory =>
      widget.isBranch ? _branchInventory() : _hqInventory(),
    StaffView.stockLookup => _stockLookup(),
    StaffView.communication => _communication(),
    StaffView.orders => _orders(),
    StaffView.customers => _customers(),
    StaffView.shipping => _shipping(),
    StaffView.requests => _requests(),
    StaffView.approvals => _approvals(),
    StaffView.analytics => _analytics(),
    StaffView.overview => const SizedBox.shrink(),
  };

  Widget _inbound() => _stack([
    _metrics(const [
      ('배송 중', '2건', '입고 확인 필요'),
      ('입고 완료', '2건', '고객 수령 대기'),
      ('해당 지점', '강남구', '서울 자치구 대리점'),
      ('입고 처리', '1단계', '실물 수량 확인 후 완료'),
    ]),
    _panel(
      '입고 대상 주문',
      '배송 중 주문은 상품 확인 후 입고 처리하세요.',
      _stack([
        _orderCard(
          'ORD-1043',
          '데일리 스니커즈 · 화이트 / 260',
          '강남구 대리점 · 1켤레 · 김민수',
          '배송 중',
          action: '입고 확인',
          steps: 1,
        ),
        _orderCard(
          'ORD-1037',
          '러닝화 · 그레이 / 270',
          '강남구 대리점 · 1켤레 · 이지은',
          '배송 중',
          action: '입고 확인',
          steps: 1,
        ),
        _orderCard(
          'ORD-1038',
          '캔버스화 · 네이비 / 250',
          '강남구 대리점 · 1켤레 · 김민수',
          '입고 완료',
          steps: 2,
        ),
      ]),
    ),
  ]);

  Widget _pickup() => _stack([
    _notice(
      '고객 수령 절차 · 고객의 픽업 결제 코드 입력 → 주문·고객·상품·지점 확인 → 실물 인도. 현재는 데모 코드로 확인합니다.',
    ),
    _panel(
      '픽업 결제 코드 확인',
      '고객이 제시한 픽업 결제 코드를 입력하세요.',
      _stack([
        _field(
          '픽업 결제 코드',
          '예: PICKUP-1038',
          controller: pickupCodeController,
          onChanged: (_) => setState(() {
            verifiedPickupCode = null;
            pickupError = null;
          }),
        ),
        _action('코드 확인', primary: true, onPressed: _verifyPickupCode),
        if (pickupError != null) _notice(pickupError!, warning: true),
        if (verifiedPickupCode != null)
          _notice('코드 확인 완료 · 아래 주문 정보와 실물 상품을 대조한 뒤 고객에게 인도하세요.'),
        if (verifiedPickupCode == 'PICKUP-1038')
          _orderCard('ORD-1038', '캔버스화 · 네이비 / 250', '강남구 대리점 · 김민수', '입고 완료'),
        if (verifiedPickupCode == 'PICKUP-1032')
          _orderCard('ORD-1032', '로퍼 · 블랙 / 255', '강남구 대리점 · 이지은', '입고 완료'),
      ]),
    ),
    _panel(
      '수령 대기 주문 · 데모',
      '데모 코드를 선택해 확인 흐름을 미리 볼 수 있습니다.',
      _stack([
        _orderCard(
          'ORD-1038',
          '캔버스화 · 네이비 / 250',
          '강남구 대리점 · 김민수',
          '입고 완료',
          action: '데모 코드 사용',
          onAction: () => _useDemoPickupCode('PICKUP-1038'),
        ),
        _orderCard(
          'ORD-1032',
          '로퍼 · 블랙 / 255',
          '강남구 대리점 · 이지은',
          '입고 완료',
          action: '데모 코드 사용',
          onAction: () => _useDemoPickupCode('PICKUP-1032'),
        ),
      ]),
    ),
  ]);

  Widget _returns() => _stack([
    _notice(
      '반품은 고객이 대리점에 방문한 뒤 주문과 상품 상태를 확인하여 접수합니다. 교환 접수된 주문은 중복 반품할 수 없습니다.',
      warning: true,
    ),
    _panel(
      '반품 대상 조회',
      '인도 완료 주문만 접수할 수 있습니다.',
      _stack([
        _field(
          '구매번호',
          '예: ORD-1032',
          onChanged: (value) => setState(() => query = value),
        ),
        _action('조회', primary: true),
        if (query.isEmpty || 'ORD-1031'.contains(query.toUpperCase()))
          _orderCard(
            'ORD-1031',
            '데일리 스니커즈 · 화이트 / 260',
            '강남구 대리점 · 김민수',
            '수령 완료',
            action: '반품 접수',
          )
        else
          _empty('검색 조건에 맞는 주문이 없습니다.'),
      ]),
    ),
  ]);

  Widget _branchExchanges() => _stack([
    _notice('교환 절차 · 기존 상품 회수·검수 → 본사 교환품 발송 → 지점 입고 → 픽업 결제 코드 확인·인도'),
    _metrics(const [
      ('접수 가능', '1건', '인도 완료 주문'),
      ('본사 발송 대기', '1건', '교환품 재고 예약'),
      ('배송 중', '0건', '지점 입고 확인 필요'),
      ('고객 재수령 대기', '0건', '픽업 결제 코드 확인'),
    ]),
    _panel(
      '교환 요청 접수',
      '인도 완료 주문의 사이즈·색상 교환을 시연합니다.',
      _orderCard(
        'ORD-1031',
        '데일리 스니커즈 · 화이트 / 260',
        '강남구 대리점 · 1켤레',
        '수령 완료',
        action: '교환 접수',
      ),
    ),
    _panel(
      '교환품 픽업 결제 코드 확인',
      '교환품 입고 후 고객의 픽업 결제 코드를 확인합니다.',
      _stack([
        _field('교환품 픽업 결제 코드', '예: PICKUP-EX-2026-001'),
        _action('코드 확인', primary: true),
      ]),
    ),
    _panel(
      '이 지점 교환 진행',
      '구매번호와 교환번호를 함께 기록합니다.',
      _exchangeCard(
        'EX-2026-000',
        'ORD-1029',
        '캔버스화 · 네이비 / 250 → 255',
        '본사 발송 대기',
      ),
    ),
  ]);

  Widget _hqExchanges() => _stack([
    _notice('대리점에서 기존 상품을 회수·검수한 교환 요청입니다. 제품 코드별 가용 재고를 확인한 뒤 발송합니다.'),
    _metrics(const [
      ('발송 대기', '1건', '교환품 준비'),
      ('배송 중', '1건', '지점 입고 대기'),
      ('지점 도착', '0건', '고객 재수령 대기'),
      ('교환 완료', '0건', '새 판매로 집계하지 않음'),
    ]),
    _panel(
      '교환품 발송 대기',
      '재고는 접수 시 예약되고 발송 시 차감됩니다.',
      _exchangeCard(
        'EX-2026-000',
        'ORD-1029',
        '캔버스화 · 네이비 / 250 → 255',
        '본사 발송 대기',
        action: '교환품 발송',
      ),
    ),
    _panel(
      '제품 코드별 본사 가용 재고',
      '색상·사이즈별 재고',
      _table(
        const ['제품', '색상·사이즈', '제품 코드', '가용 재고'],
        const [
          ['데일리 스니커즈', '화이트 / 260', 'SOLE-U-SNK-DAILY-WH-260', '14켤레'],
          ['러닝화', '그레이 / 270', 'SOLE-U-RUN-RUNNING-GY-270', '33켤레'],
          ['캔버스화', '네이비 / 255', 'SOLE-U-CNV-CANVAS-NV-255', '20켤레'],
        ],
      ),
    ),
    _panel(
      '전체 교환 이력',
      '교환 완료는 새 판매로 집계하지 않습니다.',
      _exchangeCard(
        'EX-2026-000',
        'ORD-1029',
        '캔버스화 · 네이비 / 250 → 255',
        '본사 발송 대기',
      ),
    ),
  ]);

  Widget _branchInventory() => _stack([
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 210,
          child: _field('조회 날짜', '2026-10-04', isDate: true),
        ),
        SizedBox(
          width: 210,
          child: _select('대리점', const ['강남구', '마포구', '송파구']),
        ),
      ],
    ),
    _metrics(const [
      ('기초 재고', '92켤레', '전일 마감 기준'),
      ('유입', '3켤레', '입고·반품·교환'),
      ('인도', '1켤레', '일반·교환 수령'),
      ('마감 재고', '94켤레', '선택 날짜'),
    ]),
    _panel(
      '제품별 재고',
      '강남구 대리점 · 날짜별 시연 수치',
      _table(
        const ['제품', '기초', '유입', '인도', '마감'],
        const [
          ['데일리 스니커즈', '21', '+2', '-1', '22'],
          ['러닝화', '30', '+1', '0', '31'],
          ['로퍼', '18', '0', '0', '18'],
          ['캔버스화', '23', '0', '0', '23'],
        ],
      ),
    ),
    const Text(
      '날짜별 과거 수치는 시연용 예시입니다.',
      style: TextStyle(color: _muted, fontSize: 12),
    ),
  ]);

  Widget _hqInventory() => _stack([
    _metrics(const [
      ('전체 보유', '200켤레', '본사 기준'),
      ('재고 부족', '1종', '목표의 30% 미만'),
      ('결재 진행', '2건', '구매 품의'),
      ('발주 완료', '1건', '자동 발주 기록'),
    ]),
    _notice('재고율은 현재 보유량 ÷ 목표 보유량으로 계산합니다. 30% 미만이면 구매 품의 대상입니다.'),
    _panel(
      '제품별 본사 재고',
      '재고 경고와 발주 상태를 함께 확인하세요.',
      _table(
        const ['제품', '현재 / 목표', '재고율', '발주 상태'],
        const [
          ['데일리 스니커즈', '24 / 100켤레', '24%', '이사 결재 대기'],
          ['러닝화', '58 / 100켤레', '58%', '발주 완료'],
          ['로퍼', '42 / 100켤레', '42%', '팀장 결재 대기'],
          ['캔버스화', '76 / 100켤레', '76%', '정상'],
        ],
      ),
    ),
  ]);

  Widget _stockLookup() => _panel(
    '현재 지점 재고',
    '강남구 대리점 · 현재 보유량',
    _table(
      const ['제품', '옵션', '현재 재고', '상태'],
      const [
        ['데일리 스니커즈', '화이트 / 260', '22켤레', '정상'],
        ['러닝화', '그레이 / 270', '31켤레', '정상'],
        ['로퍼', '블랙 / 255', '18켤레', '정상'],
        ['캔버스화', '네이비 / 250', '23켤레', '정상'],
      ],
    ),
  );

  Widget _communication() {
    final peers = switch (widget.roleKey) {
      'branchStaff' => const ['대리점장'],
      'branchManager' => const ['대리점 직원', '본사 사원', '본사 팀장'],
      'hqStaff' => const ['대리점장'],
      _ => const ['대리점장'],
    };
    final threads = widget.isBranch
        ? const ['수령 대기 상품 보관함 확인', '입고 예정일 문의']
        : const ['입고 예정일 문의', '교환품 수령 안내 기준'];
    if (!threads.contains(selectedThread)) selectedThread = threads.first;
    return _stack([
      _notice('대리점 직원 ↔ 대리점장 ↔ 본사 담당자가 업무를 주고받는 화면입니다. 현재 대화는 시연용입니다.'),
      LayoutBuilder(
        builder: (context, constraints) {
          final panels = [
            _panel(
              '새 대화',
              '담당 직책에 업무를 전달합니다.',
              _stack([
                _select('받는 직책', peers),
                if (!widget.isBranch)
                  _select('관련 대리점', const ['강남구', '마포구', '송파구']),
                _select('분류', const ['입고·배송', '수령·반품', '재고', '운영 이슈', '건의사항']),
                _field('제목', '업무 내용을 짧게 적어주세요'),
                _field('내용', '확인할 주문번호나 필요한 조치를 적어주세요', lines: 3),
                _action('새 대화 보내기', primary: true),
              ]),
            ),
            _panel(
              '대화 목록 · ${threads.length}건',
              '담당 대화를 선택하세요.',
              _stack([
                for (final thread in threads)
                  _choiceTile(
                    thread,
                    thread == '입고 예정일 문의'
                        ? '마포구 · 대리점장 · 입고·배송'
                        : '강남구 · 대리점장 · 수령·반품',
                    selectedThread == thread,
                    () => setState(() => selectedThread = thread),
                  ),
              ]),
            ),
            _panel(
              '대화 내용',
              '선택한 업무 소통 기록',
              _stack([
                Text(
                  selectedThread,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  selectedThread == '입고 예정일 문의'
                      ? '마포구 · 입고·배송 · 진행 중'
                      : '강남구 · 수령·반품 · 진행 중',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                _message(
                  '대리점장',
                  selectedThread == '입고 예정일 문의'
                      ? 'ORD-1043의 도착 예정일을 확인해 주세요.'
                      : 'ORD-1038 상품이 도착했습니다. 고객 방문 전 보관 위치를 확인 부탁드립니다.',
                ),
                _message(
                  '본사 사원',
                  selectedThread == '입고 예정일 문의'
                      ? '배송 일정을 확인해 안내드리겠습니다.'
                      : '확인했습니다. 수령 보관함 A에 보관해 주세요.',
                  mine: true,
                ),
                _field('답변', '답변이나 처리 내용을 입력하세요', lines: 3),
                Wrap(
                  spacing: 8,
                  children: [
                    _action('답변 보내기', primary: true),
                    _action('해결 처리'),
                  ],
                ),
              ]),
            ),
          ];
          if (constraints.maxWidth < 1050) return _stack(panels);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: panels[0]),
              const SizedBox(width: 14),
              Expanded(child: panels[1]),
              const SizedBox(width: 14),
              Expanded(flex: 2, child: panels[2]),
            ],
          );
        },
      ),
    ]);
  }

  Widget _orders() {
    const rows = [
      ['ORD-1045 · 김민수', '데일리 스니커즈', '강남구', '발송 대기', '10.04'],
      ['ORD-1044 · 이지은', '러닝화', '마포구', '발송 대기', '10.04'],
      ['ORD-1043 · 박서준', '로퍼', '강남구', '배송 중', '10.03'],
      ['ORD-1038 · 김민수', '캔버스화', '강남구', '입고 완료', '10.02'],
      ['ORD-1032 · 이지은', '로퍼', '강남구', '수령 완료', '09.29'],
    ];
    final filtered = rows
        .where((row) => row[0].toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (sort == '오래된 접수순') {
      filtered.sort((a, b) => a[4].compareTo(b[4]));
    } else if (sort == '발송 대기 우선') {
      filtered.sort(
        (a, b) => (b[3] == '발송 대기' ? 1 : 0) - (a[3] == '발송 대기' ? 1 : 0),
      );
    } else if (sort == '대리점 가나다순') {
      filtered.sort((a, b) => a[2].compareTo(b[2]));
    }
    return _panel(
      '주문 조회',
      '고객이 선택한 대리점으로 발송됩니다.',
      _stack([
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 260,
              child: _field(
                '구매번호',
                '예: ORD-1042',
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            SizedBox(
              width: 190,
              child: _select(
                '정렬 기준',
                const ['최신 접수순', '오래된 접수순', '발송 대기 우선', '대리점 가나다순'],
                value: sort,
                onChanged: (value) => setState(() => sort = value),
              ),
            ),
            _action('조회', primary: true),
          ],
        ),
        filtered.isEmpty
            ? _empty('검색 조건에 맞는 주문이 없습니다.')
            : _table(const [
                '구매번호 / 고객',
                '제품',
                '희망 대리점',
                '상태',
                '신청일',
              ], filtered),
      ]),
    );
  }

  Widget _shipping() => _stack([
    _notice('고객 구매 신청이 접수되면 선택한 대리점으로 발송 업무가 생성됩니다. 본사 사원이 상품 발송을 처리합니다.'),
    _metrics(const [
      ('발송 대기', '3건', '처리 필요'),
      ('배송 중', '2건', '대리점 입고 대기'),
      ('대리점 도착', '2건', '고객 수령 대기'),
      ('수령 완료', '4건', '인도 처리 완료'),
    ]),
    _panel(
      '주문별 배송 단계',
      '본사 발송 후 대리점에서 입고를 확인합니다.',
      _stack([
        _orderCard(
          'ORD-1045',
          '데일리 스니커즈 · 화이트 / 260',
          '강남구 대리점 · 김민수',
          '발송 대기',
          action: '발송 처리',
          steps: 0,
        ),
        _orderCard(
          'ORD-1044',
          '러닝화 · 그레이 / 270',
          '마포구 대리점 · 이지은',
          '발송 대기',
          action: '발송 처리',
          steps: 0,
        ),
        _orderCard(
          'ORD-1043',
          '로퍼 · 블랙 / 255',
          '강남구 대리점 · 박서준',
          '배송 중',
          action: '입고 예정일 등록',
          steps: 1,
        ),
      ]),
    ),
  ]);

  Widget _requests() => _stack([
    _pair(
      _panel(
        '제조사 구매 품의 작성',
        '팀장·이사 결재가 끝나면 발주가 생성됩니다.',
        _stack([
          _select('제품', const ['데일리 스니커즈', '러닝화', '로퍼', '캔버스화']),
          _field('요청 수량 (켤레)', '100', numeric: true),
          _field('요청 사유', '목표 재고 대비 30% 미만'),
          _action('품의 상신', primary: true),
        ]),
      ),
      _panel(
        '재고 경고',
        '현재 재고 ÷ 목표 보유량',
        _stack([
          _orderCard('데일리 스니커즈', '현재 24켤레 / 목표 100켤레', '구매 품의가 필요합니다.', '24%'),
          _notice('목표 재고의 30% 미만인 상품을 보여줍니다.', warning: true),
        ]),
      ),
    ),
    _panel(
      '최근 품의',
      '결재 단계와 자동 발주 번호를 확인하세요.',
      _table(
        const ['품의번호', '제품', '수량', '상태', '발주번호'],
        const [
          ['PR-2026-019', '로퍼', '60켤레', '팀장 결재 대기', '—'],
          ['PR-2026-018', '데일리 스니커즈', '100켤레', '이사 결재 대기', '—'],
          ['PR-2026-017', '러닝화', '80켤레', '발주 완료', 'PO-2026-017'],
        ],
      ),
    ),
  ]);

  Widget _approvals() {
    final team = widget.roleKey == 'teamLeader';
    final director = widget.roleKey == 'director';
    final executive = widget.roleKey == 'executive';
    return _stack([
      _notice(
        executive
            ? '전체 품의의 결재 단계와 자동 발주 결과를 조회합니다.'
            : director
            ? '팀장 1차 승인 후 넘어온 품의를 최종 검토합니다.'
            : '사원이 상신한 구매 품의를 1차 검토합니다.',
      ),
      _flow(),
      _panel(
        executive
            ? '결재 현황'
            : team
            ? '1차 결재 대기'
            : '최종 결재 대기',
        '담당 단계의 품의 내용을 확인하세요.',
        executive
            ? _empty('임원 화면은 결재 현황 조회 전용입니다.')
            : _stack([
                _approvalCard(
                  team ? 'PR-2026-019' : 'PR-2026-018',
                  team ? '로퍼' : '데일리 스니커즈',
                  team ? '60켤레' : '100켤레',
                  team ? '팀장 결재 대기' : '이사 결재 대기',
                ),
              ]),
      ),
      _panel(
        director ? '최종 검토 이력' : '전체 품의 현황',
        '최근 품의부터 표시합니다.',
        _stack([
          _approvalCard('PR-2026-017', '러닝화', '80켤레', '발주 완료'),
          if (!director)
            _approvalCard('PR-2026-018', '데일리 스니커즈', '100켤레', '이사 결재 대기'),
        ]),
      ),
    ]);
  }

  Widget _analytics() => _stack([
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 170,
          child: _select(
            '기간',
            const ['최근 7일', '최근 14일', '최근 28일'],
            value: period,
            onChanged: (value) => setState(() => period = value),
          ),
        ),
        SizedBox(
          width: 180,
          child: _select(
            '제품',
            const ['전체 제품', '데일리 스니커즈', '러닝화', '로퍼', '캔버스화'],
            value: selectedProduct,
            onChanged: (value) => setState(() => selectedProduct = value),
          ),
        ),
        SizedBox(
          width: 180,
          child: _select(
            '대리점',
            const ['전체 대리점', '강남구', '마포구', '송파구'],
            value: selectedBranch,
            onChanged: (value) => setState(() => selectedBranch = value),
          ),
        ),
      ],
    ),
    _metrics([
      (
        '판매량',
        period == '최근 7일'
            ? '32켤레'
            : period == '최근 14일'
            ? '64켤레'
            : '128켤레',
        '선택한 조건',
      ),
      (
        '매출',
        period == '최근 7일'
            ? '320만원'
            : period == '최근 14일'
            ? '640만원'
            : '1,280만원',
        '선택한 조건',
      ),
      ('일평균', '5켤레', '기간 평균'),
      ('조회 지점', selectedBranch == '전체 대리점' ? '전체' : selectedBranch, '서울 자치구'),
    ]),
    _pair(
      _panel('일자별 판매량', '시연용 판매 데이터', const _MiniChart()),
      _panel(
        '제품별 판매량',
        '켤레',
        _stack(const [
          _BarRow('데일리 스니커즈', '42', .9),
          _BarRow('러닝화', '37', .8),
          _BarRow('로퍼', '28', .6),
          _BarRow('캔버스화', '21', .45),
        ]),
      ),
    ),
    const Text(
      '판매 그래프와 매출은 필터 동작을 보여주기 위한 시연용 데이터입니다.',
      style: TextStyle(color: _muted, fontSize: 12),
    ),
  ]);

  Widget _customers() {
    final leader = widget.roleKey == 'teamLeader';
    const customers = [
      ['C-0012', '김민수', 'VIP', '771,000원', '09.24'],
      ['C-0013', '이지은', '일반', '328,000원', '09.27'],
      ['C-0014', '박서준', '일반', '109,000원', '09.28'],
      ['C-0015', '최유진', 'VIP', '560,000원', '09.21'],
    ];
    final customer = customers.firstWhere(
      (row) => row[1] == selectedCustomer,
      orElse: () => customers.first,
    );
    final visible = customers
        .where(
          (row) =>
              row[0].toLowerCase().contains(query.toLowerCase()) ||
              row[1].contains(query),
        )
        .toList();
    return _stack([
      _metrics(const [
        ('전체 고객', '8명', '시연 데이터 기준'),
        ('VIP 고객', '2명', '현재 등급'),
        ('미해결 문의', '2건', '답변·처리 대기'),
        ('혜택 승인 대기', '1건', '팀장 검토 필요'),
      ]),
      if (leader) ...[
        Wrap(
          spacing: 8,
          children: [
            _filterChip(
              '승인 요청',
              selected: customerMode == '승인 요청',
              onTap: () => setState(() => customerMode = '승인 요청'),
            ),
            _filterChip(
              '고객 목록',
              selected: customerMode == '고객 목록',
              onTap: () => setState(() => customerMode = '고객 목록'),
            ),
          ],
        ),
        if (customerMode == '승인 요청')
          _pair(
            _panel(
              '혜택 승인 요청',
              '사원이 요청한 고객 혜택을 검토합니다.',
              _stack([
                Wrap(
                  spacing: 8,
                  children: const [
                    Chip(label: Text('대기 1')),
                    Chip(label: Text('승인 0')),
                    Chip(label: Text('반려 0')),
                  ],
                ),
                _choiceTile(
                  '김민수 · 적립금 5,000P 지급',
                  '배송 지연 안내에 따른 고객 보상',
                  true,
                  _demoAction,
                ),
              ]),
            ),
            _panel(
              '승인 요청 상세',
              '팀장 승인 후 고객 혜택에 반영됩니다.',
              _stack([
                const Text(
                  '김민수  ·  VIP',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _detailRow('요청 내용', '적립금 5,000P 지급'),
                _detailRow('요청 사유', '배송 지연 안내에 따른 고객 보상'),
                _detailRow('관련 주문', 'ORD-1038'),
                _field('검토 의견', '승인 또는 반려 사유를 입력하세요', lines: 3),
                Wrap(
                  spacing: 8,
                  children: [_action('반려'), _action('승인', primary: true)],
                ),
              ]),
            ),
          ),
      ],
      if (!leader || customerMode == '고객 목록')
        _pair(
          _panel(
            '고객 목록',
            '고객을 선택하면 상세 정보를 확인할 수 있습니다.',
            _stack([
              _field(
                '고객명 또는 고객 ID',
                '고객명 또는 고객번호 검색',
                onChanged: (value) => setState(() => query = value),
              ),
              Wrap(
                spacing: 7,
                children: const [
                  Chip(label: Text('전체')),
                  Chip(label: Text('일반')),
                  Chip(label: Text('VIP')),
                ],
              ),
              visible.isEmpty
                  ? _empty('검색 조건에 맞는 고객이 없습니다.')
                  : Column(
                      children: [
                        for (final row in visible)
                          _choiceTile(
                            '${row[1]} · ${row[0]}',
                            '${row[2]} · 누적 ${row[3]} · 최근 ${row[4]}',
                            selectedCustomer == row[1],
                            () => setState(() => selectedCustomer = row[1]),
                          ),
                      ],
                    ),
            ]),
          ),
          _panel(
            '고객 상세',
            '선택한 고객의 정보와 이력',
            _stack([
              Text(
                selectedCustomer,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${customer[2]} · 고객번호 ${customer[0]} · 010-****-1200',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text('구매 ${selectedCustomer == '김민수' ? '7' : '1'}회'),
                  ),
                  Chip(label: Text('누적 ${customer[3]}')),
                  Chip(
                    label: Text(
                      '적립금 ${selectedCustomer == '김민수' ? '12,000' : '0'}P',
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final tab in const ['구매 내역', '반품 내역', '적립금·혜택'])
                    _filterChip(
                      tab,
                      selected: customerTab == tab,
                      onTap: () => setState(() => customerTab = tab),
                    ),
                ],
              ),
              if (customerTab == '구매 내역' && selectedCustomer == '김민수')
                _table(
                  const ['주문번호', '상품', '수령 지점', '상태'],
                  const [
                    ['ORD-1038', '캔버스화', '강남구', '입고 완료'],
                    ['ORD-1029', '데일리 스니커즈', '강남구', '수령 완료'],
                  ],
                )
              else if (customerTab == '구매 내역')
                _empty('표시할 구매 내역이 없습니다.')
              else if (customerTab == '반품 내역')
                _empty('반품 내역이 없습니다.')
              else
                _detailRow('적립금', selectedCustomer == '김민수' ? '12,000P' : '0P'),
              const Divider(),
              const Text(
                '고객 문의',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
              ),
              if (selectedCustomer == '김민수') ...[
                _choiceTile('배송 예정일 문의', '미처리 · 배송 · 09.29', true, _demoAction),
                _message('고객', '주문한 신발은 언제 대리점에 도착하나요?'),
              ] else
                _empty('이 고객의 문의가 없습니다.'),
              if (!leader) ...[
                _field('문의 답변', '고객에게 안내할 답변을 작성하세요', lines: 3),
                _action('답변 저장', primary: true),
              ],
            ]),
          ),
        ),
      _panel(
        '미해결 고객 문의',
        '문의 처리 현황을 조회합니다.',
        _stack([
          _choiceTile(
            '김민수 · 배송 예정일 문의',
            '미처리 · 배송 · 09.29',
            false,
            _demoAction,
          ),
          _choiceTile(
            '박서준 · 반품 진행 문의',
            '처리 중 · 반품 · 09.29',
            false,
            _demoAction,
          ),
        ]),
      ),
    ]);
  }

  Widget _stack(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        children[i],
      ],
    ],
  );

  Widget _panel(String title, String subtitle, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0924436F),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );

  Widget _metrics(List<(String, String, String)> items) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width <= 0) return const SizedBox.shrink();
      final columns = width >= 1100
          ? 4
          : width >= 480
          ? 2
          : 1;
      final cardWidth = (width - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final (label, value, caption) in items)
            SizedBox(
              width: cardWidth,
              child: Container(
                height: 125,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _notice(String text, {bool warning = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF5E5) : const Color(0xFFEAF3FF),
      border: Border.all(
        color: warning ? const Color(0xFFF4D9A9) : const Color(0xFFCFE2FF),
      ),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? const Color(0xFF885E20) : const Color(0xFF315C94),
        fontSize: 13,
        height: 1.5,
      ),
    ),
  );

  Widget _field(
    String label,
    String hint, {
    ValueChanged<String>? onChanged,
    TextEditingController? controller,
    bool numeric = false,
    bool isDate = false,
    int lines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF596A82),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: lines,
        keyboardType: numeric
            ? TextInputType.number
            : isDate
            ? TextInputType.datetime
            : lines > 1
            ? TextInputType.multiline
            : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _line),
          ),
        ),
      ),
    ],
  );

  Widget _select(
    String label,
    List<String> options, {
    String? value,
    ValueChanged<String>? onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF596A82),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: value ?? options.first,
        isExpanded: true,
        items: [
          for (final option in options)
            DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (next) {
          if (next != null) onChanged?.call(next);
        },
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    ],
  );

  Widget _action(
    String label, {
    bool primary = false,
    IconData? icon,
    VoidCallback? onPressed,
  }) => primary
      ? FilledButton.icon(
          onPressed: onPressed ?? _demoAction,
          icon: Icon(icon ?? Icons.arrow_forward, size: 16),
          label: Text(label),
          style: FilledButton.styleFrom(backgroundColor: _blue),
        )
      : OutlinedButton.icon(
          onPressed: onPressed ?? _demoAction,
          icon: Icon(icon ?? Icons.arrow_forward, size: 16),
          label: Text(label),
        );

  Widget _filterChip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: const Color(0xFFE8F1FF),
  );

  Widget _empty(String label) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
  );

  Widget _table(List<String> headers, List<List<String>> rows) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F7FC)),
          dataRowMinHeight: 48,
          columns: [
            for (final header in headers)
              DataColumn(
                label: Text(
                  header,
                  style: const TextStyle(
                    color: Color(0xFF51637C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final value in row)
                    DataCell(
                      Text(
                        value,
                        style: const TextStyle(color: _ink, fontSize: 12),
                      ),
                    ),
                ],
              ),
          ],
        ),
      );

  Widget _status(String value) {
    final tone = value.contains('완료') || value.contains('정상')
        ? _green
        : value.contains('대기') || value.contains('24%')
        ? _red
        : _blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: tone,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _orderCard(
    String id,
    String product,
    String detail,
    String status, {
    String? action,
    VoidCallback? onAction,
    int? steps,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E9F2)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: _stack([
      Row(
        children: [
          Expanded(
            child: Text(
              id,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _status(status),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
      if (steps != null) _steps(steps),
      if (action != null)
        Align(
          alignment: Alignment.centerRight,
          child: _action(action, primary: true, onPressed: onAction),
        ),
    ]),
  );

  Widget _steps(int progress) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < 4; i++)
        Chip(
          label: Text(
            const ['구매 신청', '본사 발송', '대리점 도착', '고객 수령'][i],
            style: TextStyle(
              fontSize: 11,
              color: i <= progress ? _blue : _muted,
            ),
          ),
          backgroundColor: i <= progress
              ? const Color(0xFFE8F1FF)
              : const Color(0xFFF3F6FA),
        ),
    ],
  );

  Widget _exchangeCard(
    String id,
    String orderId,
    String product,
    String status, {
    String? action,
  }) => _orderCard(
    '$id · $orderId',
    product,
    '강남구 대리점 · 사이즈 변경 · 1켤레',
    status,
    action: action,
    steps: 1,
  );

  Widget _choiceTile(
    String title,
    String detail,
    bool selected,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: selected ? const Color(0xFFEEF5FF) : Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: selected ? const Color(0xFF9BC0F4) : _line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          detail,
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
      ),
    ),
  );
  Widget _message(String author, String text, {bool mine = false}) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine ? const Color(0xFFE5F0FF) : const Color(0xFFF2F6FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author,
            style: const TextStyle(
              color: _blue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(text, style: const TextStyle(color: _ink, fontSize: 12)),
        ],
      ),
    ),
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _pair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 820
        ? _stack([first, second])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: first),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: second),
            ],
          ),
  );

  Widget _approvalCard(
    String id,
    String product,
    String quantity,
    String status,
  ) => _orderCard(
    id,
    '$product · $quantity',
    '요청 사유 · 목표 재고 보충',
    status,
    action: '품의 상세 보기',
  );

  Widget _flow() => _panel(
    '구매 품의 결재 흐름',
    '사원 상신부터 제조사 발주까지',
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        Chip(label: Text('사원 품의 작성')),
        Icon(Icons.arrow_forward, size: 16, color: _muted),
        Chip(label: Text('팀장 1차 승인')),
        Icon(Icons.arrow_forward, size: 16, color: _muted),
        Chip(label: Text('이사 최종 승인')),
        Icon(Icons.arrow_forward, size: 16, color: _muted),
        Chip(label: Text('발주 진행')),
      ],
    ),
  );
}

class _BarRow extends StatelessWidget {
  const _BarRow(this.label, this.value, this.ratio);
  final String label;
  final String value;
  final double ratio;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: const Color(0xFFE7EFF9),
            valueColor: const AlwaysStoppedAnimation(_blue),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _MiniChart extends StatelessWidget {
  const _MiniChart();

  @override
  Widget build(BuildContext context) {
    const heights = [
      44.0,
      72.0,
      60.0,
      94.0,
      80.0,
      118.0,
      101.0,
      132.0,
      90.0,
      111.0,
      124.0,
      138.0,
    ];
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < heights.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: heights[i],
                      decoration: BoxDecoration(
                        color: i == heights.length - 1
                            ? _blue
                            : const Color(0xFF8BB6F3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      i.isEven ? '${i + 1}' : '',
                      style: const TextStyle(color: _muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
