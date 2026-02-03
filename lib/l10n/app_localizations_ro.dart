// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Pontaj Admin';

  @override
  String get dashboard => 'Panou de Control';

  @override
  String get users => 'Utilizatori';

  @override
  String get settings => 'Setari';

  @override
  String get logout => 'Deconectare';

  @override
  String get login => 'Autentificare';

  @override
  String get email => 'Email';

  @override
  String get password => 'Parola';

  @override
  String get loginButton => 'Intra in Cont';

  @override
  String get language => 'Limba';

  @override
  String get selectLanguage => 'Selecteaza Limba';

  @override
  String get welcomeBack => 'Bine ai revenit';

  @override
  String get signInMessage =>
      'Te rugam sa te autentifici pentru a accesa portalul.';

  @override
  String get requiredField => 'Obligatoriu';

  @override
  String get schoolName => 'Colegiul Național\n\"Vasile Goldiș\"';

  @override
  String get excellenceInEducation => 'Excelență în Educație';

  @override
  String get noDataToExport => 'Nu există date de exportat';

  @override
  String get statsExportedSuccess => 'Statistici exportate în CSV cu succes';

  @override
  String get editProfessor => 'Editează Profesor';

  @override
  String get addProfessor => 'Adaugă Profesor';

  @override
  String get name => 'Nume';

  @override
  String get emailRequired => 'Email-ul este obligatoriu';

  @override
  String get emailInvalid =>
      'Email-ul trebuie să fie în formatul: user@domain.com';

  @override
  String get newPassword => 'Parolă Nouă';

  @override
  String get passwordRequired => 'Parola este obligatorie';

  @override
  String get passwordMinLength =>
      'Parola trebuie să aibă cel puțin 6 caractere';

  @override
  String get cancel => 'Anulează';

  @override
  String get save => 'Salvează';

  @override
  String get add => 'Adaugă';

  @override
  String get confirmDelete => 'Confirmă Ștergerea';

  @override
  String deleteConfirmation(String name) {
    return 'Ești sigur că vrei să ștergi pe $name?';
  }

  @override
  String get delete => 'Șterge';

  @override
  String get downloadApk => 'Descarcă APK';

  @override
  String get debugConsole => 'Consolă Debug';

  @override
  String get downloadCsv => 'Descarcă CSV';

  @override
  String get professors => 'Profesori';

  @override
  String get total => 'Total';

  @override
  String get idGrowth => 'Creștere ID (Activitate)';

  @override
  String get systemStatus => 'Stare Sistem';

  @override
  String get logs => 'Jurnale';

  @override
  String get clearLogs => 'Șterge Jurnalele';

  @override
  String get clearLogsConfirmation =>
      'Ești sigur că vrei să ștergi toate jurnalele?';

  @override
  String get clear => 'Șterge';

  @override
  String get searchLogs => 'Caută Jurnale';

  @override
  String get all => 'Toate';

  @override
  String get withInput => 'Cu Intrare';

  @override
  String get withOutput => 'Cu Ieșire';

  @override
  String get stackTraces => 'Urme Stivă';

  @override
  String get noLogsMatch => 'Niciun jurnal nu corespunde filtrelor';

  @override
  String get noLogsYet => 'Niciun jurnal încă';

  @override
  String get input => 'Intrare';

  @override
  String get output => 'Ieșire';

  @override
  String get trace => 'URMĂ';

  @override
  String get fullMessage => 'Mesaj Complet';

  @override
  String get stackTrace => 'Urmă Stivă';

  @override
  String copied(String title) {
    return '$title copiat';
  }

  @override
  String get changePassword => 'Schimbă Parola';

  @override
  String get passwordChangeSuccess => 'Parola a fost schimbată cu succes';

  @override
  String get students => 'Elevi';

  @override
  String get addStudent => 'Adaugă Elev';

  @override
  String get editStudent => 'Editează Elev';

  @override
  String get studentCode => 'Cod Matricol';

  @override
  String get activeStatus => 'Status Activ';

  @override
  String get active => 'Activ';

  @override
  String get inactive => 'Inactiv';

  @override
  String get codMatricol => 'Cod Matricol';

  @override
  String get reports => 'Rapoarte';

  @override
  String get scanHistory => 'Istoric Scanări';

  @override
  String get enrolledStudents => 'Elevi Înscriși';

  @override
  String get dateRange => 'Interval Dată';

  @override
  String get noScansFound => 'Nu s-au găsit scanări pentru această perioadă';

  @override
  String get noEnrolledStudents => 'Niciun elev înscris';

  @override
  String get scansToday => 'Scanări Azi';

  @override
  String get scansWeek => 'Scanări Săptămână';

  @override
  String get scansTwoWeeks => 'Scanări 2 Săpt.';

  @override
  String get scansMonth => 'Scanări Lună';

  @override
  String get studentsScanned => 'elevi scanați';

  @override
  String get enrolled => 'Înscriși';
}
