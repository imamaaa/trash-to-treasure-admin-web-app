import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:overlay_support/overlay_support.dart'; // Import overlay support
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv package
import 'login.dart'; // Admin login page
import 'dashboard.dart'; // Admin dashboard page
import 'app_router.dart'; // Custom router

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID']!,
    ),
  );

  await setPersistenceForAdmin();

  runApp(
    OverlaySupport.global( // Wrap the app in OverlaySupport
      child: MyApp(),
    ),
  );
}

Future<void> setPersistenceForAdmin() async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Listen to auth state changes to set persistence for admin users
  auth.authStateChanges().listen((User? user) async {
    if (user != null) {
      final String? email = user.email;

      // Check if the user is the admin (loaded from .env)
      if (email == dotenv.env['ADMIN_EMAIL']) {
        try {
          await auth.setPersistence(Persistence.LOCAL); // Ensure session is persisted for admin
          print("Session persistence set for admin user.");
        } catch (e) {
          print("Error setting persistence: $e");
        }
      } else {
        await auth.setPersistence(Persistence.NONE); // Disable persistence for non-admin users
        print("Session persistence disabled for non-admin user.");
      }
    }
  });
}

class MyApp extends StatelessWidget {
  final AppRouterDelegate _routerDelegate = AppRouterDelegate(); // Custom router delegate
  final AppRouteParser _routeParser = AppRouteParser(); // Route parser

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Admin Portal - Trash to Treasure',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Montserrat', // Consistent typography
        ),
      ),
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeParser,
    );
  }
}
