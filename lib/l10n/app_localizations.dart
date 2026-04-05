import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ro'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ro, this message translates to:
  /// **'Pontaj Admin'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In ro, this message translates to:
  /// **'Panou de Control'**
  String get dashboard;

  /// No description provided for @users.
  ///
  /// In ro, this message translates to:
  /// **'Utilizatori'**
  String get users;

  /// No description provided for @settings.
  ///
  /// In ro, this message translates to:
  /// **'Setări'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In ro, this message translates to:
  /// **'Deconectare'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In ro, this message translates to:
  /// **'Autentificare'**
  String get login;

  /// No description provided for @email.
  ///
  /// In ro, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ro, this message translates to:
  /// **'Parolă'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In ro, this message translates to:
  /// **'Conectare'**
  String get loginButton;

  /// No description provided for @language.
  ///
  /// In ro, this message translates to:
  /// **'Limbă'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In ro, this message translates to:
  /// **'Selectați Limba'**
  String get selectLanguage;

  /// No description provided for @welcomeBack.
  ///
  /// In ro, this message translates to:
  /// **'Bine ai revenit'**
  String get welcomeBack;

  /// No description provided for @signInMessage.
  ///
  /// In ro, this message translates to:
  /// **'Vă rugăm să vă autentificați pentru a accesa portalul admin.'**
  String get signInMessage;

  /// No description provided for @requiredField.
  ///
  /// In ro, this message translates to:
  /// **'Obligatoriu'**
  String get requiredField;

  /// No description provided for @schoolName.
  ///
  /// In ro, this message translates to:
  /// **'Colegiul Național\n\"Vasile Goldiș\"'**
  String get schoolName;

  /// No description provided for @excellenceInEducation.
  ///
  /// In ro, this message translates to:
  /// **'Excelență în Educație'**
  String get excellenceInEducation;

  /// No description provided for @noDataToExport.
  ///
  /// In ro, this message translates to:
  /// **'Nu există date de exportat'**
  String get noDataToExport;

  /// No description provided for @statsExportedSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Statisticile au fost exportate în CSV cu succes'**
  String get statsExportedSuccess;

  /// No description provided for @editProfessor.
  ///
  /// In ro, this message translates to:
  /// **'Editare Profesor'**
  String get editProfessor;

  /// No description provided for @addProfessor.
  ///
  /// In ro, this message translates to:
  /// **'Adăugare Profesor'**
  String get addProfessor;

  /// No description provided for @name.
  ///
  /// In ro, this message translates to:
  /// **'Nume'**
  String get name;

  /// No description provided for @emailRequired.
  ///
  /// In ro, this message translates to:
  /// **'Email-ul este obligatoriu'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In ro, this message translates to:
  /// **'Email-ul trebuie să fie în format: utilizator@domeniu.com'**
  String get emailInvalid;

  /// No description provided for @newPassword.
  ///
  /// In ro, this message translates to:
  /// **'Parolă Nouă'**
  String get newPassword;

  /// No description provided for @passwordRequired.
  ///
  /// In ro, this message translates to:
  /// **'Parola este obligatorie'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In ro, this message translates to:
  /// **'Parola trebuie să aibă cel puțin 6 caractere'**
  String get passwordMinLength;

  /// No description provided for @cancel.
  ///
  /// In ro, this message translates to:
  /// **'Anulare'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ro, this message translates to:
  /// **'Salvare'**
  String get save;

  /// No description provided for @add.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă'**
  String get add;

  /// No description provided for @confirmDelete.
  ///
  /// In ro, this message translates to:
  /// **'Confirmare Ștergere'**
  String get confirmDelete;

  /// No description provided for @deleteConfirmation.
  ///
  /// In ro, this message translates to:
  /// **'Sigur doriți să ștergeți pe {name}?'**
  String deleteConfirmation(String name);

  /// No description provided for @delete.
  ///
  /// In ro, this message translates to:
  /// **'Șterge'**
  String get delete;

  /// No description provided for @downloadApk.
  ///
  /// In ro, this message translates to:
  /// **'Descarcă APK'**
  String get downloadApk;

  /// No description provided for @debugConsole.
  ///
  /// In ro, this message translates to:
  /// **'Consolă Debug'**
  String get debugConsole;

  /// No description provided for @downloadCsv.
  ///
  /// In ro, this message translates to:
  /// **'Descarcă CSV'**
  String get downloadCsv;

  /// No description provided for @professors.
  ///
  /// In ro, this message translates to:
  /// **'Profesori'**
  String get professors;

  /// No description provided for @total.
  ///
  /// In ro, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @idGrowth.
  ///
  /// In ro, this message translates to:
  /// **'Evoluție ID (Activitate)'**
  String get idGrowth;

  /// No description provided for @systemStatus.
  ///
  /// In ro, this message translates to:
  /// **'Stare Sistem'**
  String get systemStatus;

  /// No description provided for @logs.
  ///
  /// In ro, this message translates to:
  /// **'Jurnale'**
  String get logs;

  /// No description provided for @clearLogs.
  ///
  /// In ro, this message translates to:
  /// **'Șterge Jurnalele'**
  String get clearLogs;

  /// No description provided for @clearLogsConfirmation.
  ///
  /// In ro, this message translates to:
  /// **'Sigur doriți să ștergeți toate jurnalele?'**
  String get clearLogsConfirmation;

  /// No description provided for @clear.
  ///
  /// In ro, this message translates to:
  /// **'Șterge'**
  String get clear;

  /// No description provided for @searchLogs.
  ///
  /// In ro, this message translates to:
  /// **'Căutare Jurnale'**
  String get searchLogs;

  /// No description provided for @all.
  ///
  /// In ro, this message translates to:
  /// **'Toate'**
  String get all;

  /// No description provided for @withInput.
  ///
  /// In ro, this message translates to:
  /// **'Cu Input'**
  String get withInput;

  /// No description provided for @withOutput.
  ///
  /// In ro, this message translates to:
  /// **'Cu Output'**
  String get withOutput;

  /// No description provided for @stackTraces.
  ///
  /// In ro, this message translates to:
  /// **'Stack Traces'**
  String get stackTraces;

  /// No description provided for @noLogsMatch.
  ///
  /// In ro, this message translates to:
  /// **'Niciun jurnal nu corespunde filtrelor'**
  String get noLogsMatch;

  /// No description provided for @noLogsYet.
  ///
  /// In ro, this message translates to:
  /// **'Nu există jurnale încă'**
  String get noLogsYet;

  /// No description provided for @input.
  ///
  /// In ro, this message translates to:
  /// **'Input'**
  String get input;

  /// No description provided for @output.
  ///
  /// In ro, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @trace.
  ///
  /// In ro, this message translates to:
  /// **'TRACE'**
  String get trace;

  /// No description provided for @fullMessage.
  ///
  /// In ro, this message translates to:
  /// **'Mesaj Complet'**
  String get fullMessage;

  /// No description provided for @stackTrace.
  ///
  /// In ro, this message translates to:
  /// **'Stack Trace'**
  String get stackTrace;

  /// No description provided for @copied.
  ///
  /// In ro, this message translates to:
  /// **'{title} copiat'**
  String copied(String title);

  /// No description provided for @changePassword.
  ///
  /// In ro, this message translates to:
  /// **'Schimbă Parola'**
  String get changePassword;

  /// No description provided for @passwordChangeSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Parola a fost schimbată cu succes'**
  String get passwordChangeSuccess;

  /// No description provided for @students.
  ///
  /// In ro, this message translates to:
  /// **'Elevi'**
  String get students;

  /// No description provided for @addStudent.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă Elev'**
  String get addStudent;

  /// No description provided for @editStudent.
  ///
  /// In ro, this message translates to:
  /// **'Editare Elev'**
  String get editStudent;

  /// No description provided for @studentCode.
  ///
  /// In ro, this message translates to:
  /// **'Cod Matricol'**
  String get studentCode;

  /// No description provided for @activeStatus.
  ///
  /// In ro, this message translates to:
  /// **'Stare Activ'**
  String get activeStatus;

  /// No description provided for @active.
  ///
  /// In ro, this message translates to:
  /// **'Activ'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In ro, this message translates to:
  /// **'Inactiv'**
  String get inactive;

  /// No description provided for @codMatricol.
  ///
  /// In ro, this message translates to:
  /// **'Cod Matricol'**
  String get codMatricol;

  /// No description provided for @reports.
  ///
  /// In ro, this message translates to:
  /// **'Rapoarte'**
  String get reports;

  /// No description provided for @scanHistory.
  ///
  /// In ro, this message translates to:
  /// **'Istoric Scanări'**
  String get scanHistory;

  /// No description provided for @enrolledStudents.
  ///
  /// In ro, this message translates to:
  /// **'Elevi Înscriși'**
  String get enrolledStudents;

  /// No description provided for @dateRange.
  ///
  /// In ro, this message translates to:
  /// **'Interval Date'**
  String get dateRange;

  /// No description provided for @noScansFound.
  ///
  /// In ro, this message translates to:
  /// **'Nu s-au găsit scanări pentru această perioadă'**
  String get noScansFound;

  /// No description provided for @noEnrolledStudents.
  ///
  /// In ro, this message translates to:
  /// **'Nu există elevi înscriși'**
  String get noEnrolledStudents;

  /// No description provided for @scansToday.
  ///
  /// In ro, this message translates to:
  /// **'Scanări Azi'**
  String get scansToday;

  /// No description provided for @scansWeek.
  ///
  /// In ro, this message translates to:
  /// **'Scanări Săpt.'**
  String get scansWeek;

  /// No description provided for @scansTwoWeeks.
  ///
  /// In ro, this message translates to:
  /// **'Scanări 2 Săpt.'**
  String get scansTwoWeeks;

  /// No description provided for @scansMonth.
  ///
  /// In ro, this message translates to:
  /// **'Scanări Lună'**
  String get scansMonth;

  /// No description provided for @studentsScanned.
  ///
  /// In ro, this message translates to:
  /// **'elevi scanați'**
  String get studentsScanned;

  /// No description provided for @enrolled.
  ///
  /// In ro, this message translates to:
  /// **'Înrolat'**
  String get enrolled;

  /// No description provided for @selectTimeInterval.
  ///
  /// In ro, this message translates to:
  /// **'Selectați Intervalul Orar'**
  String get selectTimeInterval;

  /// No description provided for @startTime.
  ///
  /// In ro, this message translates to:
  /// **'Ora Start'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In ro, this message translates to:
  /// **'Ora Sfârșit'**
  String get endTime;

  /// No description provided for @apply.
  ///
  /// In ro, this message translates to:
  /// **'Aplică'**
  String get apply;

  /// No description provided for @sevenDays.
  ///
  /// In ro, this message translates to:
  /// **'(7 Zile)'**
  String get sevenDays;

  /// No description provided for @thirtyDays.
  ///
  /// In ro, this message translates to:
  /// **'(30 Zile)'**
  String get thirtyDays;

  /// No description provided for @thisWeek.
  ///
  /// In ro, this message translates to:
  /// **'(Săptămâna aceasta)'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In ro, this message translates to:
  /// **'(Luna aceasta)'**
  String get thisMonth;

  /// No description provided for @searchByStudentName.
  ///
  /// In ro, this message translates to:
  /// **'Caută după nume elev...'**
  String get searchByStudentName;

  /// No description provided for @weeklyActivity.
  ///
  /// In ro, this message translates to:
  /// **'Activitate Săptămânală'**
  String get weeklyActivity;

  /// No description provided for @mon.
  ///
  /// In ro, this message translates to:
  /// **'Lun'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In ro, this message translates to:
  /// **'Mar'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In ro, this message translates to:
  /// **'Mie'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In ro, this message translates to:
  /// **'Joi'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In ro, this message translates to:
  /// **'Vin'**
  String get fri;

  /// No description provided for @lightMode.
  ///
  /// In ro, this message translates to:
  /// **'Mod Luminos'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In ro, this message translates to:
  /// **'Mod Intunecat'**
  String get darkMode;

  /// No description provided for @blueAccent.
  ///
  /// In ro, this message translates to:
  /// **'Accent Albastru'**
  String get blueAccent;

  /// No description provided for @yellowAccent.
  ///
  /// In ro, this message translates to:
  /// **'Accent Galben'**
  String get yellowAccent;

  /// No description provided for @uniqueStudents.
  ///
  /// In ro, this message translates to:
  /// **'Elevi Unici (Lun-Vin)'**
  String get uniqueStudents;

  /// No description provided for @filterStudents.
  ///
  /// In ro, this message translates to:
  /// **'Filtrează Elevi'**
  String get filterStudents;

  /// No description provided for @close.
  ///
  /// In ro, this message translates to:
  /// **'Închide'**
  String get close;

  /// No description provided for @day.
  ///
  /// In ro, this message translates to:
  /// **'Zi'**
  String get day;

  /// No description provided for @week.
  ///
  /// In ro, this message translates to:
  /// **'Săptămână'**
  String get week;

  /// No description provided for @month.
  ///
  /// In ro, this message translates to:
  /// **'Lună'**
  String get month;

  /// No description provided for @rolling.
  ///
  /// In ro, this message translates to:
  /// **'Mobil'**
  String get rolling;

  /// No description provided for @calendar.
  ///
  /// In ro, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @totalScans.
  ///
  /// In ro, this message translates to:
  /// **'Total Scanări'**
  String get totalScans;

  /// No description provided for @hourlyDistribution.
  ///
  /// In ro, this message translates to:
  /// **'Distribuție Orară'**
  String get hourlyDistribution;

  /// No description provided for @scansPerHour.
  ///
  /// In ro, this message translates to:
  /// **'Scanări pe Oră'**
  String get scansPerHour;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
