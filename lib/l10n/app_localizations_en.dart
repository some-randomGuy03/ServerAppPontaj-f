// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pontaj Admin';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get users => 'Users';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInMessage => 'Please sign in to access the admin portal.';

  @override
  String get requiredField => 'Required';

  @override
  String get schoolName => 'Colegiul Național\n\"Vasile Goldiș\"';

  @override
  String get excellenceInEducation => 'Excellence in Education';

  @override
  String get noDataToExport => 'No data to export';

  @override
  String get statsExportedSuccess => 'Stats exported to CSV successfully';

  @override
  String get editProfessor => 'Edit Professor';

  @override
  String get addProfessor => 'Add Professor';

  @override
  String get name => 'Name';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Email must be in format: user@domain.com';

  @override
  String get newPassword => 'New Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String deleteConfirmation(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get downloadApk => 'Download APK';

  @override
  String get debugConsole => 'Debug Console';

  @override
  String get downloadCsv => 'Download CSV';

  @override
  String get professors => 'Professors';

  @override
  String get total => 'Total';

  @override
  String get idGrowth => 'ID Growth (Activity)';

  @override
  String get systemStatus => 'System Status';

  @override
  String get logs => 'Logs';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get clearLogsConfirmation =>
      'Are you sure you want to clear all logs?';

  @override
  String get clear => 'Clear';

  @override
  String get searchLogs => 'Search Logs';

  @override
  String get all => 'All';

  @override
  String get withInput => 'With Input';

  @override
  String get withOutput => 'With Output';

  @override
  String get stackTraces => 'Stack Traces';

  @override
  String get noLogsMatch => 'No logs match your filters';

  @override
  String get noLogsYet => 'No logs yet';

  @override
  String get input => 'Input';

  @override
  String get output => 'Output';

  @override
  String get trace => 'TRACE';

  @override
  String get fullMessage => 'Full Message';

  @override
  String get stackTrace => 'Stack Trace';

  @override
  String copied(String title) {
    return '$title copied';
  }

  @override
  String get changePassword => 'Change Password';

  @override
  String get passwordChangeSuccess => 'Password changed successfully';

  @override
  String get students => 'Students';

  @override
  String get addStudent => 'Add Student';

  @override
  String get editStudent => 'Edit Student';

  @override
  String get studentCode => 'Student Code';

  @override
  String get activeStatus => 'Active Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get codMatricol => 'Student Code';

  @override
  String get reports => 'Reports';

  @override
  String get scanHistory => 'Scan History';

  @override
  String get enrolledStudents => 'Enrolled Students';

  @override
  String get dateRange => 'Date Range';

  @override
  String get noScansFound => 'No scans found for this period';

  @override
  String get noEnrolledStudents => 'No enrolled students';

  @override
  String get scansToday => 'Scans Today';

  @override
  String get scansWeek => 'Scans Week';

  @override
  String get scansTwoWeeks => 'Scans 2 Weeks';

  @override
  String get scansMonth => 'Scans Month';

  @override
  String get studentsScanned => 'students scanned';

  @override
  String get enrolled => 'Enrolled';
}
