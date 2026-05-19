import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pontaj_admin/l10n/app_localizations.dart';
import '../models/login_response.dart';
import '../services/auth_service.dart';
import '../widgets/language_switcher.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  LoginResponse? _loginResponse;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await _authService.getSession();
    if (session != null && mounted) {
      final token = session['token']!;
      final username = session['username']!;
      final admin = int.tryParse(session['admin'] ?? '0') ?? 0;

      print(
        'DEBUG: Session restored. Admin status from prefs: ${session['admin']}, parsed: $admin',
      );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AdminDashboardScreen(
                token: token,
                username: username,
                adminStatus: admin,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _loginResponse = null;
      });

      final response = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
        _loginResponse = response;
      });

      if (response.isSuccess && mounted) {
        final adminStatus = response.admin ?? 0;
        print(
          'DEBUG: Login success. Admin status from API: \${response.admin}, used: \$adminStatus',
        );

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AdminDashboardScreen(
                  token: response.accessToken!,
                  username: response.username ?? _usernameController.text,
                  adminStatus: adminStatus,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
        await _authService.saveSession(
          response.accessToken!,
          response.username ?? _usernameController.text,
          adminStatus,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Left Side - Branding (Desktop only)
              if (isDesktop)
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF002B5C), // Navy Blue
                          const Color(0xFFD4AF37), // School Gold
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/school_logo.svg',
                            width: 180,
                            height: 180,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            l10n.schoolName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Serif',
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.excellenceInEducation,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Right Side - Login Form
              Expanded(
                flex: 6,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isDesktop) ...[
                                Center(
                                  child: SvgPicture.asset(
                                    'assets/images/school_logo.svg',
                                    width: 100,
                                    height: 100,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).primaryColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  l10n.schoolName,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                        fontFamily: 'Serif',
                                      ),
                                ),
                                const SizedBox(height: 48),
                              ],
                              Text(
                                l10n.welcomeBack,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.headlineMedium?.color,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.signInMessage,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 48),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _usernameController,
                                      decoration: InputDecoration(
                                        labelText: l10n.email,
                                        hintText: 'admin@example.com',
                                        prefixIcon: const Icon(
                                          Icons.email_outlined,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).cardColor,
                                        contentPadding: const EdgeInsets.all(
                                          20,
                                        ),
                                      ),
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                          ? l10n.requiredField
                                          : null,
                                      onFieldSubmitted: (_) => _handleLogin(),
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: l10n.password,
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).cardColor,
                                        contentPadding: const EdgeInsets.all(
                                          20,
                                        ),
                                      ),
                                      obscureText: true,
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                          ? l10n.requiredField
                                          : null,
                                      onFieldSubmitted: (_) => _handleLogin(),
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                l10n.loginButton,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_loginResponse != null &&
                                  !_loginResponse!.isSuccess) ...[
                                const SizedBox(height: 32),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _loginResponse!.detail ??
                                              'Login failed',
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                              // APK Download Button
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(
                                    'https://github.com/some-randomGuy03/pontaj_mobile/releases/download/1.2.2/app-release.apk',
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.download),
                                label: const Text('Download Mobile App'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Positioned(top: 16, right: 16, child: LanguageSwitcher()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
