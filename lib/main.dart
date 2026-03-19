import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/providers/user_provider.dart';
import 'package:expense_tracker_app/screens/add_edit_transaction_screen.dart';
import 'package:expense_tracker_app/screens/home_screen.dart';
import 'package:expense_tracker_app/screens/login_screen.dart';
import 'package:expense_tracker_app/screens/statistics_screen.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()..initialize()),
        ChangeNotifierProvider<TransactionProvider>(
          create: (_) => TransactionProvider()..loadTransactions(),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        initialRoute: AppRoutes.root,
        routes: {
          AppRoutes.root: (_) => const RootRouter(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.transactionForm: (_) => const AddEditTransactionScreen(),
          AppRoutes.statistics: (_) => const StatisticsScreen(),
        },
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (userProvider.currentUser == null) {
          return const LoginScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
