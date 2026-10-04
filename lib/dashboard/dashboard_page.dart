import 'package:flutter/material.dart';
import 'package:shupick_staff/dashboard/staff_pages.dart';
import 'package:shupick_staff/dashboard/staff_views.dart';

const _navy = Color(0xFF102B58);
const _blue = Color(0xFF1768E9);
const _ink = Color(0xFF14243E);
const _muted = Color(0xFF718098);
const _line = Color(0xFFDCE5F0);
const _red = Color(0xFFCF3948);
const _green = Color(0xFF126D66);

enum StaffRole {
  branchStaff('대리점 직원', '입고·픽업 결제 코드 확인·반품·교환 처리', true),
  branchManager('대리점장', '지점 재고와 운영·본사 소통', true),
  hqStaff('본사 사원', '주문·고객 문의·배송·구매 품의', false),
  teamLeader('본사 팀장', '구매 품의·고객 혜택 결재·지점 이슈 조정', false),
  director('본사 이사', '구매 품의 최종 결재', false),
  executive('본사 임원', '판매·재고·발주 분석', false);

  const StaffRole(this.label, this.description, this.isBranch);

  static StaffRole? fromCode(String code) => switch (code) {
    'BRANCH_STAFF' => StaffRole.branchStaff,
    'BRANCH_MANAGER' => StaffRole.branchManager,
    'HQ_STAFF' => StaffRole.hqStaff,
    'TEAM_LEAD' => StaffRole.teamLeader,
    'DIRECTOR' => StaffRole.director,
    'EXECUTIVE' => StaffRole.executive,
    _ => null,
  };
  final String label;
  final String description;
  final bool isBranch;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.initialRole,
    required this.availableRoles,
    required this.employeeName,
    required this.branch,
    required this.availableBranches,
    required this.onSelectBranch,
    required this.onSignOut,
  });

  final StaffRole initialRole;
  final List<StaffRole> availableRoles;
  final String employeeName;
  final String branch;
  final Map<int, String> availableBranches;
  final ValueChanged<int> onSelectBranch;
  final VoidCallback onSignOut;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late StaffRole role;
  StaffView selectedView = StaffView.overview;
  final ScrollController _contentScrollController = ScrollController();

  void _selectView(StaffView view) {
    if (selectedView == view) return;
    setState(() => selectedView = view);
    if (_contentScrollController.hasClients) _contentScrollController.jumpTo(0);
  }

  void _selectRole(StaffRole value) {
    setState(() {
      role = value;
      selectedView = StaffView.overview;
    });
    if (_contentScrollController.hasClients) _contentScrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    role = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final tabletPortrait =
            constraints.maxWidth >= 700 && constraints.maxWidth < 1100;
        return Scaffold(
          drawer: compact
              ? Drawer(
                  width: 260,
                  child: _Sidebar(
                    role: role,
                    employeeName: widget.employeeName,
                    branch: widget.branch,
                    selectedView: selectedView,
                    inDrawer: true,
                    onSelect: _selectView,
                    onSignOut: widget.onSignOut,
                  ),
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                if (tabletPortrait)
                  SizedBox(
                    width: 88,
                    child: _TabletRail(
                      role: role,
                      selectedView: selectedView,
                      onSelect: _selectView,
                      onSignOut: widget.onSignOut,
                    ),
                  ),
                if (!compact && !tabletPortrait)
                  SizedBox(
                    width: 236,
                    child: _Sidebar(
                      role: role,
                      employeeName: widget.employeeName,
                      branch: widget.branch,
                      selectedView: selectedView,
                      onSelect: _selectView,
                      onSignOut: widget.onSignOut,
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _contentScrollController,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 16 : 24,
                            compact ? 20 : 24,
                            compact ? 16 : 24,
                            44,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _header(compact, constraints.maxWidth < 1100),
                              const SizedBox(height: 24),
                              if (selectedView == StaffView.overview) ...[
                                _Metrics(items: _metricsFor(role)),
                                const SizedBox(height: 18),
                                _alerts(),
                                const SizedBox(height: 18),
                                _roleSections(),
                              ] else
                                StaffPage(
                                  key: ValueKey(
                                    '${role.name}-${selectedView.name}',
                                  ),
                                  view: selectedView,
                                  roleKey: role.name,
                                  isBranch: role.isBranch,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(bool compact, bool stacked) {
    final now = DateTime.now();
    final date =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    final heading = viewTitle(
      selectedView,
      isBranch: role.isBranch,
      role: role.name,
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          Builder(
            builder: (context) => IconButton.filledTonal(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
              tooltip: '업무 메뉴',
            ),
          ),
        Text(
          role.isBranch ? 'BRANCH OPERATIONS' : 'HEADQUARTERS',
          style: const TextStyle(
            color: _blue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          heading,
          style: const TextStyle(
            color: _ink,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          viewDescription(
            selectedView,
            isBranch: role.isBranch,
            role: role.name,
          ),
          style: const TextStyle(color: _muted, fontSize: 14),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const _ChipLabel(label: '화면 시안 · 시연 데이터', highlighted: true),
        _ChipLabel(label: date),
        PopupMenuButton<StaffRole>(
          key: const Key('role-selector'),
          tooltip: '직책별 대시보드 보기',
          onSelected: _selectRole,
          itemBuilder: (context) => widget.availableRoles
              .map(
                (value) =>
                    PopupMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          child: _ChipLabel(label: '${role.label}  ▾', highlighted: true),
        ),
        if (role.isBranch && widget.availableBranches.isNotEmpty)
          widget.availableBranches.length == 1
              ? _ChipLabel(label: widget.branch)
              : PopupMenuButton<int>(
                  key: const Key('branch-selector'),
                  tooltip: '소속 지점 선택',
                  onSelected: widget.onSelectBranch,
                  itemBuilder: (context) => widget.availableBranches.entries
                      .map(
                        (entry) => PopupMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  child: _ChipLabel(label: '${widget.branch}  ▾'),
                ),
        OutlinedButton(onPressed: widget.onSignOut, child: const Text('로그아웃')),
      ],
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 16), actions],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        Flexible(
          child: Align(alignment: Alignment.topRight, child: actions),
        ),
      ],
    );
  }

  Widget _alerts() {
    final alerts = switch (role) {
      StaffRole.branchStaff || StaffRole.branchManager => const [
        ('대리점 도착 · 고객 인도 대기', '입고 완료 주문 2건 · 픽업 결제 코드와 실물을 확인하세요.'),
        ('배송 중 · 입고 확인 필요', '배송 중 주문 2건 · 실제 도착 후 입고 처리하세요.'),
        ('교환품 입고·인도 확인', '진행 중인 교환품 1건의 상태를 확인하세요.'),
      ],
      StaffRole.hqStaff => const [
        ('새 주문 · 발송 필요', '3건의 주문을 희망 대리점으로 보내세요.'),
        ('교환품 발송 요청', '1건의 교환품이 발송을 기다립니다.'),
        ('재고 부족 · 데일리 스니커즈', '재고율 24% · 구매 품의를 작성하세요.'),
      ],
      StaffRole.teamLeader => const [
        ('품의 작성 · 1차 결재 요청', 'PR-2026-019 · 로퍼 60켤레'),
        ('고객 혜택 승인 요청', '1건의 혜택 요청이 검토를 기다립니다.'),
      ],
      StaffRole.director => const [
        ('팀장 승인 · 최종 결재 요청', 'PR-2026-018 · 데일리 스니커즈 100켤레'),
        ('최종 승인 → 발주 진행', '제조사 발주 1건이 생성되었습니다.'),
      ],
      StaffRole.executive => const [
        ('재고 부족 상품', '데일리 스니커즈의 본사 재고가 목표의 30% 미만입니다.'),
        ('발주 진행', '최종 승인된 제조사 발주 1건을 확인하세요.'),
      ],
    };
    return _Panel(
      title: '업무 알림 · ${alerts.length}개',
      subtitle: '현재 직책의 주요 업무를 미리 보여줍니다.',
      trailing: '전체 알림 →',
      child: Column(
        children: [
          for (final (title, description) in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF264B7A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roleSections() => switch (role) {
    StaffRole.branchStaff || StaffRole.branchManager => _branchSections(),
    StaffRole.hqStaff => _hqSections(),
    StaffRole.teamLeader || StaffRole.director => _approvalSections(),
    StaffRole.executive => _executiveSections(),
  };

  Widget _branchSections() {
    final manager = role == StaffRole.branchManager;
    return Column(
      children: [
        _ResponsivePair(
          first: _Panel(
            title: '입고 확인할 주문',
            subtitle: '배송 중 전체 목록 · 실물 도착 후 입고 확인',
            trailing: '전체 보기 →',
            child: const Column(
              children: [
                _OrderTile(
                  id: 'ORD-1043',
                  name: '데일리 스니커즈',
                  detail: '화이트 / 260 · 강남구 대리점 · 1켤레',
                  status: '배송 중',
                  statusColor: _blue,
                ),
                SizedBox(height: 10),
                _OrderTile(
                  id: 'ORD-1037',
                  name: '러닝화',
                  detail: '그레이 / 270 · 강남구 대리점 · 1켤레',
                  status: '배송 중',
                  statusColor: _blue,
                ),
              ],
            ),
          ),
          second: _Panel(
            title: '고객 수령 대기',
            subtitle: '픽업 결제 코드 확인 후 고객·상품·지점을 확인하세요.',
            trailing: '픽업 코드 확인 →',
            child: const Column(
              children: [
                _OrderTile(
                  id: 'ORD-1038',
                  name: '캔버스화',
                  detail: '네이비 / 250 · 김민수 · 강남구 대리점',
                  status: '입고 완료',
                  statusColor: _green,
                ),
                SizedBox(height: 10),
                _OrderTile(
                  id: 'ORD-1032',
                  name: '로퍼',
                  detail: '블랙 / 255 · 이지은 · 강남구 대리점',
                  status: '입고 완료',
                  statusColor: _green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ResponsivePair(
          first: _Panel(
            title: '반품·교환 확인',
            subtitle: '반품은 현장 접수 · 교환은 고객 인도까지 추적',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderTile(
                  id: 'EX-2026-000',
                  name: '캔버스화 교환',
                  detail: '사이즈 변경 · 강남구 대리점',
                  status: '본사 발송 대기',
                  statusColor: _red,
                ),
                SizedBox(height: 12),
                Text(
                  '반품은 고객 방문 시 접수와 완료를 함께 처리합니다.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          second: manager
              ? _Panel(
                  title: '지점 재고 점검',
                  subtitle: '초기 보관량 대비 30% 미만인 상품',
                  trailing: '날짜별 재고 →',
                  child: const Column(
                    children: [
                      _StockRow(
                        name: '데일리 스니커즈',
                        amount: '6 / 22켤레',
                        ratio: 0.27,
                      ),
                      _StockRow(name: '러닝화', amount: '31 / 31켤레', ratio: 1),
                      _StockRow(name: '로퍼', amount: '18 / 18켤레', ratio: 1),
                    ],
                  ),
                )
              : _Panel(
                  title: '현재 보관 재고',
                  subtitle: '강남구 대리점 · 하단 참고 정보',
                  trailing: '재고 조회 →',
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '94켤레',
                        style: TextStyle(
                          fontSize: 28,
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '입고, 고객 인도와 재판매 가능한 반품·교환 회수를 반영한 시연 수치입니다.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _hqSections() => _ResponsivePair(
    first: _Panel(
      title: '고객 구매 요청',
      subtitle: '구매 완료 후 발송 업무가 생성됩니다.',
      trailing: '전체 주문 →',
      child: const Column(
        children: [
          _OrderTile(
            id: 'ORD-1045',
            name: '데일리 스니커즈',
            detail: '화이트 / 260 · 강남구 대리점 · 1켤레',
            status: '발송 대기',
            statusColor: _red,
          ),
          SizedBox(height: 10),
          _OrderTile(
            id: 'ORD-1044',
            name: '러닝화',
            detail: '그레이 / 270 · 마포구 대리점 · 1켤레',
            status: '발송 대기',
            statusColor: _red,
          ),
          SizedBox(height: 10),
          _OrderTile(
            id: 'ORD-1042',
            name: '로퍼',
            detail: '블랙 / 255 · 송파구 대리점 · 1켤레',
            status: '발송 대기',
            statusColor: _red,
          ),
        ],
      ),
    ),
    second: _Panel(
      title: '재고 경고',
      subtitle: '목표 보유량 대비 30% 미만 기준',
      child: const Column(
        children: [
          _OrderTile(
            id: '데일리 스니커즈',
            name: '현재 24켤레 / 목표 100켤레',
            detail: '구매 품의 검토가 필요합니다.',
            status: '24%',
            statusColor: _red,
          ),
          SizedBox(height: 14),
          _HintBanner(text: '재고가 부족한 상품은 구매 품의 화면에서 보충 수량을 요청합니다.'),
        ],
      ),
    ),
  );

  Widget _approvalSections() {
    final team = role == StaffRole.teamLeader;
    return Column(
      children: [
        const _ApprovalFlow(),
        const SizedBox(height: 18),
        _ResponsivePair(
          first: _Panel(
            title: team ? '구매 품의 1차 검토' : '구매 품의 최종 검토',
            subtitle: '품의 상세 내용과 결재 단계를 확인하세요.',
            trailing: '결재함 보기 →',
            child: _OrderTile(
              id: team ? 'PR-2026-019' : 'PR-2026-018',
              name: team ? '로퍼 · 60켤레' : '데일리 스니커즈 · 100켤레',
              detail: team ? '가을 판매 수요 대비 선제 확보' : '목표 재고 대비 24%로 30% 미만',
              status: team ? '팀장 결재 대기' : '이사 결재 대기',
              statusColor: _blue,
            ),
          ),
          second: _Panel(
            title: team ? '지점 운영 이슈' : '결재 현황',
            subtitle: team ? '대리점장이 전달한 업무를 확인하세요.' : '최종 승인 후 제조사 발주가 생성됩니다.',
            child: team
                ? const _OrderTile(
                    id: '강동구',
                    name: '교환품 수령 안내 기준',
                    detail: '입고 후 고객 안내 시점을 확인해 주세요.',
                    status: '확인 필요',
                    statusColor: _red,
                  )
                : const Column(
                    children: [
                      _StockRow(name: '최종 승인·발주', amount: '1건', ratio: 0.7),
                      _StockRow(name: '최종 결재 대기', amount: '1건', ratio: 0.4),
                      _StockRow(name: '최종 반려', amount: '0건', ratio: 0),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _executiveSections() => Column(
    children: const [
      _ResponsivePair(
        first: _Panel(
          title: '일자별 판매 추이',
          subtitle: '최근 28일 · 전체 제품·대리점 · 켤레',
          trailing: '상세 분석 →',
          child: _SalesChart(),
        ),
        second: _Panel(
          title: '제품별 판매',
          subtitle: '최근 28일 · 전체 대리점 · 켤레',
          child: Column(
            children: [
              _StockRow(name: '데일리 스니커즈', amount: '42', ratio: 0.86),
              _StockRow(name: '러닝화', amount: '37', ratio: 0.76),
              _StockRow(name: '로퍼', amount: '28', ratio: 0.58),
              _StockRow(name: '캔버스화', amount: '21', ratio: 0.43),
            ],
          ),
        ),
      ),
      SizedBox(height: 18),
      _ResponsivePair(
        first: _Panel(
          title: '지점별 판매 현황',
          subtitle: '최근 28일 · 서울 주요 지점 · 켤레',
          child: Column(
            children: [
              _StockRow(name: '강남구', amount: '26', ratio: 1),
              _StockRow(name: '마포구', amount: '19', ratio: 0.73),
              _StockRow(name: '송파구', amount: '12', ratio: 0.46),
              _StockRow(name: '서초구', amount: '10', ratio: 0.38),
            ],
          ),
        ),
        second: _Panel(
          title: '제품별 반품률',
          subtitle: '최근 28일 주문 대비 반품 완료 비율',
          child: Column(
            children: [
              _StockRow(
                name: '데일리 스니커즈',
                amount: '2.4%',
                ratio: 0.24,
                color: _red,
              ),
              _StockRow(name: '러닝화', amount: '2.1%', ratio: 0.21, color: _red),
              _StockRow(name: '로퍼', amount: '0%', ratio: 0, color: _red),
              _StockRow(name: '캔버스화', amount: '3.1%', ratio: 0.31, color: _red),
            ],
          ),
        ),
      ),
    ],
  );
}

class _MetricInfo {
  const _MetricInfo(this.label, this.value, this.caption, [this.tone = _ink]);
  final String label;
  final String value;
  final String caption;
  final Color tone;
}

List<_MetricInfo> _metricsFor(StaffRole role) => switch (role) {
  StaffRole.branchStaff => const [
    _MetricInfo('오늘 입고 예정', '2건', '등록된 오늘 도착 예정'),
    _MetricInfo('고객 수령 대기', '2건', '일반 주문·교환품 픽업 코드 확인'),
    _MetricInfo('반품 대기', '0건', '방문 접수 즉시 처리'),
    _MetricInfo('교환 진행', '1건', '본사 발송·입고·인도'),
  ],
  StaffRole.branchManager => const [
    _MetricInfo('오늘 입고', '2건', '입고 처리 기록 · 교환 포함'),
    _MetricInfo('수령 미완료', '2건', '입고 후 고객 인도 대기', _red),
    _MetricInfo('반품·교환 진행', '1건', '교환 진행 상황'),
    _MetricInfo('재고 부족 상품', '1종', '초기 보관량의 30% 미만', _red),
  ],
  StaffRole.hqStaff => const [
    _MetricInfo('발송 대기', '3건', '희망 대리점으로 발송'),
    _MetricInfo('오늘 출고 완료', '2건', '일반 주문·교환품 포함', _green),
    _MetricInfo('교환품 발송 대기', '1건', '대리점 교환 요청'),
    _MetricInfo('재고 부족 상품', '1종', '목표 재고 30% 미만', _red),
  ],
  StaffRole.teamLeader => const [
    _MetricInfo('1차 결재 대기', '1건', '사원 상신 → 팀장 검토', _red),
    _MetricInfo('미해결 지점 이슈', '1건', '대리점장과 운영 이슈 조정', _red),
    _MetricInfo('고객 혜택 승인 대기', '1건', '고객 관리에서 검토'),
    _MetricInfo('재고 부족 상품', '1종', '목표 재고 30% 미만'),
  ],
  StaffRole.director => const [
    _MetricInfo('최종 결재 대기', '1건', '팀장 1차 승인된 품의', _red),
    _MetricInfo('최종 승인·발주', '1건', '최종 승인 시 자동 발주', _green),
    _MetricInfo('최종 반려', '0건', '반려 사유 기록'),
    _MetricInfo('재고 부족 상품', '1종', '최종 검토 참고'),
  ],
  StaffRole.executive => const [
    _MetricInfo('최근 28일 판매량', '128켤레', '전체 제품·대리점'),
    _MetricInfo('매출액', '₩1,280만', '최근 28일 시연 데이터'),
    _MetricInfo('재고 부족 상품', '1종', '목표 재고 30% 미만', _red),
    _MetricInfo('발주 진행', '1건', '최종 승인된 발주', _green),
    _MetricInfo('반품률', '2.1%', '최근 28일 주문 기준'),
  ],
};

class _Metrics extends StatelessWidget {
  const _Metrics({required this.items});
  final List<_MetricInfo> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width <= 0) return const SizedBox.shrink();
      final columns = width >= 900
          ? items.length
          : width >= 400
          ? 2
          : 1;
      const gap = 12.0;
      final cardWidth = (width - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: cardWidth,
              child: _Surface(
                child: SizedBox(
                  height: 118,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF63738B),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.value,
                        maxLines: 1,
                        style: TextStyle(
                          color: item.tone,
                          fontSize: cardWidth < 180 ? 25 : 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        item.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7C8AA0),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.role,
    required this.employeeName,
    required this.branch,
    required this.selectedView,
    required this.onSelect,
    required this.onSignOut,
    this.inDrawer = false,
  });
  final StaffRole role;
  final String employeeName;
  final String branch;
  final StaffView selectedView;
  final ValueChanged<StaffView> onSelect;
  final VoidCallback onSignOut;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final items = menusForRole(role.name);
    return ColoredBox(
      color: _navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 28, 14, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3175EE),
                      borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHOEPICK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                      Text(
                        'STAFF TABLET',
                        style: TextStyle(
                          color: Color(0xFFA9C0E5),
                          fontSize: 10,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C3C70),
                  border: Border.all(color: const Color(0xFF315182)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 접속',
                      style: TextStyle(color: Color(0xFFA9C0E5), fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$employeeName · ${role.label}${role.isBranch ? ' · $branch' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    '업무 메뉴',
                    style: TextStyle(
                      color: Color(0xFF8FAAD2),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = item.view == selectedView;
                    return InkWell(
                      key: Key('menu-${item.view.name}'),
                      onTap: () {
                        onSelect(item.view);
                        if (inDrawer) Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 19,
                              color: selected
                                  ? const Color(0xFF124B9E)
                                  : const Color(0xFFD7E3F8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF124B9E)
                                      : const Color(0xFFD7E3F8),
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              OutlinedButton(
                onPressed: onSignOut,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('로그아웃'),
              ),
              const SizedBox(height: 8),
              const Text(
                '업무 화면은 시연 데이터입니다.\n처리 기능은 차례로 연결됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9CB3D6),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletRail extends StatelessWidget {
  const _TabletRail({
    required this.role,
    required this.selectedView,
    required this.onSelect,
    required this.onSignOut,
  });

  final StaffRole role;
  final StaffView selectedView;
  final ValueChanged<StaffView> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final items = menusForRole(role.name);
    return ColoredBox(
      color: _navy,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(0xFF3175EE),
                borderRadius: BorderRadius.all(Radius.circular(13)),
              ),
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = selectedView == item.view;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Tooltip(
                      message: item.label,
                      child: Material(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          key: Key('menu-${item.view.name}'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onSelect(item.view),
                          child: SizedBox(
                            height: 64,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 23,
                                  color: selected
                                      ? const Color(0xFF124B9E)
                                      : const Color(0xFFD7E3F8),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: selected
                                        ? const Color(0xFF124B9E)
                                        : const Color(0xFFD7E3F8),
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              onPressed: onSignOut,
              tooltip: '로그아웃',
              icon: const Icon(
                Icons.manage_accounts_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label, this.highlighted = false});
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: highlighted ? const Color(0xFFE8F1FF) : Colors.white,
      border: Border.all(color: highlighted ? const Color(0xFFD5E6FF) : _line),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: highlighted ? const Color(0xFF174A99) : const Color(0xFF52637E),
        fontSize: 12,
        fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
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
    child: child,
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 860) {
        return Column(children: [first, const SizedBox(height: 18), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: first),
          const SizedBox(width: 18),
          Expanded(flex: 2, child: second),
        ],
      );
    },
  );
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.id,
    required this.name,
    required this.detail,
    required this.status,
    required this.statusColor,
  });
  final String id;
  final String name;
  final String detail;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE2E9F2)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                id,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(detail, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    ),
  );
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.name,
    required this.amount,
    required this.ratio,
    this.color = _blue,
  });
  final String name;
  final String amount;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 105,
          child: Text(
            name,
            maxLines: 2,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: const Color(0xFFE7EFF9),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 65,
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FF),
      border: Border.all(color: const Color(0xFFCFE2FF)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFF315C94), fontSize: 12),
    ),
  );
}

class _ApprovalFlow extends StatelessWidget {
  const _ApprovalFlow();

  @override
  Widget build(BuildContext context) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '구매 품의 결재 흐름',
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            _FlowStep('사원 상신', done: true),
            Icon(Icons.arrow_forward, size: 15, color: _muted),
            _FlowStep('팀장 1차 결재', active: true),
            Icon(Icons.arrow_forward, size: 15, color: _muted),
            _FlowStep('이사 최종 결재'),
            Icon(Icons.arrow_forward, size: 15, color: _muted),
            _FlowStep('제조사 발주'),
          ],
        ),
      ],
    ),
  );
}

class _FlowStep extends StatelessWidget {
  const _FlowStep(this.label, {this.active = false, this.done = false});
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: done
          ? const Color(0xFFE5F6EE)
          : active
          ? const Color(0xFFE6F0FF)
          : const Color(0xFFEEF4FC),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: done
            ? const Color(0xFF117453)
            : active
            ? const Color(0xFF125EC2)
            : const Color(0xFF64758D),
        fontSize: 11,
        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
      ),
    ),
  );
}

class _SalesChart extends StatelessWidget {
  const _SalesChart();

  @override
  Widget build(BuildContext context) {
    const values = [
      34.0,
      58.0,
      45.0,
      71.0,
      62.0,
      87.0,
      69.0,
      95.0,
      76.0,
      100.0,
      82.0,
      91.0,
      73.0,
      86.0,
    ];
    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: values[i] * 1.45,
                      decoration: BoxDecoration(
                        color: i == values.length - 1
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
