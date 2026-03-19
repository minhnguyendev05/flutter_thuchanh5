import 'package:expense_tracker_app/providers/user_provider.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    final success = _isRegisterMode
        ? await userProvider.registerWithEmailPassword(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
        : await userProvider.signInWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Expense Tracker',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegisterMode
                              ? 'Tạo tài khoản với Email hoặc Google.'
                              : 'Đăng nhập với Email hoặc Google.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Đăng nhập'),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Đăng ký'),
                            ),
                          ],
                          selected: {_isRegisterMode},
                          onSelectionChanged: userProvider.isLoading
                              ? null
                              : (selection) {
                                  setState(() {
                                    _isRegisterMode = selection.first;
                                    _nameController.clear();
                                    _emailController.clear();
                                    _passwordController.clear();
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
                        if (_isRegisterMode)
                          Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Họ tên',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập họ tên';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!value.contains('@')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.trim().length < 6) {
                              return 'Mật khẩu tối thiểu 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: userProvider.isLoading ? null : _submitEmailPassword,
                          icon: userProvider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(_isRegisterMode ? Icons.person_add_alt_1 : Icons.login),
                          label: Text(
                            userProvider.isLoading
                                ? 'Đang xử lý...'
                                : (_isRegisterMode ? 'Đăng ký Email' : 'Đăng nhập Email'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: userProvider.isLoading
                              ? null
                              : () async {
                                  final success = await context.read<UserProvider>().signInWithGoogle();
                                  if (success && mounted) {
                                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                                  }
                                },
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('Đăng nhập Google'),
                        ),
                        if (userProvider.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            userProvider.error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
