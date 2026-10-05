import 'package:flutter/material.dart';
import 'package:shupick_staff/dashboard/staff_pages.dart';
import 'package:shupick_staff/dashboard/staff_overview.dart';
import 'package:shupick_staff/dashboard/staff_views.dart';

const _navy = Color(0xFF102B58);
const _blue = Color(0xFF1768E9);
const _ink = Color(0xFF14243E);
const _muted = Color(0xFF718098);
const _line = Color(0xFFDCE5F0);

enum StaffRole {
  branchStaff('대리점 직원', '입고·픽업 결제 코드 확인·반품 현황', true),
  branchManager('대리점장', '지점 재고와 입고·픽업 업무', true),
  hqStaff('본사 사원', '주문·고객 문의·배송·구매 품의', false),
  teamLeader('본사 팀장', '구매 품의 결재와 재고 조회', false),
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
    required this.selectedBranchId,
    required this.availableBranches,
    required this.onSelectBranch,
    required this.onSignOut,
  });

  final StaffRole initialRole;
  final List<StaffRole> availableRoles;
  final String employeeName;
  final String branch;
  final int? selectedBranchId;
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
                              if (selectedView == StaffView.overview)
                                StaffOverview(
                                  key: ValueKey(
                                    '${role.name}-overview-${widget.selectedBranchId}',
                                  ),
                                  roleKey: role.name,
                                  selectedBranchId: widget.selectedBranchId,
                                  onOpenView: _selectView,
                                )
                              else
                                StaffPage(
                                  key: ValueKey(
                                    '${role.name}-${selectedView.name}-${widget.selectedBranchId}',
                                  ),
                                  view: selectedView,
                                  roleKey: role.name,
                                  isBranch: role.isBranch,
                                  selectedBranchId: widget.selectedBranchId,
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
        const _ChipLabel(label: '서버 업무 현황', highlighted: true),
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
