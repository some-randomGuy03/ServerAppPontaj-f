import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
import 'login_screen.dart';
import 'debug_screen.dart';

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

  // Report/Scan State
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _isHistoryExpanded = true;
  List<ScanLog>? _scans;
  bool _isLoadingScans = false;
  String? _scansError;
  List<FlSpot> _weeklyActivitySpots = [];
  bool _isLoadingActivity = false;

  // Scan Statistics State
  int _scansToday = 0;
  int _scansWeek = 0;
  int _scansTwoWeeks = 0;
  int _scansMonth = 0;
  bool _isLoadingStats = false;

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
    _fabController.dispose();
    _adminSearchController.dispose();
    _elevSearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshList();
    }
  }

  void _refreshList() {
    setState(() {
      _adminsFuture = _fetchAdmins();
      _fetchElevi().then((_) {
        if (mounted) setState(() {});
      });
      _fetchScans();
      _fetchWeeklyActivity();
      _fetchScanStatistics();
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
      // Calculate start and end dates based on selection
      final DateTime startDate;
      final DateTime endDate;

      if (_selectedDay != null) {
        // Fetch for specific day
        startDate = DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
        );
        // Set end date to the next day to satisfy start < end validation
        endDate = startDate.add(const Duration(days: 1));
      } else {
        // Fetch for entire month
        startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        // Set end date to start of next month to capture all days in current month (explicitly exclusive end logic usually)
        endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
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

  Future<void> _fetchWeeklyActivity() async {
    setState(() {
      _isLoadingActivity = true;
    });

    try {
      final now = DateTime.now();
      // Find Monday of the current week
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(monday.year, monday.month, monday.day);
      // End date is Saturday (exclusive of Friday scan times potentially if not careful,
      // but scans_by_date logic usually takes start and end.
      // Let's set end to Saturday 00:00:00 to cover full Friday.
      final endDate = startDate.add(const Duration(days: 5));

      final response = await _adminService.getScansByDate(
        widget.token,
        startDate,
        endDate,
      );

      final scans = response.data;
      final Map<int, Set<int>> dailyStudents = {
        0: {}, // Mon
        1: {}, // Tue
        2: {}, // Wed
        3: {}, // Thu
        4: {}, // Fri
      };

      for (var scan in scans) {
        // Calculate day index (0=Mon, 4=Fri)
        // scan.scanTime.weekday: Mon=1, Sun=7
        final dayIndex = scan.scanTime.weekday - 1;
        if (dayIndex >= 0 && dayIndex <= 4) {
          dailyStudents[dayIndex]?.add(scan.idElev);
        }
      }

      final List<FlSpot> spots = [];
      for (int i = 0; i < 5; i++) {
        spots.add(
          FlSpot(i.toDouble(), dailyStudents[i]?.length.toDouble() ?? 0),
        );
      }

      setState(() {
        _weeklyActivitySpots = spots;
      });
    } catch (e) {
      print('Error fetching weekly activity: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingActivity = false;
        });
      }
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
      final weekAgo = today.subtract(const Duration(days: 7));
      final twoWeeksAgo = today.subtract(const Duration(days: 14));
      final monthAgo = today.subtract(const Duration(days: 30));

      // Fetch all periods in parallel
      final results = await Future.wait([
        _adminService.getScansByDate(widget.token, today, tomorrow),
        _adminService.getScansByDate(widget.token, weekAgo, tomorrow),
        _adminService.getScansByDate(widget.token, twoWeeksAgo, tomorrow),
        _adminService.getScansByDate(widget.token, monthAgo, tomorrow),
      ]);

      if (mounted) {
        setState(() {
          _scansToday = results[0].data.length;
          _scansWeek = results[1].data.length;
          _scansTwoWeeks = results[2].data.length;
          _scansMonth = results[3].data.length;
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
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                                color: Colors.white,
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
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                            color: Colors.white,
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
                      color: const Color(0xFFF2F2F7),
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
                      color: const Color(0xFFF2F2F7),
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
                                color: Colors.white,
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
    final now = DateTime.now();
    // Localize date format
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('EEEE, d MMMM', l10n.localeName).format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS System Gray 6
      body: FutureBuilder<AdminListResponse>(
        future: _adminsFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data;
          final admins = data?.admins ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                backgroundColor: const Color(0xFFF2F2F7),
                surfaceTintColor: Colors.transparent,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    l10n.dashboard,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Stack(
                    children: [
                      Positioned(
                        left: 20,
                        bottom: 50,
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
                actions: [
                  // Language Switcher
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: LanguageSwitcher(),
                  ),
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
                // Charts Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _buildChartsSection(admins, _allElevi),
                  ),
                ),

                // Weekly Activity Chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _buildActivityChart(),
                  ),
                ),

                // Reports Control & History Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
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
                                        color: Colors.black.withOpacity(0.8),
                                      ),
                                    ),
                                    if (_scans != null && _scans!.isNotEmpty)
                                      Text(
                                        '${_scans!.map((s) => s.idElev).toSet().length} ${l10n.studentsScanned}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                const Spacer(),
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
                            const SizedBox(height: 16),
                            // Year/Month Selector (12 dots)
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 12,
                                itemBuilder: (context, index) {
                                  final monthDate = DateTime(
                                    DateTime.now().year,
                                    index + 1,
                                  );
                                  final isSelected =
                                      _selectedMonth.month == index + 1 &&
                                      _selectedMonth.year == monthDate.year;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedMonth = monthDate;
                                        _selectedDay =
                                            null; // Reset day selection
                                      });
                                      _fetchScans();
                                    },
                                    child: Container(
                                      width: 40,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? Border.all(
                                                color: Colors.blue,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          DateFormat('MMM').format(monthDate),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Day Selector
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month + 1,
                                  0,
                                ).day, // Days in month
                                itemBuilder: (context, index) {
                                  final day = index + 1;
                                  final dayDate = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month,
                                    day,
                                  );
                                  final isSelected =
                                      _selectedDay?.day == day &&
                                      _selectedDay?.month ==
                                          _selectedMonth.month;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDay = isSelected
                                            ? null
                                            : dayDate;
                                      });
                                      _fetchScans();
                                    },
                                    child: Container(
                                      width: 45,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('E').format(dayDate),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected
                                                  ? Colors.white.withOpacity(
                                                      0.8,
                                                    )
                                                  : Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '$day',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    sliver: Builder(
                      builder: (context) {
                        // Group scans by student ID
                        final Map<String, List<ScanLog>> groupedScans = {};
                        for (var scan in _scans!) {
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
                                color: Colors.white,
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
                                  horizontal: 20,
                                  vertical: 8,
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
                                      firstScan.name.isNotEmpty
                                          ? firstScan.name[0].toUpperCase()
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
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${studentScans.length} scans',
                                    style: TextStyle(
                                      color: Colors.blue[700],
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
              ],
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
                              color: const Color(0xFFF2F2F7),
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
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showProfessorsListModal();
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
                                  color: Colors.white,
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

  Widget _buildChartsSection(List<Professor> admins, List<Elev> elevi) {
    final l10n = AppLocalizations.of(context)!;

    final int totalProfessors = admins.length;
    final int totalStudents = elevi.length;
    final int totalEnrolled = _currentElevi.length;
    final int total = totalProfessors + totalStudents;

    // Calculate percentages for pie chart
    final double profPercentage = total > 0
        ? (totalProfessors / total) * 100
        : 50;
    final double studPercentage = total > 0
        ? (totalStudents / total) * 100
        : 50;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        height: 220,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          children: [
            // Stats Overview Card (Professors, Students, Enrolled)
            _buildChartCard(
              title: l10n.total,
              width: 440,
              child: Row(
                children: [
                  // Professors stat
                  Expanded(
                    child: InkWell(
                      onTap: _showProfessorsListModal,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade50,
                              Colors.blue.shade100.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$totalProfessors',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            Text(
                              l10n.professors,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Students stat
                  Expanded(
                    child: InkWell(
                      onTap: _showStudentsListModal,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade100.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.school,
                                color: Colors.green[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$totalStudents',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            Text(
                              l10n.students,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Enrolled Students stat
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade50,
                            Colors.purple.shade100.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.how_to_reg,
                              color: Colors.purple[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$totalEnrolled',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          Text(
                            l10n.enrolled,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Scan Statistics Card
            _buildChartCard(
              title: l10n.scanHistory,
              width: 520,
              child: Row(
                children: [
                  // Scans Today - Blue
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade50,
                            Colors.blue.shade100.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.today,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLoadingStats ? '...' : '$_scansToday',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          Text(
                            l10n.scansToday,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Scans Week - Amber
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade50,
                            Colors.amber.shade100.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.date_range,
                              color: Colors.amber[700],
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLoadingStats ? '...' : '$_scansWeek',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                          Text(
                            l10n.scansWeek,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Scans 2 Weeks - Orange
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade50,
                            Colors.orange.shade100.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_view_week,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLoadingStats ? '...' : '$_scansTwoWeeks',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          Text(
                            l10n.scansTwoWeeks,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Scans Month - Red
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade50,
                            Colors.red.shade100.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_month,
                              color: Colors.red[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLoadingStats ? '...' : '$_scansMonth',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          Text(
                            l10n.scansMonth,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Distribution Pie Chart
            _buildChartCard(
              title: l10n.systemStatus,
              width: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 35,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: Colors.blue[500],
                          value: profPercentage,
                          showTitle: false,
                          radius: 20,
                        ),
                        PieChartSectionData(
                          color: Colors.green[500],
                          value: studPercentage,
                          showTitle: false,
                          radius: 20,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        l10n.total,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Activity',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unique Students (Mon-Fri)',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoadingActivity
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              );
                              String text;
                              switch (value.toInt()) {
                                case 0:
                                  text = 'Mon';
                                  break;
                                case 1:
                                  text = 'Tue';
                                  break;
                                case 2:
                                  text = 'Wed';
                                  break;
                                case 3:
                                  text = 'Thu';
                                  break;
                                case 4:
                                  text = 'Fri';
                                  break;
                                default:
                                  return Container();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 10,
                                child: Text(text, style: style),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5, // Adjust interval based on max
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0)
                                return Container(); // Only integers
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 4,
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _weeklyActivitySpots.isEmpty
                              ? [const FlSpot(0, 0)]
                              : _weeklyActivitySpots,
                          isCurved: true,
                          color: Colors.blueAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blueAccent.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required Widget child,
    double width = 200,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
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
        color: Colors.white,
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
          fillColor: Colors.white,
        ),
        validator: validator,
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
