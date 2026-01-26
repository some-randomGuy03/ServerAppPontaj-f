import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pontaj_admin/l10n/app_localizations.dart';
import '../models/professor.dart';
import '../models/elev.dart';
import '../services/admin_service.dart';
import '../services/elev_service.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
import '../utils/csv_downloader.dart';
import '../utils/apk_downloader.dart';
import '../widgets/language_switcher.dart';
import 'login_screen.dart';
import 'debug_screen.dart';
import 'reports_screen.dart';

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
  late Future<ElevListResponse> _eleviFuture;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  List<Professor> _currentAdmins = [];
  List<Elev> _currentElevi = [];

  // Search and Collapse state
  bool _isAdminsExpanded = true;
  bool _isEleviExpanded = true;
  late int _adminStatus;
  final TextEditingController _adminSearchController = TextEditingController();
  final TextEditingController _elevSearchController = TextEditingController();
  String _adminSearchQuery = '';
  String _elevSearchQuery = '';

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

    _adminSearchController.addListener(() {
      setState(() {
        _adminSearchQuery = _adminSearchController.text.toLowerCase();
      });
    });

    _elevSearchController.addListener(() {
      setState(() {
        _elevSearchQuery = _elevSearchController.text.toLowerCase();
      });
    });
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
      _eleviFuture = _fetchElevi();
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

  Future<ElevListResponse> _fetchElevi() async {
    try {
      final response = await _elevService.getElevi(widget.token);
      _currentElevi = response.elevi;
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
                                                      professor!.id,
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
                          case 'reports':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReportsScreen(token: widget.token),
                              ),
                            );
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
                          PopupMenuItem<String>(
                            value: 'reports',
                            child: Row(
                              children: [
                                const Icon(Icons.analytics_outlined, size: 20),
                                const SizedBox(width: 12),
                                Text('Reports'),
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
                // Professors Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChartsSection(admins, _currentElevi),
                        const SizedBox(height: 32),
                        // Professors Header
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isAdminsExpanded
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_right_rounded,
                                color: Colors.black.withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isAdminsExpanded = !_isAdminsExpanded;
                                });
                              },
                            ),
                            Text(
                              l10n.professors,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withOpacity(0.8),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Spacer(),
                            // Search Bar
                            if (_isAdminsExpanded)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.05),
                                      ),
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
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.05),
                                ),
                              ),
                              child: Text(
                                '${admins.length} ${l10n.total}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                if (_isAdminsExpanded)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: Builder(
                      builder: (context) {
                        final filteredAdmins = admins.where((admin) {
                          return admin.name.toLowerCase().contains(
                                _adminSearchQuery,
                              ) ||
                              admin.email.toLowerCase().contains(
                                _adminSearchQuery,
                              );
                        }).toList();

                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final admin = filteredAdmins[index];
                            final isFirst = index == 0;
                            final isLast = index == filteredAdmins.length - 1;

                            return _AnimatedListItem(
                              index: index,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  bottom: 1,
                                ), // Separator line
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
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
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
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    admin.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  subtitle: Text(
                                    admin.email,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.lock_outline,
                                          color: Colors.orange[400],
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            _showChangePasswordDialog(admin),
                                        tooltip: l10n.changePassword,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue[400],
                                          size: 22,
                                        ),
                                        onPressed: () => _showProfessorDialog(
                                          professor: admin,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red[300],
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            _deleteProfessor(admin),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }, childCount: filteredAdmins.length),
                        );
                      },
                    ),
                  ),

                // Students Section
                FutureBuilder<ElevListResponse>(
                  future: _eleviFuture,
                  builder: (context, snapshot) {
                    final elevi = snapshot.data?.elevi ?? [];

                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isEleviExpanded
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_right_rounded,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isEleviExpanded = !_isEleviExpanded;
                                    });
                                  },
                                ),
                                Text(
                                  l10n.students,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black.withOpacity(0.8),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Spacer(),
                                // Search Bar
                                if (_isEleviExpanded)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                          ),
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
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Text(
                                    '${elevi.length} ${l10n.total}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                FutureBuilder<ElevListResponse>(
                  future: _eleviFuture,
                  builder: (context, snapshot) {
                    final elevi = snapshot.data?.elevi ?? [];

                    if (!_isEleviExpanded) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    final filteredElevi = elevi.where((elev) {
                      final query = _elevSearchQuery;
                      return elev.name.toLowerCase().contains(query) ||
                          elev.email.toLowerCase().contains(query) ||
                          elev.codMatricol.toLowerCase().contains(query);
                    }).toList();

                    if (filteredElevi.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final elev = filteredElevi[index];
                          final isFirst = index == 0;
                          final isLast = index == filteredElevi.length - 1;

                          return _AnimatedListItem(
                            index: index,
                            child: Container(
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
                                  vertical: 12,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: elev.activ == 1
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
                                        color: elev.activ == 1
                                            ? Colors.green
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
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
                                        color: elev.activ == 1
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        elev.activ == 1
                                            ? l10n.active
                                            : l10n.inactive,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: elev.activ == 1
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue[400],
                                        size: 22,
                                      ),
                                      onPressed: () =>
                                          _showElevDialog(elev: elev),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red[300],
                                        size: 22,
                                      ),
                                      onPressed: () => _deleteElev(elev),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: filteredElevi.length),
                      ),
                    );
                  },
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
        constraints: const BoxConstraints(maxWidth: 1000),
        height: 220,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          children: [
            // Stats Overview Card
            _buildChartCard(
              title: l10n.total,
              width: 320,
              child: Row(
                children: [
                  // Professors stat
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(16),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.blue[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalProfessors',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          Text(
                            l10n.professors,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Students stat
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(16),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.school,
                              color: Colors.green[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalStudents',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            l10n.students,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
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
