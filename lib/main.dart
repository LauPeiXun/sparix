import 'dart:async';
import 'package:flutter/material.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// DI / State
import 'package:provider/provider.dart';
import 'package:sparix/application/providers/employee_provider.dart';
import 'package:sparix/application/providers/notification_provider.dart';
import 'package:sparix/application/providers/product_stream_provider.dart';
import 'package:sparix/application/providers/damage_report_provider.dart';
import 'package:sparix/application/providers/request_report_provider.dart';
import 'package:sparix/application/providers/workshop_report_provider.dart';

// App code
import 'package:sparix/config/firebase_options.dart';
import 'package:sparix/presentation/screens/auth/login_screen.dart';
import 'package:sparix/core/services/firebase_auth_service.dart';
import 'package:sparix/presentation/screens/spare_parts/spare_part_list.dart';
import 'package:sparix/presentation/screens/auth/auth_wrapper.dart' as biometric;

import 'package:sparix/core/services/notification_service.dart';

import 'application/providers/sales_revenue_report_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase & App Check
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  await NotificationService.registerBackgroundHandler();

  await NotificationService.init(navigatorKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ProductStreamProvider()),
        ChangeNotifierProvider(create: (_) => DamageReportProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RequestReportProvider()),
        ChangeNotifierProvider(create: (_) => WorkshopReportProvider()),
        ChangeNotifierProvider(create: (_) => SalesRevenueProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Spare Parts App',
        theme: ThemeData.light(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const biometric.AuthWrapper(
            requireBiometric: true,
            child: HomePage(),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
