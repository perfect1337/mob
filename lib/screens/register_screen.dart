import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

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
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.user;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final success = await _authService.register(email, password, role: _selectedRole);

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          setState(() => _errorMessage = 'Email уже используется');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF424242),
        title: const Text('Регистрация', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'email@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите email';
                        if (!value.contains('@')) return 'Некорректный email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Пароль'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: '••••••••',
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите пароль';
                        if (value.length < 6) return 'Минимум 6 символов';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Подтвердите пароль'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hintText: '••••••••',
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Подтвердите пароль';
                        if (value != _passwordController.text) return 'Пароли не совпадают';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Роль'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: UserRole.user,
                          child: Text(UserRole.user.displayName),
                        ),
                        DropdownMenuItem(
                          value: UserRole.admin,
                          child: Text(UserRole.admin.displayName),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedRole = value ?? UserRole.user);
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF616161),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text(
                          'ЗАРЕГИСТРИРОВАТЬСЯ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 1),
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w400),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
      validator: validator,
    );
  }
}