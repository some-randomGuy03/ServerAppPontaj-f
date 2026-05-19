import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:pontaj_admin/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/hero_background.dart';
import '../widgets/floating_stats_sidebar.dart';
import '../models/scan_log.dart';
import '../models/elev.dart';
import '../services/admin_service.dart';
import '../services/elev_service.dart';
import 'dart:async';

enum ChartPeriod { day, week, month }

class StudentReportsScreen extends StatefulWidget {
  final String token;
  final String username;
  final int adminStatus;

  const StudentReportsScreen({
    super.key,
    required this.token,
    required this.username,
    required this.adminStatus,
  });

  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> {
  final _adminService = AdminService();
  final _elevService = ElevService();

  List<Elev> _currentElevi = []; 
  List<Elev> _allElevi = []; 

  // Timeframe State
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  ChartPeriod _chartPeriod = ChartPeriod.week;
  bool _isChartRolling = false;
  DateTime? _lastTapTime;
  DateTime? _lastTapDay;
  Timer? _singleTapTimer;

  // Time filtering
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);

  // Student Filter State
  List<int> _selectedStudentFilters = [];
  final TextEditingController _scanSearchController = TextEditingController();

  // Data State
  List<ScanLog>? _chartScans;
  bool _isLoadingCharts = false;

  // Chart State
  String _currentChartMode = 'daily';
  Map<int, List<FlSpot>> _multiStudentSpots = {};
  List<double> _totalScansRaw = [];
  List<BarChartGroupData> _totalScansBarGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchElevi();
    _fetchChartData();
  }

  @override
  void dispose() {
    _scanSearchController.dispose();
    _singleTapTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchElevi() async {
    try {
      final enrolledResponse = await _elevService.getEleviEnrolled(widget.token);
      _currentElevi = enrolledResponse.elevi;
      final allResponse = await _elevService.getElevi(widget.token);
      _allElevi = allResponse.elevi;
      if (mounted) setState(() {});
    } catch (e) {
      print('Error fetching elevi: $e');
    }
  }

  String _getSelectedDateText() {
    String formatTime(TimeOfDay time) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return "$h:$m";
    }

    final hasCustomTime = _startTime.hour != 0 || _startTime.minute != 0 || _endTime.hour != 23 || _endTime.minute != 59;
    final timeStr = hasCustomTime ? " (${formatTime(_startTime)} - ${formatTime(_endTime)})" : "";

    if (_rangeStart != null && _rangeEnd != null) {
      return "${DateFormat('MMM d').format(_rangeStart!)} - ${DateFormat('MMM d').format(_rangeEnd!)}$timeStr";
    } else if (_rangeStart != null) {
      return "${DateFormat('MMM d, yyyy').format(_rangeStart!)}$timeStr";
    }
    return "This Month";
  }

  Color _getStudentColor(int studentId) {
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.pink, Colors.amber, 
      Colors.indigo, Colors.cyan
    ];
    return colors[studentId % colors.length];
  }

  String _getStudentName(int id) {
    try {
      return _allElevi.firstWhere((e) => e.id == id).name;
    } catch (e) {
      return "Student $id";
    }
  }

  Future<void> _fetchChartData() async {
    setState(() => _isLoadingCharts = true);
    try {
      DateTime startDate;
      DateTime endDate;

      if (_rangeStart != null && _rangeEnd != null) {
        startDate = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
        endDate = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day).add(const Duration(days: 1));
      } else if (_rangeStart != null) {
        startDate = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
        endDate = startDate.add(const Duration(days: 1));
      } else {
        startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
        endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      }

      final response = await _adminService.getScansByDate(widget.token, startDate, endDate);
      _chartScans = response.data;
      _processChartData();
    } catch (e) {
      print('Error fetching chart data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCharts = false);
    }
  }

  void _processChartData() {
    if (_chartScans == null) return;
    
    final scans = _chartScans!.where((s) {
      if (_selectedStudentFilters.isNotEmpty && !_selectedStudentFilters.contains(s.idElev)) {
        return false;
      }
      final scanTimeInMinutes = s.scanTime.hour * 60 + s.scanTime.minute;
      final startTimeInMinutes = _startTime.hour * 60 + _startTime.minute;
      final endTimeInMinutes = _endTime.hour * 60 + _endTime.minute;
      return scanTimeInMinutes >= startTimeInMinutes && scanTimeInMinutes <= endTimeInMinutes;
    }).toList();

    DateTime sDate;
    DateTime eDate;

    if (_rangeStart != null && _rangeEnd != null) {
      sDate = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
      eDate = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day).add(const Duration(days: 1));
    } else if (_rangeStart != null) {
      sDate = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
      eDate = sDate.add(const Duration(days: 1));
    } else {
      sDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      eDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    }

    final duration = eDate.difference(sDate);
    final days = duration.inDays;

    if (days <= 1) {
      _currentChartMode = 'hourly';
      _processChartByHour(scans, sDate);
    } else if (days <= 60) {
      _currentChartMode = 'daily';
      _processChartByDay(scans, sDate, days);
    } else if (days <= 180) {
      _currentChartMode = 'weekly';
      _processChartByWeek(scans, sDate, eDate);
    } else {
      _currentChartMode = 'monthly';
      _processChartByMonth(scans, sDate, eDate);
    }
  }

  void _processChartByHour(List<ScanLog> scans, DateTime startDate) {
    final multiSpots = <int, List<FlSpot>>{};
    final totalCounts = List.generate(24, (_) => 0);
    
    final studentHourlyTotal = <int, List<int>>{};
    for (var id in _selectedStudentFilters) {
      studentHourlyTotal[id] = List.generate(24, (_) => 0);
    }

    for (var s in scans) {
      if (s.scanTime.year == startDate.year && s.scanTime.month == startDate.month && s.scanTime.day == startDate.day) {
        totalCounts[s.scanTime.hour]++;
        if (studentHourlyTotal.containsKey(s.idElev)) {
          studentHourlyTotal[s.idElev]![s.scanTime.hour]++;
        }
      }
    }

    for (var entry in studentHourlyTotal.entries) {
      multiSpots[entry.key] = List.generate(24, (i) => FlSpot(i.toDouble(), entry.value[i].toDouble()));
    }

    final accentColor = Theme.of(context).colorScheme.secondary;
    if (mounted) {
      setState(() {
        _multiStudentSpots = multiSpots;
        _totalScansRaw = totalCounts.map((e) => e.toDouble()).toList();
        _totalScansBarGroups = List.generate(24, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: totalCounts[i].toDouble(), 
            gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.4)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          )
        ]));
      });
    }
  }

  void _processChartByDay(List<ScanLog> scans, DateTime startDate, int days) {
    final multiSpots = <int, List<FlSpot>>{};
    final dailyTotal = List.generate(days, (_) => 0);
    
    final studentDailyTotal = <int, List<int>>{};
    for (var id in _selectedStudentFilters) {
      studentDailyTotal[id] = List.generate(days, (_) => 0);
    }

    for (var s in scans) {
      final diff = DateTime(s.scanTime.year, s.scanTime.month, s.scanTime.day).difference(startDate).inDays;
      if (diff >= 0 && diff < days) {
        dailyTotal[diff]++;
        if (studentDailyTotal.containsKey(s.idElev)) {
          studentDailyTotal[s.idElev]![diff]++;
        }
      }
    }

    for (var entry in studentDailyTotal.entries) {
      multiSpots[entry.key] = List.generate(days, (i) => FlSpot(i.toDouble(), entry.value[i].toDouble()));
    }

    final accentColor = Theme.of(context).colorScheme.secondary;
    if (mounted) {
      setState(() {
        _multiStudentSpots = multiSpots;
        _totalScansRaw = dailyTotal.map((e) => e.toDouble()).toList();
        _totalScansBarGroups = List.generate(days, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: dailyTotal[i].toDouble(), 
            gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.4)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            width: days > 30 ? 4 : 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          )
        ]));
      });
    }
  }

  void _processChartByWeek(List<ScanLog> scans, DateTime startDate, DateTime endDate) {
    int weeks = (endDate.difference(startDate).inDays / 7).ceil();
    if (weeks == 0) weeks = 1;
    final multiSpots = <int, List<FlSpot>>{};
    final weeklyTotal = List.generate(weeks, (_) => 0);
    
    final studentWeeklyTotal = <int, List<int>>{};
    for (var id in _selectedStudentFilters) {
      studentWeeklyTotal[id] = List.generate(weeks, (_) => 0);
    }

    for (var s in scans) {
      final diff = DateTime(s.scanTime.year, s.scanTime.month, s.scanTime.day).difference(startDate).inDays;
      final weekIndex = diff ~/ 7;
      if (weekIndex >= 0 && weekIndex < weeks) {
        weeklyTotal[weekIndex]++;
        if (studentWeeklyTotal.containsKey(s.idElev)) {
          studentWeeklyTotal[s.idElev]![weekIndex]++;
        }
      }
    }

    for (var entry in studentWeeklyTotal.entries) {
      multiSpots[entry.key] = List.generate(weeks, (i) => FlSpot(i.toDouble(), entry.value[i].toDouble()));
    }

    final accentColor = Theme.of(context).colorScheme.secondary;
    if (mounted) {
      setState(() {
        _multiStudentSpots = multiSpots;
        _totalScansRaw = weeklyTotal.map((e) => e.toDouble()).toList();
        _totalScansBarGroups = List.generate(weeks, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: weeklyTotal[i].toDouble(), 
            gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.4)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          )
        ]));
      });
    }
  }

  void _processChartByMonth(List<ScanLog> scans, DateTime startDate, DateTime endDate) {
    int months = (endDate.year - startDate.year) * 12 + endDate.month - startDate.month + 1;
    final multiSpots = <int, List<FlSpot>>{};
    final monthlyTotal = List.generate(months, (_) => 0);
    
    final studentMonthlyTotal = <int, List<int>>{};
    for (var id in _selectedStudentFilters) {
      studentMonthlyTotal[id] = List.generate(months, (_) => 0);
    }

    for (var s in scans) {
      int monthIndex = (s.scanTime.year - startDate.year) * 12 + s.scanTime.month - startDate.month;
      if (monthIndex >= 0 && monthIndex < months) {
        monthlyTotal[monthIndex]++;
        if (studentMonthlyTotal.containsKey(s.idElev)) {
          studentMonthlyTotal[s.idElev]![monthIndex]++;
        }
      }
    }

    for (var entry in studentMonthlyTotal.entries) {
      multiSpots[entry.key] = List.generate(months, (i) => FlSpot(i.toDouble(), entry.value[i].toDouble()));
    }

    final accentColor = Theme.of(context).colorScheme.secondary;
    if (mounted) {
      setState(() {
        _multiStudentSpots = multiSpots;
        _totalScansRaw = monthlyTotal.map((e) => e.toDouble()).toList();
        _totalScansBarGroups = List.generate(months, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: monthlyTotal[i].toDouble(), 
            gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.4)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          )
        ]));
      });
    }
  }

  Future<void> _handleDoubleTap(DateTime date, BuildContext context, [StateSetter? setDialogState]) async {
    final l10n = AppLocalizations.of(context)!;
    if (_rangeStart != null && _rangeEnd != null) {
      if (isSameDay(date, _rangeStart)) {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _startTime,
          helpText: l10n.startTime,
        );
        if (picked != null) {
          setState(() => _startTime = picked);
          if (setDialogState != null) setDialogState(() {});
          _processChartData();
        }
      } else if (isSameDay(date, _rangeEnd)) {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _endTime,
          helpText: l10n.endTime,
        );
        if (picked != null) {
          setState(() => _endTime = picked);
          if (setDialogState != null) setDialogState(() {});
          _processChartData();
        }
      }
    } else {
      await _showTwoHoursPickerDialog(context, setDialogState);
    }
  }

  Future<void> _showTwoHoursPickerDialog(BuildContext context, [StateSetter? setDialogStateParam]) async {
    final l10n = AppLocalizations.of(context)!;
    TimeOfDay tempStart = _startTime;
    TimeOfDay tempEnd = _endTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                  child: Text(l10n.cancel),
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
      if (setDialogStateParam != null) setDialogStateParam(() {});
      _processChartData();
    }
  }

  void _showStudentFilterPopup() {
    final l10n = AppLocalizations.of(context)!;
    final sortedStudents = List<Elev>.from(_allElevi)..sort((a, b) => a.name.compareTo(b.name));
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(l10n.selectOneOrMoreStudents ?? "Select one or more students"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    TextField(
                      controller: _scanSearchController,
                      onChanged: (val) => setDialogState((){}),
                      decoration: InputDecoration(
                        hintText: "Search...",
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
                            activeColor: _getStudentColor(student.id),
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  _selectedStudentFilters.add(student.id);
                                } else {
                                  _selectedStudentFilters.remove(student.id);
                                }
                              });
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
                  },
                  child: Text(l10n.clear ?? "Clear"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel ?? "Cancel", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {});
                    _processChartData();
                  },
                  child: Text(l10n.done ?? "Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTimetablePopup() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.selectDateOrTimeframe ?? "Select a date or timeframe",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PeriodChip(
                            label: l10n.day,
                            isSelected: _chartPeriod == ChartPeriod.day,
                            onTap: () {
                              final today = DateTime.now();
                              setState(() {
                                _chartPeriod = ChartPeriod.day;
                                _isChartRolling = false;
                                _rangeStart = DateTime(today.year, today.month, today.day);
                                _rangeEnd = _rangeStart;
                                _focusedDay = _rangeStart!;
                              });
                              setDialogState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _PeriodChip(
                            label: _chartPeriod == ChartPeriod.week 
                                ? ( _isChartRolling ? l10n.sevenDays : l10n.thisWeek ) 
                                : l10n.week,
                            isSelected: _chartPeriod == ChartPeriod.week,
                            onTap: () {
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              setState(() {
                                if (_chartPeriod == ChartPeriod.week) {
                                  _isChartRolling = !_isChartRolling;
                                } else {
                                  _chartPeriod = ChartPeriod.week;
                                  _isChartRolling = false;
                                }
                                if (_isChartRolling) {
                                  _rangeStart = today.subtract(const Duration(days: 6));
                                  _rangeEnd = today;
                                } else {
                                  _rangeStart = today.subtract(Duration(days: today.weekday - 1));
                                  _rangeEnd = today;
                                }
                                _focusedDay = _rangeStart!;
                              });
                              setDialogState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _PeriodChip(
                            label: _chartPeriod == ChartPeriod.month 
                                ? ( _isChartRolling ? l10n.thirtyDays : l10n.thisMonth ) 
                                : l10n.month,
                            isSelected: _chartPeriod == ChartPeriod.month,
                            onTap: () {
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              setState(() {
                                if (_chartPeriod == ChartPeriod.month) {
                                  _isChartRolling = !_isChartRolling;
                                } else {
                                  _chartPeriod = ChartPeriod.month;
                                  _isChartRolling = false;
                                }
                                if (_isChartRolling) {
                                  _rangeStart = today.subtract(const Duration(days: 29));
                                  _rangeEnd = today;
                                } else {
                                  _rangeStart = DateTime(now.year, now.month, 1);
                                  final nextMonth = DateTime(now.year, now.month + 1, 1);
                                  _rangeEnd = nextMonth.subtract(const Duration(days: 1));
                                }
                                _focusedDay = _rangeStart!;
                              });
                              setDialogState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildCalendarBookingInterface(l10n, setDialogState),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _fetchChartData();
                          },
                          child: Text(l10n.done ?? "Done"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarBookingInterface(AppLocalizations l10n, [StateSetter? setDialogState]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: TableCalendar(
            locale: Localizations.localeOf(context).toString(),
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
              if (setDialogState != null) setDialogState(() {});
            },
            onDaySelected: (selectedDay, focusedDay) {
              final now = DateTime.now();
              if (_lastTapTime != null && 
                  _lastTapDay != null && 
                  isSameDay(_lastTapDay, selectedDay) && 
                  now.difference(_lastTapTime!).inMilliseconds < 400) {
                _singleTapTimer?.cancel();
                _handleDoubleTap(selectedDay, context, setDialogState);
                _lastTapTime = null;
                return;
              }
              _lastTapTime = now;
              _lastTapDay = selectedDay;

              _singleTapTimer?.cancel();
              _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
                setState(() {
                  _focusedDay = focusedDay;
                  if (_rangeStart != null && _rangeEnd == null && isSameDay(_rangeStart, selectedDay)) {
                    _rangeStart = null;
                  } else if (_rangeStart != null && _rangeEnd != null && isSameDay(_rangeStart, selectedDay)) {
                    _rangeEnd = null;
                  } else if (_rangeStart != null && _rangeEnd != null && isSameDay(_rangeEnd, selectedDay)) {
                    _rangeStart = _rangeEnd;
                    _rangeEnd = null;
                  } else if (_rangeStart == null || _rangeEnd != null) {
                    _rangeStart = selectedDay;
                    _rangeEnd = null;
                  } else if (selectedDay.isBefore(_rangeStart!)) {
                    _rangeEnd = _rangeStart;
                    _rangeStart = selectedDay;
                  } else {
                    _rangeEnd = selectedDay;
                  }
                });
                if (setDialogState != null) setDialogState(() {});
              });
            },
            onDayLongPressed: (selectedDay, focusedDay) => _handleDoubleTap(selectedDay, context, setDialogState),
            onRangeSelected: (start, end, focusedDay) {
              final selectedDay = end ?? start;
              if (selectedDay != null) {
                final now = DateTime.now();
                if (_lastTapTime != null && 
                    _lastTapDay != null && 
                    isSameDay(_lastTapDay, selectedDay) && 
                    now.difference(_lastTapTime!).inMilliseconds < 400) {
                  _singleTapTimer?.cancel();
                  _handleDoubleTap(selectedDay, context, setDialogState);
                  _lastTapTime = null;
                  return;
                }
                _lastTapTime = now;
                _lastTapDay = selectedDay;
              }

              _singleTapTimer?.cancel();
              _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
                if (selectedDay != null) {
                  setState(() {
                    _focusedDay = focusedDay;
                    if (_rangeStart != null && _rangeEnd == null && isSameDay(_rangeStart, selectedDay)) {
                      _rangeStart = null;
                    } else if (_rangeStart != null && _rangeEnd != null && isSameDay(_rangeStart, selectedDay)) {
                      _rangeEnd = null;
                    } else if (_rangeStart != null && _rangeEnd != null && isSameDay(_rangeEnd, selectedDay)) {
                      _rangeStart = _rangeEnd;
                      _rangeEnd = null;
                    } else if (_rangeStart == null || _rangeEnd != null) {
                      _rangeStart = selectedDay;
                      _rangeEnd = null;
                    } else if (selectedDay.isBefore(_rangeStart!)) {
                      _rangeEnd = _rangeStart;
                      _rangeStart = selectedDay;
                    } else {
                      _rangeEnd = selectedDay;
                    }
                  });
                  if (setDialogState != null) setDialogState(() {});
                }
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
      ],
    );
  }

  Widget _buildMultiActivityChart() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white54 : Colors.grey[600];

    DateTime sDate;
    if (_rangeStart != null) {
      sDate = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
    } else {
      sDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    }

    final lines = <LineChartBarData>[];
    for (var entry in _multiStudentSpots.entries) {
      lines.add(
        LineChartBarData(
          spots: entry.value,
          isCurved: true,
          color: _getStudentColor(entry.key),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
        )
      );
    }
    
    return _ChartBase(
      title: l10n.studentUses ?? "Student Uses",
      subtitle: l10n.scansPerStudent ?? "Scans per student",
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
                  if (_currentChartMode == 'hourly') {
                    if (value.toInt() % 4 != 0) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${value.toInt()}h', style: TextStyle(fontSize: 10, color: labelColor)),
                    );
                  } else if (_currentChartMode == 'daily') {
                    final date = sDate.add(Duration(days: value.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(fontSize: 10, color: labelColor),
                      ),
                    );
                  } else if (_currentChartMode == 'weekly') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'W${value.toInt() + 1}',
                        style: TextStyle(fontSize: 10, color: labelColor),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'M${value.toInt() + 1}',
                        style: TextStyle(fontSize: 10, color: labelColor),
                      ),
                    );
                  }
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
          borderData: FlBorderData(show: false),
          lineBarsData: lines.isEmpty ? [
             LineChartBarData(
              spots: [const FlSpot(0, 0)],
              color: Colors.transparent,
            )
          ] : lines,
        ),
      ),
    );
  }

  Widget _buildTotalScansChart() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white54 : Colors.grey[600];
    final accentColor = Theme.of(context).colorScheme.secondary;

    DateTime sDate;
    if (_rangeStart != null) {
      sDate = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
    } else {
      sDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    }

    final reactiveGroups = List.generate(_totalScansRaw.length, (i) => BarChartGroupData(x: i, barRods: [
      BarChartRodData(
        toY: _totalScansRaw[i], 
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.4)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        width: _currentChartMode == 'hourly' ? 8 : 12,
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
                  if (_currentChartMode == 'hourly') return const SizedBox();
                  if (_currentChartMode == 'weekly') {
                    return Text('W${value.toInt() + 1}', style: TextStyle(fontSize: 8, color: labelColor));
                  } else if (_currentChartMode == 'monthly') {
                    return Text('M${value.toInt() + 1}', style: TextStyle(fontSize: 8, color: labelColor));
                  }
                  final date = sDate.add(Duration(days: value.toInt()));
                  return Text(date.day.toString(), style: TextStyle(fontSize: 8, color: labelColor));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.85),
                surfaceTintColor: Colors.transparent,
                floating: false,
                pinned: true,
                automaticallyImplyLeading: false, 
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 88, bottom: 16),
                      title: Text(
                        l10n.detailedStudentReports ?? "Detailed Student Reports",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          const HeroBackground(height: 140),
                        ],
                      ),
                      centerTitle: false,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(88, 24, 24, 8),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l10n.goBack ?? "Go back"),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showStudentFilterPopup(),
                        icon: const Icon(Icons.person_search, size: 18),
                        label: Text(l10n.selectOneOrMoreStudents ?? "Select one or more students"),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showTimetablePopup(),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(l10n.selectDateOrTimeframe ?? "Select a date or timeframe"),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Active Filters Zone
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(88, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_rangeStart != null || _selectedStudentFilters.isNotEmpty)
                        Text(l10n.activeFilters ?? "Active filters:", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color)),
                      if (_rangeStart != null || _selectedStudentFilters.isNotEmpty)
                        const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_rangeStart != null)
                            Chip(
                              label: Text(_getSelectedDateText()),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _rangeStart = null;
                                  _rangeEnd = null;
                                });
                                _fetchChartData();
                              },
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                              side: BorderSide.none,
                            ),
                          ..._selectedStudentFilters.map((id) => Chip(
                            label: Text(_getStudentName(id)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedStudentFilters.remove(id);
                              });
                              _processChartData();
                            },
                            backgroundColor: _getStudentColor(id).withOpacity(0.1),
                            labelStyle: TextStyle(color: _getStudentColor(id), fontWeight: FontWeight.bold),
                            side: BorderSide.none,
                          )).toList(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Charts on a single row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(88, 8, 24, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildMultiActivityChart(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTotalScansChart(),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: FloatingStatsSidebar(
              professorsCount: 0,
              studentsCount: _allElevi.length,
              enrolledCount: _currentElevi.length,
              scansToday: 0,
              scansWeek: 0,
              scansMonth: 0,
              weekLabel: l10n.thisWeek,
              monthLabel: l10n.thisMonth,
              onTapWeek: () {},
              onTapMonth: () {},
              onTapProfessors: () {},
              onTapStudents: () {},
              onTapEnrolled: () {},
              l10n: l10n,
            ),
          ),
        ],
      ),
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
