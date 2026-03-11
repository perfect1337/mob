import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final success = await _authService.register(email, password);

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Регистрация успешна!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(20),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Email уже используется',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(20),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEC4899),
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
         
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  
            
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        size: 50,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
           
                  const Text(
                    'Регистрация',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
               
                  Container(
                    width: 360, 
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                 
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(10),
                                child: const Icon(Icons.email_outlined, color: Color(0xFFEC4899), size: 20),
                              ),
                              labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Введите email';
                              if (!value.contains('@')) return 'Введите корректный email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          
                   
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(10),
                                child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFEC4899), size: 20),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  color: const Color(0xFFEC4899),
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                              labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Введите пароль';
                              if (value.length < 6) return 'Минимум 6 символов';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          
                 
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Подтвердите пароль',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(10),
                                child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFEC4899), size: 20),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  color: const Color(0xFFEC4899),
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                              ),
                              labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Подтвердите пароль';
                              if (value != _passwordController.text) return 'Пароли не совпадают';
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 35), 
                          
                          
                          SizedBox(
                            width: double.infinity,
                            height: 60, 
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEC4899),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 5,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('ЗАРЕГИСТРИРОВАТЬСЯ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                        SizedBox(width: 8),
                                        Icon(Icons.rocket_launch_rounded, size: 22),
                                      ],
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
              
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: RichText(
                              text: TextSpan(
                                text: 'Уже есть аккаунт? ',
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                                children: [
                                  TextSpan(
                                    text: 'Войти',
                                    style: TextStyle(
                                      color: const Color(0xFFEC4899),
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: const Color(0xFFEC4899),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}