import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:overlay_support/overlay_support.dart'; // Import overlay support
import 'login.dart'; // Admin login page
import 'dashboard.dart'; // Admin dashboard page
import 'app_router.dart'; // Custom router

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDEsRPmH3JBuxWrOo8A8UH-xX5vD_ZsL9s", // Replace with your admin Firebase credentials
      authDomain: "trashtotreasure-4a540.firebaseapp.com",
      projectId: "trashtotreasure-4a540",
      storageBucket: "trashtotreasure-4a540.appspot.com",
      messagingSenderId: "228866710479",
      appId: "1:228866710479:web:7b18763b153da9eaee90ba",
      measurementId: "G-LED6WMRB15",
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

      // Check if the user is the admin (replace with actual admin email or role check logic)
      if (email == "imamaaamjad@gmail.com") {
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
