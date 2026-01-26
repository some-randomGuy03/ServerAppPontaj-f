import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_log.dart';
import '../models/elev.dart';
import '../services/admin_service.dart';
import '../l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  final String token;

  const ReportsScreen({super.key, required this.token});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  // Scans State
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<ScanLog>? _scans;
  bool _isLoadingScans = false;
  String? _scansError;

  // Enrolled Students State
  List<Elev>? _enrolledStudents;
  bool _isLoadingStudents = false;
  String? _studentsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEnrolledStudents();
    _fetchScans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchScans() async {
    setState(() {
      _isLoadingScans = true;
      _scansError = null;
    });

    try {
      final response = await _adminService.getScansByDate(
        widget.token,
        _startDate,
        _endDate,
      );
      setState(() {
        _scans = response.data;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _scansError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingScans = false;
        });
      }
    }
  }

  Future<void> _fetchEnrolledStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _studentsError = null;
    });

    try {
      final response = await _adminService.getEleviEnrolled(widget.token);
      setState(() {
        _enrolledStudents = response.elevi;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _studentsError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchScans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('EEEE, d MMMM', l10n.localeName).format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS System Gray 6
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              backgroundColor: const Color(0xFFF2F2F7),
              surfaceTintColor: Colors.transparent,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 50),
                title: Text(
                  l10n.reports,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      bottom: 84, // Adjusted position to be above tabs
                      child: Text(
                        dateStr.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.blue[600],
                    labelColor: Colors.blue[600],
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(
                        text: l10n.scanHistory,
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                      Tab(
                        text: l10n.enrolledStudents,
                        icon: const Icon(Icons.people),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildScansTab(), _buildEnrolledStudentsTab()],
        ),
      ),
    );
  }

  Widget _buildScansTab() {
    final l10n = AppLocalizations.of(context)!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dateRange,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _selectDateRange(context),
                        icon: const Icon(Icons.edit_calendar, size: 16),
                        label: const Text('Change'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[700],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _fetchScans,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.searchLogs),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoadingScans)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_scansError != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Error: $_scansError',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else if (_scans == null || _scans!.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noScansFound,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final scan = _scans![index];
                final isFirst = index == 0;
                final isLast = index == _scans!.length - 1;

                return _AnimatedListItem(
                  index: index,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: isFirst ? const Radius.circular(20) : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(20)
                            : Radius.zero,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            scan.name.isNotEmpty
                                ? scan.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        scan.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${scan.idElev}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('HH:mm:ss').format(scan.scanTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat('yyyy-MM-dd').format(scan.scanTime),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: _scans!.length),
            ),
          ),
      ],
    );
  }

  Widget _buildEnrolledStudentsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_studentsError != null) {
      return Center(child: Text('Error: $_studentsError'));
    }
    if (_enrolledStudents == null || _enrolledStudents!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              l10n.noEnrolledStudents,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final elev = _enrolledStudents![index];
              final isFirst = index == 0;
              final isLast = index == _enrolledStudents!.length - 1;
              final bool isActive = elev.activ == 1;

              return _AnimatedListItem(
                index: index,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(20) : Radius.zero,
                      bottom: isLast ? const Radius.circular(20) : Radius.zero,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          elev.name.isNotEmpty
                              ? elev.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: isActive
                                ? Colors.green[700]
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            elev.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? l10n.active : l10n.inactive,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          elev.email,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${l10n.codMatricol}: ${elev.codMatricol}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Show details?
                    },
                  ),
                ),
              );
            }, childCount: _enrolledStudents!.length),
          ),
        ),
      ],
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({required this.index, required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_animation);

    if (widget.index < 10) {
      Future.delayed(Duration(milliseconds: widget.index * 50), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
