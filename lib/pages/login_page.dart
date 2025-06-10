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
  final Map<String, String> _hardcodedCredentials = {
    'WORKER001': 'password123',
    'WORKER002': 'worker123', 
    'WORKER003': 'pickup123',
    'ADMIN': 'admin@123',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundLight,
              Color(0xFFE8F5F3),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo and Header
                  _buildHeader(),
                  
                  const SizedBox(height: 48),
                  
                  // Login Form
                  _buildLoginForm(),
                  
                  const SizedBox(height: 32),
                  
                  // Demo Credentials
                  _buildDemoCredentials(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo Container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppTheme.cardShadow,
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // App Title
        Text(
          'Municipality',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        
        Text(
          'Pickup Logger',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.secondaryTeal,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Worker Portal',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Card(
      elevation: 4,
      shadowColor: AppTheme.shadowColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign In',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Enter your credentials to access the system',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),

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
            
            const SizedBox(height: 20),

            // Password Field
            CustomTextField(
              label: 'Password',
              hintText: 'Enter your password',
              controller: passwordCtrl,
              prefixIcon: Icons.lock_outline,
              suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
              onSuffixIconPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              obscureText: _obscurePassword,
              isRequired: true,
              onSubmitted: (_) => _login(),
            ),
            
            const SizedBox(height: 32),

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
    );
  }

  Widget _buildDemoCredentials() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Demo Credentials',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Use any of these credentials for testing:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 12),
            
            ..._hardcodedCredentials.entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderGrey),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entry.key} / ${entry.value}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          // Copy to clipboard functionality could be added here
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied: ${entry.key}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        color: AppTheme.primaryGreen,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}