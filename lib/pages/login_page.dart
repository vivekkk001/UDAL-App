import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_card.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final workerIdCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Hardcoded credentials
  final Map<String, String> _hardcodedCredentials = {'ID1234': '1234'};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    workerIdCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _errorMessage = null;
    });

    String workerId = workerIdCtrl.text.trim();
    String password = passwordCtrl.text.trim();

    if (workerId.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both Worker ID and Password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check credentials
    if (_hardcodedCredentials.containsKey(workerId) &&
        _hardcodedCredentials[workerId] == password) {
      // Login successful
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HomePage(workerId: workerId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid Worker ID or Password';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF20B2AA), // Light Sea Green
              Color(0xFF008B8B), // Dark Cyan
              Color(0xFF006666), // Darker Teal
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06, // 6% of screen width
                vertical: isSmallScreen ? 16 : 24,
              ),
              child: Column(
                children: [
                  SizedBox(height: isSmallScreen ? 20 : 40),

                  // Logo and Header
                  _buildHeader(isSmallScreen),

                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Login Form
                  _buildLoginForm(screenWidth, isSmallScreen),

                  SizedBox(height: isSmallScreen ? 20 : 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      children: [
        // Logo Container
        Container(
          width: isSmallScreen ? 100 : 130,
          height: isSmallScreen ? 90 : 120,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 246, 244, 244),
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF20B2AA), // Light Sea Green
                Color(0xFF008B8B), // Dark Cyan
                Color(0xFF006666), // Darker Teal
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Icon(
              Icons.local_shipping_rounded,
              size: isSmallScreen ? 45 : 60,
              color: Colors.white,
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 20 : 28),

        // App Title
        Text(
          'UDAL',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isSmallScreen ? 32 : null,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtitle with proper text wrapping
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Municipal Waste Collection Management App',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 18 : 24,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        SizedBox(height: isSmallScreen ? 8 : 12),

        Text(
          'Worker Portal',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 14 : 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(double screenWidth, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: screenWidth > 600 ? 400 : double.infinity,
      ),
      child: Card(
        elevation: 4,
        shadowColor: AppTheme.shadowColor,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 20.0 : 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sign In',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  fontSize: isSmallScreen ? 24 : null,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Enter your credentials to access the system',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 13 : 14,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: isSmallScreen ? 20 : 28),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: StatusCard(
                    title: 'Login Failed',
                    message: _errorMessage!,
                    type: StatusType.error,
                  ),
                ),

              // Worker ID Field
              CustomTextField(
                label: 'Worker ID',
                hintText: 'Enter your worker ID',
                controller: workerIdCtrl,
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.text,
                isRequired: true,
                onSubmitted: (_) => _login(),
              ),

              const SizedBox(height: 18),

              // Password Field
              CustomTextField(
                label: 'Password',
                hintText: 'Enter your password',
                controller: passwordCtrl,
                prefixIcon: Icons.lock_outline,
                suffixIcon: _obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                onSuffixIconPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                obscureText: _obscurePassword,
                isRequired: true,
                onSubmitted: (_) => _login(),
              ),

              SizedBox(height: isSmallScreen ? 24 : 32),

              // Login Button
              CustomButton(
                text: 'Sign In',
                onPressed: _login,
                icon: Icons.login,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
