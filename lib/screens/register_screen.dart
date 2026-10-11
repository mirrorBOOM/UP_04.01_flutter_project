import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  Role _role = Role.client;
  bool _loading = false;

  bool get _hasMinLength => _passController.text.length >= 8;
  bool get _hasNumber => RegExp(r'\d').hasMatch(_passController.text);
  bool get _hasSpecial => RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_passController.text);
  bool get _isPasswordValid => _hasMinLength && _hasNumber && _hasSpecial;

  void _submit() async {
    if (!_formKey.currentState!.validate() || !_isPasswordValid) return;
    setState(() => _loading = true);

    try {
      final auth = context.read<AuthNotifier>();
      await auth.register(
        _userController.text.trim(),
        _nameController.text.trim(),
        _passController.text.trim(),
        _role,
      );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: 'Логин *', border: OutlineInputBorder()),
                    validator: AppValidators.requiredField,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'ФИО *', border: OutlineInputBorder()),
                    validator: AppValidators.requiredField,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Role>(
                    initialValue: _role,
                    decoration: const InputDecoration(labelText: 'Роль в клубе', border: OutlineInputBorder()),
                    items: Role.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                    onChanged: (val) => setState(() => _role = val ?? Role.client),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Пароль *', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  _buildRule('Не менее 8 символов', _hasMinLength),
                  _buildRule('Минимум 1 цифра', _hasNumber),
                  _buildRule('Минимум 1 спецсимвол (!@#\$%^&*)', _hasSpecial),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_loading || !_isPasswordValid) ? null : _submit,
                      child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Зарегистрироваться'),
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

  Widget _buildRule(String text, bool ok) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : Colors.red, size: 18),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: ok ? Colors.green : Colors.red, fontSize: 13)),
      ],
    );
  }
}