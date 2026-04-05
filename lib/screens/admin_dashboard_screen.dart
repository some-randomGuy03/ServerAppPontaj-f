import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pontaj_admin/l10n/app_localizations.dart';
import '../models/professor.dart';
import '../models/elev.dart';
import '../models/scan_log.dart';
import '../services/admin_service.dart';
import '../services/elev_service.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
import '../utils/csv_downloader.dart';
import '../utils/apk_downloader.dart';
import '../widgets/language_switcher.dart';
import '../widgets/hero_background.dart';
import '../widgets/floating_stats_sidebar.dart';
import 'dart:ui';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'debug_screen.dart';

enum ChartPeriod { day, week, month }

class AdminDashboardScreen extends StatefulWidget {
  final String token;
  final String username;
  final int adminStatus;

  const AdminDashboardScreen({
    super.key,
    required this.token,
    required this.username,
    this.adminStatus = 0,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _adminService = AdminService();
  final _elevService = ElevService();
  final _authService = AuthService();
  late Future<AdminListResponse> _adminsFuture;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  List<Professor> _currentAdmins = [];
  List<Elev> _currentElevi = []; // Enrolled students
  List<Elev> _allElevi = []; // All students

  // Search and Collapse state
  late int _adminStatus;
  final TextEditingController _adminSearchController = TextEditingController();
  final TextEditingController _elevSearchController = TextEditingController();

  // Report/Scan State - Calendar Booking Interface
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  // Time interval filtering
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);

  bool _isHistoryExpanded = true;
  List<ScanLog>? _scans;
  bool _isLoadingScans = false;
  String? _scansError;
  List<FlSpot> _weeklyActivitySpots = [];
  bool _isLoadingActivity = false;

  // Student search in scans
  final TextEditingController _scanSearchController = TextEditingController();
  List<int> _selectedStudentFilters = [];

  // Chart state
  // --- Analytics Chart State ---
  ChartPeriod _chartPeriod = ChartPeriod.week; // Current timeframe: Day, Week, or Month
  bool _isChartRolling = false; // Toggle: Start of period (Calendar) vs Last X days (Rolling)
  List<ScanLog>? _chartScans; // Cached raw analysis data from the last API call
  bool _isLoadingCharts = false; // Spinner flag for async data fetching
  List<FlSpot> _uniqueStudentsSpots = []; // Prepared coordinate points for the unique students line chart
  List<double> _totalScansRaw = []; // Raw aggregation values for the pillar chart (Reactive)
  List<BarChartGroupData> _totalScansBarGroups = []; // Prepared bar groups for the total pillar chart
  List<BarChartGroupData> _hourlyDistributionBarGroups = []; // Prepared groups for the activity heatmap


  void _showStudentFilterDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Show ALL enrolled students, not just those with scans
    final sortedStudents = List<Elev>.from(_currentElevi)
      ..sort((a, b) => a.name.compareTo(b.name));


    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(l10n.filterStudents),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    TextField(
                      controller: _scanSearchController,
                      onChanged: (val) => setDialogState((){}),
                      decoration: InputDecoration(
                        hintText: l10n.searchByStudentName,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: sortedStudents.where((student) {
                          return _scanSearchController.text.isEmpty ||
                              student.name.toLowerCase().contains(_scanSearchController.text.toLowerCase());
                        }).map((student) {
                          final isSelected = _selectedStudentFilters.contains(student.id);
                          return CheckboxListTile(
                            title: Text(student.name),
                            subtitle: Text('ID: ${student.id}'),
                            value: isSelected,
                            activeColor: Theme.of(context).colorScheme.secondary,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  _selectedStudentFilters.add(student.id);
                                } else {
                                  _selectedStudentFilters.remove(student.id);
                                }
                              });
                              setState(() {}); 
                              _processChartData(); // Update charts when filter changes
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedStudentFilters.clear();
                    });
                    setState(() {});
                  },
                  child: Text(l10n.clear, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.close),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Scan Statistics State
  int _scansToday = 0;
  int _scansCurrentWeek = 0;
  int _scansRollingWeek = 0;
  int _scansCurrentMonth = 0;
  int _scansRollingMonth = 0;
  bool _isLoadingStats = false;

  bool _useRollingWeekStats = false;
  bool _useRollingMonthStats = false;

  // Double tap logic for calendar
  DateTime? _lastTapTime;
  DateTime? _lastTapDay;
  Timer? _singleTapTimer;

