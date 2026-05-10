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

  @override
  String get selectTimeInterval => 'Select Time Interval';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get apply => 'Apply';

  @override
  String get sevenDays => '(7 Days)';

  @override
  String get thirtyDays => '(30 Days)';

  @override
  String get thisWeek => '(This Week)';

  @override
  String get thisMonth => '(This Month)';

  @override
  String get searchByStudentName => 'Search by student name...';

  @override
  String get weeklyActivity => 'Weekly Activity';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get blueAccent => 'Blue Accent';

  @override
  String get yellowAccent => 'Yellow Accent';

  @override
  String get uniqueStudents => 'Unique Students (Mon-Fri)';

  @override
  String get filterStudents => 'Filter Students';

  @override
  String get close => 'Close';

  @override
  String get day => 'Day';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get rolling => 'Rolling';

  @override
  String get calendar => 'Calendar';

  @override
  String get totalScans => 'Total Scans';

  @override
  String get hourlyDistribution => 'Distribuție Orară';

  @override
  String get scansPerHour => 'Scans per Hour';

  @override
  String get reportsForAllStudents => 'Reports for all students';

  @override
  String get selectDateOrTimeframe => 'Select a date or timeframe';

  @override
  String get selectOneOrMoreStudents => 'Select one or more students';

  @override
  String get goBackToMainPage => 'Go back to main page';

  @override
  String get goBack => 'Go back';

  @override
  String get detailedStudentReports => 'Detailed Student Reports';

  @override
  String get activeFilters => 'Active filters:';

  @override
  String get studentUses => 'Student Uses';

  @override
  String get scansPerStudent => 'Scans per student';

  @override
  String get done => 'Done';

  @override
  String get clickNext => 'Click next ->';

  @override
  String get helpSlide1Title => 'Select a Day';

  @override
  String get helpSlide1Desc => 'Tap on a day to select it.';

  @override
  String get helpSlide2Title => 'Create a Timeframe';

  @override
  String get helpSlide2Desc => 'Tap 2 different days to create a timeframe.';

  @override
  String get helpSlide3Title => 'Select Specific Hours';

  @override
  String get helpSlide3Desc =>
      'Hold on the selected day (or hold on each edge of a timeframe) to select a specific beginning and end hour.';

  @override
  String get viewDetailedStudentReports => 'View detailed student reports';
}
