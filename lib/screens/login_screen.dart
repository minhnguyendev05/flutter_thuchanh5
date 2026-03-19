import 'package:expense_tracker_app/providers/user_provider.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.account_balance_wallet, size: 80, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Expense Tracker',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để quản lý chi tiêu cá nhân.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: userProvider.isLoading
                          ? null
                          : () async {
                              final success = await context.read<UserProvider>().signInWithGoogle();
                              if (success && context.mounted) {
                                Navigator.pushReplacementNamed(context, AppRoutes.home);
                              }
                            },
                      icon: const Icon(Icons.login),
                      label: Text(userProvider.isLoading ? 'Đang đăng nhập...' : 'Đăng nhập Google'),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