  @override
  void initState() {
    super.initState();
    _adminStatus = widget.adminStatus;
    print(
      'DEBUG: AdminDashboardScreen initialized with adminStatus: $_adminStatus',
    );
    WidgetsBinding.instance.addObserver(this);
    _refreshList();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _singleTapTimer?.cancel();
    _fabController.dispose();
    _adminSearchController.dispose();
    _elevSearchController.dispose();
    _scanSearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshList();
    }
  }

  Future<void> _handleDoubleTap(DateTime date, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Determine the state of our interval
    if (_rangeStart != null && _rangeEnd != null) {
      if (isSameDay(date, _rangeStart)) {
        // Double tapped the start date
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _startTime,
          helpText: l10n.startTime,
        );
        if (picked != null) {
          setState(() => _startTime = picked);
          _fetchScans();
        }
      } else if (isSameDay(date, _rangeEnd)) {
        // Double tapped the end date
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _endTime,
          helpText: l10n.endTime,
        );
        if (picked != null) {
          setState(() {
            _endTime = picked;
          });
          _fetchScans();
        }
      }
    } else {
      // It's just a single day selected or no interval selected
      await _showTwoHoursPickerDialog(context);
    }
  }

  Future<void> _showTwoHoursPickerDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    TimeOfDay tempStart = _startTime;
    TimeOfDay tempEnd = _endTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(l10n.selectTimeInterval),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.schedule, color: Theme.of(context).colorScheme.secondary),
                    title: Text(l10n.startTime),
                    trailing: Text(tempStart.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: tempStart,
                        helpText: l10n.startTime,
                      );
                      if (picked != null) {
                        setDialogState(() => tempStart = picked);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.event_busy, color: Theme.of(context).colorScheme.secondary),
                    title: Text(l10n.endTime),
                    trailing: Text(tempEnd.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: tempEnd,
                        helpText: l10n.endTime,
                      );
                      if (picked != null) {
                        setDialogState(() => tempEnd = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.apply),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() {
        _startTime = tempStart;
        _endTime = tempEnd;
      });
      _fetchScans();
    }
  }

  void _refreshList() {
    setState(() {
      _adminsFuture = _fetchAdmins();
      _fetchElevi().then((_) {
        if (mounted) setState(() {});
      });
      _fetchScans();
      _fetchScanStatistics();
      _fetchChartData();
    });
  }

  Future<AdminListResponse> _fetchAdmins() async {
    try {
      final response = await _adminService.getProfessors(widget.token);
      _currentAdmins = response.admins;

      // Update admin status based on the list
      try {
        final currentUser = response.admins.firstWhere(
          (admin) =>
              admin.name == widget.username || admin.email == widget.username,
          orElse: () => Professor(id: 0, email: '', name: '', admin: 0),
        );

        if (currentUser.id != 0 && currentUser.admin != _adminStatus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _adminStatus = currentUser.admin;
              });
              print('DEBUG: Updated admin status from list: $_adminStatus');
            }
          });
        }
      } catch (e) {
        print('DEBUG: Error matching admin user: $e');
      }

      return response;
    } catch (e) {
      if (e.toString().contains('401')) {
        // Token expired or invalid
        if (mounted) {
          _handleLogout();
        }
      }
      rethrow;
    }
  }

  Future<void> _fetchElevi() async {
    try {
      // Fetch Enrolled - for the bottom list
      final enrolledResponse = await _elevService.getEleviEnrolled(
        widget.token,
      );
      _currentElevi = enrolledResponse.elevi;

      // Fetch All - for the stats card and modal
      final allResponse = await _elevService.getElevi(widget.token);
      _allElevi = allResponse.elevi;
    } catch (e) {
      print('Error fetching elevi: $e');
    }
  }

  Future<void> _fetchScans() async {
    setState(() {
      _isLoadingScans = true;
      _scansError = null;
    });

    try {
      // Calculate start and end dates based on calendar range selection
      final DateTime startDate;
      final DateTime endDate;

      if (_rangeStart != null && _rangeEnd != null) {
        // Date range selected — fetch from rangeStart to rangeEnd (inclusive)
        startDate = DateTime(
          _rangeStart!.year,
          _rangeStart!.month,
          _rangeStart!.day,
        );
        // Add 1 day to make the end date inclusive
        endDate = DateTime(
          _rangeEnd!.year,
          _rangeEnd!.month,
          _rangeEnd!.day,
        ).add(const Duration(days: 1));
      } else if (_rangeStart != null) {
        // Single day selected (only rangeStart set, no rangeEnd yet)
        startDate = DateTime(
          _rangeStart!.year,
          _rangeStart!.month,
          _rangeStart!.day,
        );
        endDate = startDate.add(const Duration(days: 1));
      } else {
        // No selection — fetch for the currently focused month
        startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
        endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      }

      final response = await _adminService.getScansByDate(
        widget.token,
        startDate,
        endDate,
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

  /// Fetches raw scan data (all students) for the selected timeframe.
  /// Results are cached in [_chartScans] to allow instant re-processing when filters are toggled.
  Future<void> _fetchChartData() async {
    setState(() => _isLoadingCharts = true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      DateTime rangeStart;
      switch (_chartPeriod) {
        case ChartPeriod.day:
          rangeStart = today;
          break;
        case ChartPeriod.week:
          // Rolling Week = last 7 full days. Calendar Week = since Monday.
          rangeStart = _isChartRolling 
            ? today.subtract(const Duration(days: 7))
            : today.subtract(Duration(days: today.weekday - 1));
          break;
        case ChartPeriod.month:
          // Rolling Month = last 30 full days. Calendar Month = since 1st of month.
          rangeStart = _isChartRolling
            ? today.subtract(const Duration(days: 30))
            : DateTime(now.year, now.month, 1);
          break;
      }

      // Fetch broad range from API (Server filter is by Date alone)
      final response = await _adminService.getScansByDate(widget.token, rangeStart, tomorrow);
      _chartScans = response.data;

      // Transform raw data into visible chart spots/bars
      _processChartData();
    } catch (e) {
      print('Error fetching chart data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCharts = false);
    }
  }

  /// Organizes the cached [_chartScans] into UI-ready chart data.
  /// This is called both after fetching and whenever the student filter is updated.
  void _processChartData() {
    if (_chartScans == null) return;
    
    // Step 1: Filter the cached data by the selected student set
    final scans = _chartScans!.where((s) => 
      _selectedStudentFilters.isEmpty || _selectedStudentFilters.contains(s.idElev)
    ).toList();

    // Step 2: Delegate to daily or multi-day aggregation logic
    if (_chartPeriod == ChartPeriod.day) {
      _processDailyChart(scans);
    } else {
      _processMultiDayChart(scans);
    }
  }

  void _processDailyChart(List<ScanLog> scans) {
    final spots = <FlSpot>[];
    final barGroups = <BarChartGroupData>[];
    final hourlyUnique = Map<int, Set<int>>.fromIterable(
      List.generate(24, (i) => i), key: (i) => i, value: (_) => {}
    );
    final totalCounts = Map<int, int>.fromIterable(
      List.generate(24, (i) => i), key: (i) => i, value: (_) => 0
    );

    for (var s in scans) {
      hourlyUnique[s.scanTime.hour]?.add(s.idElev);
      totalCounts[s.scanTime.hour] = (totalCounts[s.scanTime.hour] ?? 0) + 1;
    }

    final accentColor = Theme.of(context).colorScheme.secondary;
    final rawTotals = <double>[];

    for (int i = 0; i < 24; i++) {
      final count = totalCounts[i]!.toDouble();
      spots.add(FlSpot(i.toDouble(), hourlyUnique[i]!.length.toDouble()));
      rawTotals.add(count);
      barGroups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: count, 
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withOpacity(0.4)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        )
      ]));
    }
    if (mounted) {
      setState(() {
        _uniqueStudentsSpots = spots;
        _totalScansRaw = rawTotals;
        _totalScansBarGroups = barGroups;
      });
    }
  }

  void _processMultiDayChart(List<ScanLog> scans) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int days = _chartPeriod == ChartPeriod.week ? (_isChartRolling ? 7 : today.weekday) : (_isChartRolling ? 30 : today.day);
    
    final dailyUnique = List.generate(days, (_) => <int>{});
    final dailyTotal = List.generate(days, (_) => 0);
    
    final startDate = _chartPeriod == ChartPeriod.week 
      ? (_isChartRolling ? today.subtract(const Duration(days: 6)) : today.subtract(Duration(days: today.weekday - 1)))
      : (_isChartRolling ? today.subtract(const Duration(days: 29)) : DateTime(now.year, now.month, 1));

    for (var s in scans) {
      final diff = s.scanTime.difference(startDate).inDays;
      if (diff >= 0 && diff < days) {
        dailyUnique[diff].add(s.idElev);
        dailyTotal[diff]++;
      }
    }

    final accentColor = Theme.of(context).colorScheme.secondary;
    final rawTotals = List.generate(days, (i) => dailyTotal[i].toDouble());

    if (mounted) {
      setState(() {
        _uniqueStudentsSpots = List.generate(days, (i) => FlSpot(i.toDouble(), dailyUnique[i].length.toDouble()));
        _totalScansRaw = rawTotals;
        _totalScansBarGroups = List.generate(days, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: dailyTotal[i].toDouble(), 
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.4)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          )
        ]));
      });
    }
  }

  Future<void> _fetchScanStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final rollingWeekAgo = today.subtract(const Duration(days: 7));
      final rollingMonthAgo = today.subtract(const Duration(days: 30));
      
      final currentWeekStart = today.subtract(Duration(days: today.weekday - 1)); // Monday
      final currentMonthStart = DateTime(now.year, now.month, 1);

      // Fetch all periods in parallel
      final results = await Future.wait([
        _adminService.getScansByDate(widget.token, today, tomorrow),
        _adminService.getScansByDate(widget.token, currentWeekStart, tomorrow),
        _adminService.getScansByDate(widget.token, rollingWeekAgo, tomorrow),
        _adminService.getScansByDate(widget.token, currentMonthStart, tomorrow),
        _adminService.getScansByDate(widget.token, rollingMonthAgo, tomorrow),
      ]);

      if (mounted) {
        setState(() {
          _scansToday = results[0].data.length;
          _scansCurrentWeek = results[1].data.length;
          _scansRollingWeek = results[2].data.length;
          _scansCurrentMonth = results[3].data.length;
          _scansRollingMonth = results[4].data.length;
        });
      }
    } catch (e) {
      print('Error fetching scan statistics: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  void _showProfessorsListModal() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      l10n.professors,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search Bar for Professors
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _adminSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    // Need to listen to controller changes to update filtered list
                    // Alternatively, rely on parent state if controllers update it.
                    // Since _adminSearchController updates _adminSearchQuery in parent,
                    // and we pass filteredAdmins.

                    // Best approach: Use ValueListenableBuilder or just rely on parent rebuilds wont work easily in modal.
                    // Actually, StatefullBuilder + listener on controller is best.

                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _adminSearchController,
                      builder: (context, value, child) {
                        final query = value.text.toLowerCase();
                        final filteredAdmins = _currentAdmins.where((admin) {
                          return admin.name.toLowerCase().contains(query) ||
                              admin.email.toLowerCase().contains(query);
                        }).toList();

                        return ListView.builder(
                          controller: controller,
                          itemCount: filteredAdmins.length,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemBuilder: (context, index) {
                            final admin = filteredAdmins[index];
                            final isFirst = index == 0;
                            final isLast = index == filteredAdmins.length - 1;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.vertical(
                                  top: isFirst
                                      ? const Radius.circular(20)
                                      : Radius.zero,
                                  bottom: isLast
                                      ? const Radius.circular(20)
                                      : Radius.zero,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      admin.name.isNotEmpty
                                          ? admin.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  admin.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(admin.email),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.lock_outline,
                                        color: Colors.orange[400],
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _showChangePasswordDialog(admin);
                                      },
                                      tooltip: l10n.changePassword,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue[400],
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showProfessorDialog(professor: admin);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red[300],
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteProfessor(admin),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentsListModal() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      l10n.students,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _elevSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _elevSearchController,
                  builder: (context, value, child) {
                    final query = value.text.toLowerCase();
                    final filteredElevi = _allElevi.where((elev) {
                      return elev.name.toLowerCase().contains(query) ||
                          elev.email.toLowerCase().contains(query) ||
                          elev.codMatricol.toLowerCase().contains(query);
                    }).toList();

                    return ListView.builder(
                      controller: controller,
                      itemCount: filteredElevi.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        final elev = filteredElevi[index];
                        final isFirst = index == 0;
                        final isLast = index == filteredElevi.length - 1;
                        final bool isActive = elev.activ == 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 1),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.vertical(
                              top: isFirst
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                              bottom: isLast
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
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
                                        ? Colors.green
                                        : Colors.grey,
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
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      l10n.active,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(elev.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue[400],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showElevDialog(elev: elev);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[300],
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteElev(elev),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnrolledStudentsModal() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      l10n.enrolled,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _elevSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _elevSearchController,
                  builder: (context, value, child) {
                    final query = value.text.toLowerCase();
                    final filteredElevi = _currentElevi.where((elev) {
                      return elev.name.toLowerCase().contains(query) ||
                          elev.email.toLowerCase().contains(query) ||
                          elev.codMatricol.toLowerCase().contains(query);
                    }).toList();

                    return ListView.builder(
                      controller: controller,
                      itemCount: filteredElevi.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        final elev = filteredElevi[index];
                        final isFirst = index == 0;
                        final isLast = index == filteredElevi.length - 1;
                        final bool isActive = elev.activ == 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 1),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.vertical(
                              top: isFirst
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                              bottom: isLast
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
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
                                        ? Colors.green
                                        : Colors.grey,
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
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      l10n.active,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(elev.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue[400],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showElevDialog(elev: elev);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[300],
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteElev(elev),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadCsv() {
    final l10n = AppLocalizations.of(context)!;
    if (_currentAdmins.isEmpty) {
      ErrorService().showError(l10n.noDataToExport);
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('PROFESSORS');
    buffer.writeln('ID,Name,Email');
    for (var p in _currentAdmins) {
      buffer.writeln('${p.id},"${p.name}","${p.email}"');
    }

    buffer.writeln('');
    buffer.writeln('');

    buffer.writeln('STUDENTS');
    buffer.writeln('ID,Name,Email,Matricol');
    for (var e in _currentElevi) {
      buffer.writeln('${e.id},"${e.name}","${e.email}","${e.codMatricol}"');
    }

    downloadCsvFile(buffer.toString(), 'professors_stats.csv');
    ErrorService().showSuccess(l10n.statsExportedSuccess);
  }

  void _downloadApk() {
    downloadApk();
  }

  Future<void> _showProfessorDialog({Professor? professor}) async {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = professor != null;
    final nameController = TextEditingController(text: professor?.name ?? '');
    final emailController = TextEditingController(text: professor?.email ?? '');
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? l10n.editProfessor : l10n.addProfessor,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withOpacity(0.8),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Name field
                          _buildInputField(
                            controller: nameController,
                            label: l10n.name,
                            icon: Icons.person,
                            color: Colors.blue,
                            validator: (value) => value?.isEmpty ?? true
                                ? l10n.requiredField
                                : null,
                          ),
                          const SizedBox(height: 12),
                          // Email field
                          _buildInputField(
                            controller: emailController,
                            label: l10n.email,
                            icon: Icons.email,
                            color: Colors.blue,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return l10n.emailRequired;
                              }
                              if (!value!.contains('@') ||
                                  !value.contains('.')) {
                                return l10n.emailInvalid;
                              }
                              return null;
                            },
                          ),
                          if (!isEditing) ...[
                            const SizedBox(height: 12),
                            // Password field
                            _buildInputField(
                              controller: passwordController,
                              label: l10n.password,
                              icon: Icons.lock,
                              color: Colors.blue,
                              obscureText: true,
                              helperText: l10n.passwordMinLength,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return l10n.passwordRequired;
                                }
                                if (value!.length < 6) {
                                  return l10n.passwordMinLength;
                                }
                                return null;
                              },
                            ),
                          ],
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          const SizedBox(height: 20),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.cancel,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (formKey.currentState!
                                              .validate()) {
                                            setState(() => isLoading = true);
                                            try {
                                              if (isEditing) {
                                                await _adminService
                                                    .updateProfessor(
                                                      widget.token,
                                                      professor.id,
                                                      nameController.text,
                                                      emailController.text,
                                                    );
                                              } else {
                                                await _adminService
                                                    .addProfessor(
                                                      widget.token,
                                                      nameController.text,
                                                      emailController.text,
                                                      passwordController.text,
                                                    );
                                              }
                                              if (mounted) {
                                                Navigator.pop(context);
                                                _refreshList();
                                              }
                                            } catch (e) {
                                              // Error is already logged by ErrorService
                                            } finally {
                                              if (mounted)
                                                setState(
                                                  () => isLoading = false,
                                                );
                                            }
                                          }
                                        },
                                  child: Text(
                                    isEditing ? l10n.save : l10n.add,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteProfessor(Professor professor) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteConfirmation(professor.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteProfessor(widget.token, professor.id);
        _refreshList();
        // Success - refresh the list
      } catch (e) {
        // Error is already logged by ErrorService
      }
    }
  }

  Future<void> _showChangePasswordDialog(Professor professor) async {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text('Change Password - ${professor.name}'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: l10n.newPassword,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            helperText: l10n.passwordMinLength,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return l10n.passwordRequired;
                            }
                            if (value!.length < 6) {
                              return l10n.passwordMinLength;
                            }
                            return null;
                          },
                        ),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setState(() => isLoading = true);
                                try {
                                  await _adminService.changePassword(
                                    widget.token,
                                    professor.id,
                                    passwordController.text,
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ErrorService().showSuccess(
                                      'Password changed successfully',
                                    );
                                  }
                                } catch (e) {
                                  // Error is already logged by ErrorService
                                } finally {
                                  if (mounted) {
                                    setState(() => isLoading = false);
                                  }
                                }
                              }
                            },
                      child: Text(l10n.save),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showElevDialog({Elev? elev}) async {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = elev != null;
    final nameController = TextEditingController(text: elev?.name ?? '');
    final emailController = TextEditingController(text: elev?.email ?? '');
    final codMatricolController = TextEditingController(
      text: elev?.codMatricol ?? '',
    );
    int activeStatus = elev?.activ ?? 0;
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? l10n.editStudent : l10n.addStudent,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withOpacity(0.8),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Name field
                            _buildInputField(
                              controller: nameController,
                              label: l10n.name,
                              icon: Icons.person,
                              color: Colors.green,
                              validator: (value) => value?.isEmpty ?? true
                                  ? l10n.requiredField
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            // Email field
                            _buildInputField(
                              controller: emailController,
                              label: l10n.email,
                              icon: Icons.email,
                              color: Colors.green,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return l10n.emailRequired;
                                }
                                if (!value!.contains('@') ||
                                    !value.contains('.')) {
                                  return l10n.emailInvalid;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            // Cod Matricol field
                            _buildInputField(
                              controller: codMatricolController,
                              label: l10n.codMatricol,
                              icon: Icons.badge,
                              color: Colors.green,
                              validator: (value) => value?.isEmpty ?? true
                                  ? l10n.requiredField
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            // Active status switch
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.activeStatus,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  activeStatus == 1
                                      ? l10n.active
                                      : l10n.inactive,
                                  style: TextStyle(
                                    color: activeStatus == 1
                                        ? Colors.green[600]
                                        : Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                                value: activeStatus == 1,
                                activeColor: Colors.green[600],
                                onChanged: (bool value) {
                                  setState(() {
                                    activeStatus = value ? 1 : 0;
                                  });
                                },
                              ),
                            ),
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            const SizedBox(height: 20),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.cancel,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              setState(() => isLoading = true);
                                              try {
                                                if (isEditing) {
                                                  await _elevService.updateElev(
                                                    widget.token,
                                                    elev.id,
                                                    nameController.text,
                                                    emailController.text,
                                                    codMatricolController.text,
                                                    activeStatus,
                                                  );
                                                } else {
                                                  await _elevService.addElev(
                                                    widget.token,
                                                    nameController.text,
                                                    emailController.text,
                                                    codMatricolController.text,
                                                    activeStatus,
                                                  );
                                                }
                                                if (mounted) {
                                                  Navigator.pop(context);
                                                  _refreshList();
                                                }
                                              } catch (e) {
                                                // Error is already logged by ErrorService
                                              } finally {
                                                if (mounted) {
                                                  setState(
                                                    () => isLoading = false,
                                                  );
                                                }
                                              }
                                            }
                                          },
                                    child: Text(
                                      isEditing ? l10n.save : l10n.add,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
      },
    );
  }

  Future<void> _deleteElev(Elev elev) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteConfirmation(elev.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _elevService.deleteElev(widget.token, elev.id);
        _refreshList();
      } catch (e) {
        // Error is already logged by ErrorService
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes (Accent color, Dark Mode) to ensure charts and UI rebuild immediately
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final now = DateTime.now();
    // Localize date format for the dashboard header
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('EEEE, d MMMM', l10n.localeName).format(now);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<AdminListResponse>(
        future: _adminsFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data;
          final admins = data?.admins ?? [];

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.85),
                surfaceTintColor: Colors.transparent,
                floating: false,
                pinned: true,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 88, bottom: 16),
                      title: Text(
                        l10n.dashboard,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          HeroBackground(height: 280),
                          Positioned(
                            left: 88,
                            bottom: 50,
                            child: Text(
                              dateStr.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      centerTitle: false,
                    ),
                  ),
                ),
                actions: [
                  // Language Switcher

                  if (kIsWeb)
                    IconButton(
                      onPressed: _downloadApk,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.android,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                      tooltip: l10n.downloadApk,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'debug':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DebugScreen(),
                              ),
                            );
                            break;
                          case 'csv':
                            _downloadCsv();
                            break;
                          case 'logout':
                            _handleLogout();
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          if (_adminStatus == 1)
                            PopupMenuItem<String>(
                              value: 'debug',
                              child: Row(
                                children: [
                                  const Icon(Icons.bug_report, size: 20),
                                  const SizedBox(width: 12),
                                  Text(l10n.debugConsole),
                                ],
                              ),
                            ),
                          PopupMenuItem<String>(
                            value: 'csv',
                            child: Row(
                              children: [
                                const Icon(Icons.download_rounded, size: 20),
                                const SizedBox(width: 12),
                                Text(l10n.downloadCsv),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),

                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.logout,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.logout,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ],
              ),

              if (isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[

                // Charts Header & Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(88, 24, 24, 8),
                    child: Row(
                      children: [
                        Text(
                          l10n.reports,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor),
                        ),
                        const Spacer(),
                        _buildPeriodSelector(),
                      ],
                    ),
                  ),
                ),

                // Unique Students Chart (Line)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(88, 8, 24, 12),
                    child: _buildActivityChart(),
                  ),
                ),

                // Total Scans Chart (Bar/Pillars)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(88, 12, 24, 12),
                    child: _buildTotalScansChart(),
                  ),
                ),

                // Reports Control & History Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(88, 0, 24, 24),
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isHistoryExpanded = !_isHistoryExpanded;
                              });
                            },
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.scanHistory,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    if (_scans != null && _scans!.isNotEmpty)
                                      Text(
                                        '${_scans!.map((s) => s.idElev).toSet().length} ${l10n.studentsScanned}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Stack(
                                    children: [
                                      const Icon(Icons.filter_list, color: Colors.grey),
                                      if (_selectedStudentFilters.isNotEmpty)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onPressed: () => _showStudentFilterDialog(context),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isHistoryExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          if (_isHistoryExpanded) ...[
                            _buildCalendarBookingInterface(l10n),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Scans List Section
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
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
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
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey[300],
                          ),
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
                    padding: const EdgeInsets.fromLTRB(88, 0, 24, 24),
                    sliver: Builder(
                      builder: (context) {
                        // Filter scans by time interval and search query
                        final filteredScans = _scans!.where((scan) {
                          // Time interval filter
                          final scanHour = scan.scanTime.hour;
                          final scanMinute = scan.scanTime.minute;
                          final scanTimeInMinutes = scanHour * 60 + scanMinute;
                          final startTimeInMinutes =
                              _startTime.hour * 60 + _startTime.minute;
                          final endTimeInMinutes =
                              _endTime.hour * 60 + _endTime.minute;

                          final withinTimeRange =
                              scanTimeInMinutes >= startTimeInMinutes &&
                              scanTimeInMinutes <= endTimeInMinutes;

                          // Student search filter
                          final matchesSearch = _selectedStudentFilters.isEmpty || 
                              _selectedStudentFilters.contains(scan.idElev);

                          return withinTimeRange && matchesSearch;
                        }).toList();

                        // Group filtered scans by student ID
                        final Map<String, List<ScanLog>> groupedScans = {};
                        for (var scan in filteredScans) {
                          final key = '${scan.name}_${scan.idElev}';
                          if (!groupedScans.containsKey(key)) {
                            groupedScans[key] = [];
                          }
                          groupedScans[key]!.add(scan);
                        }

                        final keys = groupedScans.keys.toList();

                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final key = keys[index];
                            final studentScans = groupedScans[key]!;
                            final firstScan = studentScans.first;
                            final isFirst = index == 0;
                            final isLast = index == keys.length - 1;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.vertical(
                                  top: isFirst
                                      ? const Radius.circular(20)
                                      : Radius.zero,
                                  bottom: isLast
                                      ? const Radius.circular(20)
                                      : Radius.zero,
                                ),
                              ),
                              child: ExpansionTile(
                                shape: Border.all(color: Colors.transparent),
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      firstScan.name.isNotEmpty
                                          ? firstScan.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  firstScan.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                subtitle: Text(
                                  'ID: ${firstScan.idElev}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${studentScans.length} scans',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                children: studentScans.map((scan) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.only(
                                      left: 80,
                                      right: 20,
                                      bottom: 8,
                                    ),
                                    title: Text(
                                      DateFormat(
                                        'EEEE, MMM d, yyyy',
                                      ).format(scan.scanTime),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: Text(
                                      DateFormat(
                                        'HH:mm:ss',
                                      ).format(scan.scanTime),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontFamily: 'Monospace',
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }, childCount: keys.length),
                        );
                      },
                    ),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ], // ends else ...[
            ], // ends slivers: [
          ), // ends CustomScrollView
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: FloatingStatsSidebar(
            professorsCount: admins.length,
            studentsCount: _allElevi.length,
            enrolledCount: _currentElevi.length,
            scansToday: _scansToday,
            scansWeek: _useRollingWeekStats ? _scansRollingWeek : _scansCurrentWeek,
            scansMonth: _useRollingMonthStats ? _scansRollingMonth : _scansCurrentMonth,
            weekLabel: _useRollingWeekStats ? '${l10n.scansWeek} ${l10n.sevenDays}' : '${l10n.scansWeek} ${l10n.thisWeek}',
            monthLabel: _useRollingMonthStats ? '${l10n.scansMonth} ${l10n.thirtyDays}' : '${l10n.scansMonth} ${l10n.thisMonth}',
            onTapWeek: () => setState(() => _useRollingWeekStats = !_useRollingWeekStats),
            onTapMonth: () => setState(() => _useRollingMonthStats = !_useRollingMonthStats),
            onTapProfessors: _showProfessorsListModal,
            onTapStudents: _showStudentsListModal,
            onTapEnrolled: _showEnrolledStudentsModal,
            l10n: l10n,
          ),
        ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Dismiss',
              barrierColor: Colors.black54,
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SizedBox(),
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: Dialog(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.add,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black.withOpacity(0.8),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Professor option
                                Material(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showProfessorDialog();
                                    },
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.blue[600],
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              l10n.addProfessor,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey[400],
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 1,
                                  color: Colors.grey.withOpacity(0.15),
                                ),
                                // Student option
                                Material(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showElevDialog();
                                    },
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(12),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.school,
                                              color: Colors.green[600],
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              l10n.addStudent,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey[400],
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
            );
          },
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }


  /// UI Component for toggling between Day, Week, and Month views on the charts.
  /// Also handles the secondary toggle for "Rolling" vs "Calendar" views.
  Widget _buildPeriodSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day Selector
          _PeriodChip(
            label: l10n.day,
            isSelected: _chartPeriod == ChartPeriod.day,
            onTap: () {
              setState(() {
                _chartPeriod = ChartPeriod.day;
                _isChartRolling = false;
              });
              _fetchChartData();
            },
          ),
          // Week Selector (including Rolling Toggle)
          _PeriodChip(
            label: _chartPeriod == ChartPeriod.week 
              ? ( _isChartRolling ? l10n.sevenDays : l10n.thisWeek ) 
              : l10n.week,
            isSelected: _chartPeriod == ChartPeriod.week,
            onTap: () {
              setState(() {
                if (_chartPeriod == ChartPeriod.week) {
                  _isChartRolling = !_isChartRolling; // Toggle rolling mode if already selected
                } else {
                  _chartPeriod = ChartPeriod.week;
                  _isChartRolling = false;
                }
              });
              _fetchChartData();
            },
          ),
          // Month Selector (including Rolling Toggle)
          _PeriodChip(
            label: _chartPeriod == ChartPeriod.month 
              ? ( _isChartRolling ? l10n.thirtyDays : l10n.thisMonth ) 
              : l10n.month,
            isSelected: _chartPeriod == ChartPeriod.month,
            onTap: () {
              setState(() {
                if (_chartPeriod == ChartPeriod.month) {
                  _isChartRolling = !_isChartRolling; // Toggle rolling mode if already selected
                } else {
                  _chartPeriod = ChartPeriod.month;
                  _isChartRolling = false;
                }
              });
              _fetchChartData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeekly = _chartPeriod == ChartPeriod.week;
    final labelColor = isDark ? Colors.white54 : Colors.grey[600];
    
    return _ChartBase(
      title: l10n.weeklyActivity,
      subtitle: l10n.uniqueStudents,
      isLoading: _isLoadingCharts,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (_chartPeriod == ChartPeriod.day) {
                    if (value.toInt() % 4 != 0) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${value.toInt()}h', style: TextStyle(fontSize: 10, color: labelColor)),
                    );
                  }
                  if (isWeekly && !_isChartRolling) {
                    final days = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri];
                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(days[value.toInt()], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor)),
                      );
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      (value.toInt() + 1).toString(),
                      style: TextStyle(fontSize: 10, color: labelColor),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 10,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: labelColor),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Theme.of(context).cardColor,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()} ${l10n.enrolled}',
                    TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _uniqueStudentsSpots.isEmpty ? [const FlSpot(0, 0)] : _uniqueStudentsSpots,
              isCurved: true,
              color: Theme.of(context).colorScheme.secondary,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: isDark ? Colors.black : Colors.white,
                  strokeWidth: 3,
                  strokeColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalScansChart() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white54 : Colors.grey[600];
    final accentColor = Theme.of(context).colorScheme.secondary;

    // Use raw values to rebuild groups reactively for accent changes
    final reactiveGroups = List.generate(_totalScansRaw.length, (i) => BarChartGroupData(x: i, barRods: [
      BarChartRodData(
        toY: _totalScansRaw[i], 
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.4)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        width: _chartPeriod == ChartPeriod.day ? 8 : 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      )
    ]));

    return _ChartBase(
      title: l10n.totalScans,
      subtitle: l10n.all,
      isLoading: _isLoadingCharts,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (_chartPeriod == ChartPeriod.day) return const SizedBox();
                  return Text((value.toInt() + 1).toString(), style: TextStyle(fontSize: 8, color: labelColor));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: reactiveGroups.isEmpty ? _totalScansBarGroups : reactiveGroups,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required MaterialColor color,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: color[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          helperText: helperText,
          helperStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color[400]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[300]!, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, color: color[600], size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildCalendarBookingInterface(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Calendar Widget
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: TableCalendar(
            firstDay: DateTime(DateTime.now().year - 1),
            lastDay: DateTime(DateTime.now().year + 1),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_rangeStart, day) || isSameDay(_rangeEnd, day);
            },
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            rangeSelectionMode: _rangeSelectionMode,
            calendarFormat: CalendarFormat.month,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              // Refresh scans when navigating months (only if no range is selected)
              if (_rangeStart == null && _rangeEnd == null) {
                _fetchScans();
              }
            },
            onDaySelected: (selectedDay, focusedDay) {
              final now = DateTime.now();
              if (_lastTapTime != null && 
                  _lastTapDay != null && 
                  isSameDay(_lastTapDay, selectedDay) && 
                  now.difference(_lastTapTime!).inMilliseconds < 400) {
                _singleTapTimer?.cancel();
                _handleDoubleTap(selectedDay, context);
                _lastTapTime = null;
                return;
              }
              _lastTapTime = now;
              _lastTapDay = selectedDay;

              _singleTapTimer?.cancel();
              _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
                setState(() {
                  _focusedDay = focusedDay;

                  // Range selection logic
                  if (_rangeStart == null || _rangeEnd != null) {
                    _rangeStart = selectedDay;
                    _rangeEnd = null;
                  } else if (selectedDay.isBefore(_rangeStart!)) {
                    _rangeEnd = _rangeStart;
                    _rangeStart = selectedDay;
                  } else {
                    _rangeEnd = selectedDay;
                  }
                });
                _fetchScans();
              });
            },
            onDayLongPressed: (selectedDay, focusedDay) => _handleDoubleTap(selectedDay, context),
            onRangeSelected: (start, end, focusedDay) {
              final selectedDay = end ?? start;
              if (selectedDay != null) {
                final now = DateTime.now();
                if (_lastTapTime != null && 
                    _lastTapDay != null && 
                    isSameDay(_lastTapDay, selectedDay) && 
                    now.difference(_lastTapTime!).inMilliseconds < 400) {
                  _singleTapTimer?.cancel();
                  _handleDoubleTap(selectedDay, context);
                  _lastTapTime = null;
                  return;
                }
                _lastTapTime = now;
                _lastTapDay = selectedDay;
              }

              _singleTapTimer?.cancel();
              _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
                setState(() {
                  _focusedDay = focusedDay;
                  _rangeStart = start;
                  _rangeEnd = end;
                });
                _fetchScans();
              });
            },
            calendarStyle: CalendarStyle(
              rangeHighlightColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              rangeStartDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              withinRangeDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.secondary),
              rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),

        const SizedBox(height: 16),
        // Removed Student Search Bar (now handled by advanced Filter button)
      ],
    );
  }
}

class _ChartBase extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool isLoading;

  const _ChartBase({required this.title, required this.subtitle, required this.child, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
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

    // Staggered animation only for the first 10 items
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
