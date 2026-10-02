import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../services/favorites_service.dart';
import 'main_navigation_screen.dart';

const _navy = Color(0xFF1E1B4B);
const _muted = Color(0xFF6B7280);
const _fieldBorder = Color(0xFFE5E7EB);

class EmailAuthScreen extends StatefulWidget {
  /// Opens on the "Create account" tab instead of "Sign in".
  final bool startWithRegister;
  const EmailAuthScreen({super.key, this.startWithRegister = false});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isRegister = widget.startWithRegister;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(bool register) {
    if (_isLoading || register == _isRegister) return;
    setState(() {
      _isRegister = register;
      _errorMessage = '';
    });
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final res = _isRegister
        ? await ApiService.register(
            name: _nameController.text.trim(),
            email: email,
            phone: _phoneController.text.trim(),
            password: password,
          )
        : await ApiService.login(email, password);

    if (!mounted) return;

    if (res['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage = res['message']?.toString() ?? 'Something went wrong. Please try again.';
      });
      return;
    }

    final data = res['data'];
    if (data?['user'] != null) {
      ProfileService().setUserFromBackend(data['user'], data['customer']);
    }
    await ProfileService().syncWithBackend();
    await FavoritesService().syncWithBackend();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _muted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _fieldBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _fieldBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFFC107), width: 1.8)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.red.shade400)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.red.shade400, width: 1.8)),
      labelStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w500),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: selected ? _navy : _muted),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 110,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back, color: _navy, size: 24),
                SizedBox(width: 6),
                Text('Back', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navy)),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRegister ? 'Create your\naccount' : 'Welcome\nback',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _navy, height: 1.25),
                ),
                const SizedBox(height: 10),
                Text(
                  _isRegister ? 'Sign up with your email to start ordering' : 'Sign in with your email and password',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _muted, height: 1.4),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      _tab('Sign in', !_isRegister, () => _setMode(false)),
                      _tab('Create account', _isRegister, () => _setMode(true)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_errorMessage, style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),

                if (_isRegister) ...[
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _navy),
                    decoration: _decoration('Full name', Icons.person_outline),
                    validator: (v) => (v ?? '').trim().length < 2 ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 14),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _navy),
                  decoration: _decoration('Email', Icons.mail_outline, hint: 'you@example.com'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 14),

                if (_isRegister) ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _navy),
                    decoration: _decoration('Mobile number', Icons.phone_outlined, hint: '03XX XXXXXXX'),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'[\s\-+()]'), '');
                      return digits.length < 10 ? 'Enter a valid mobile number' : null;
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 6, top: 6),
                    child: Text('Riders call this number when your order arrives.', style: TextStyle(fontSize: 11.5, color: _muted)),
                  ),
                  const SizedBox(height: 14),
                ],

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: [_isRegister ? AutofillHints.newPassword : AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _navy),
                  decoration: _decoration(
                    'Password',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _muted, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.isEmpty) return 'Please enter your password';
                    if (_isRegister && value.length < 8) return 'Use at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE054), Color(0xFFFFC727)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(_navy)),
                          )
                        : Text(
                            _isRegister ? 'CREATE ACCOUNT' : 'SIGN IN',
                            style: const TextStyle(color: _navy, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: GestureDetector(
                    onTap: () => _setMode(!_isRegister),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text.rich(
                        TextSpan(
                          text: _isRegister ? 'Already have an account? ' : "Don't have an account? ",
                          style: const TextStyle(color: _muted, fontSize: 13),
                          children: [
                            TextSpan(
                              text: _isRegister ? 'Sign in' : 'Create one',
                              style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
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
  }
}
