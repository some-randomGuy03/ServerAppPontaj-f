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
  String get settings => 'Setări';

  @override
  String get logout => 'Deconectare';

  @override
  String get login => 'Autentificare';

  @override
  String get email => 'Email';

  @override
  String get password => 'Parolă';

  @override
  String get loginButton => 'Conectare';

  @override
  String get language => 'Limbă';

  @override
  String get selectLanguage => 'Selectați Limba';

  @override
  String get welcomeBack => 'Bine ai revenit';

  @override
  String get signInMessage =>
      'Vă rugăm să vă autentificați pentru a accesa portalul admin.';

  @override
  String get requiredField => 'Obligatoriu';

  @override
  String get schoolName => 'Colegiul Național\n\"Vasile Goldiș\"';

  @override
  String get excellenceInEducation => 'Excelență în Educație';

  @override
  String get noDataToExport => 'Nu există date de exportat';

  @override
  String get statsExportedSuccess =>
      'Statisticile au fost exportate în CSV cu succes';

  @override
  String get editProfessor => 'Editare Profesor';

  @override
  String get addProfessor => 'Adăugare Profesor';

  @override
  String get name => 'Nume';

  @override
  String get emailRequired => 'Email-ul este obligatoriu';

  @override
  String get emailInvalid =>
      'Email-ul trebuie să fie în format: utilizator@domeniu.com';

  @override
  String get newPassword => 'Parolă Nouă';

  @override
  String get passwordRequired => 'Parola este obligatorie';

  @override
  String get passwordMinLength =>
      'Parola trebuie să aibă cel puțin 6 caractere';

  @override
  String get cancel => 'Anulare';

  @override
  String get save => 'Salvare';

  @override
  String get add => 'Adaugă';

  @override
  String get confirmDelete => 'Confirmare Ștergere';

  @override
  String deleteConfirmation(String name) {
    return 'Sigur doriți să ștergeți pe $name?';
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
  String get idGrowth => 'Evoluție ID (Activitate)';

  @override
  String get systemStatus => 'Stare Sistem';

  @override
  String get logs => 'Jurnale';

  @override
  String get clearLogs => 'Șterge Jurnalele';

  @override
  String get clearLogsConfirmation =>
      'Sigur doriți să ștergeți toate jurnalele?';

  @override
  String get clear => 'Șterge';

  @override
  String get searchLogs => 'Căutare Jurnale';

  @override
  String get all => 'Toate';

  @override
  String get withInput => 'Cu Input';

  @override
  String get withOutput => 'Cu Output';

  @override
  String get stackTraces => 'Stack Traces';

  @override
  String get noLogsMatch => 'Niciun jurnal nu corespunde filtrelor';

  @override
  String get noLogsYet => 'Nu există jurnale încă';

  @override
  String get input => 'Input';

  @override
  String get output => 'Output';

  @override
  String get trace => 'TRACE';

  @override
  String get fullMessage => 'Mesaj Complet';

  @override
  String get stackTrace => 'Stack Trace';

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
  String get editStudent => 'Editare Elev';

  @override
  String get studentCode => 'Cod Matricol';

  @override
  String get activeStatus => 'Stare Activ';

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
  String get dateRange => 'Interval Date';

  @override
  String get noScansFound => 'Nu s-au găsit scanări pentru această perioadă';

  @override
  String get noEnrolledStudents => 'Nu există elevi înscriși';

  @override
  String get scansToday => 'Scanări Azi';

  @override
  String get scansWeek => 'Scanări Săpt.';

  @override
  String get scansTwoWeeks => 'Scanări 2 Săpt.';

  @override
  String get scansMonth => 'Scanări Lună';

  @override
  String get studentsScanned => 'elevi scanați';

  @override
  String get enrolled => 'Înrolat';

  @override
  String get selectTimeInterval => 'Selectați Intervalul Orar';

  @override
  String get startTime => 'Ora Start';

  @override
  String get endTime => 'Ora Sfârșit';

  @override
  String get apply => 'Aplică';

  @override
  String get sevenDays => '(7 Zile)';

  @override
  String get thirtyDays => '(30 Zile)';

  @override
  String get thisWeek => '(Săptămâna aceasta)';

  @override
  String get thisMonth => '(Luna aceasta)';

  @override
  String get searchByStudentName => 'Caută după nume elev...';

  @override
  String get weeklyActivity => 'Activitate Săptămânală';

  @override
  String get mon => 'Lun';

  @override
  String get tue => 'Mar';

  @override
  String get wed => 'Mie';

  @override
  String get thu => 'Joi';

  @override
  String get fri => 'Vin';

  @override
  String get lightMode => 'Mod Luminos';

  @override
  String get darkMode => 'Mod Intunecat';

  @override
  String get blueAccent => 'Accent Albastru';

  @override
  String get yellowAccent => 'Accent Galben';

  @override
  String get uniqueStudents => 'Elevi Unici (Lun-Vin)';

  @override
  String get filterStudents => 'Filtrează Elevi';

  @override
  String get close => 'Închide';

  @override
  String get day => 'Zi';

  @override
  String get week => 'Săptămână';

  @override
  String get month => 'Lună';

  @override
  String get rolling => 'Mobil';

  @override
  String get calendar => 'Calendar';

  @override
  String get totalScans => 'Total Scanări';

  @override
  String get hourlyDistribution => 'Distribuție Orară';

  @override
  String get scansPerHour => 'Scanări pe Oră';

  @override
  String get reportsForAllStudents => 'Rapoarte pentru toți elevii';

  @override
  String get selectDateOrTimeframe => 'Selectează o dată sau un interval';

  @override
  String get selectOneOrMoreStudents => 'Selectează unul sau mai mulți elevi';

  @override
  String get goBackToMainPage => 'Înapoi la pagina principală';

  @override
  String get goBack => 'Înapoi';

  @override
  String get detailedStudentReports => 'Rapoarte Detaliate Elevi';

  @override
  String get activeFilters => 'Filtre active:';

  @override
  String get studentUses => 'Utilizări Elevi';

  @override
  String get scansPerStudent => 'Scanări per elev';

  @override
  String get done => 'Gata';

  @override
  String get clickNext => 'Apasă următorul ->';

  @override
  String get helpSlide1Title => 'Selectează o zi';

  @override
  String get helpSlide1Desc => 'Apasă pe o zi pentru a o selecta.';

  @override
  String get helpSlide2Title => 'Creează un interval';

  @override
  String get helpSlide2Desc =>
      'Apasă pe 2 zile diferite pentru a crea un interval.';

  @override
  String get helpSlide3Title => 'Selectează ore specifice';

  @override
  String get helpSlide3Desc =>
      'Ȟine apăsat pe ziua selectată (sau pe fiecare capăt al intervalului) pentru a selecta o oră de început şi de sfârşit.';

  @override
  String get viewDetailedStudentReports =>
      'Vezi rapoartele detaliate ale elevilor';
}
