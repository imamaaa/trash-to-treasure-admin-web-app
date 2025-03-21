import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'dashboard.dart';
import 'update_points.dart';
import 'manage_users.dart';
import 'view_feedback.dart';
import 'manage_shops.dart';
import 'user_details.dart';
import 'add_user.dart';
import 'profile_settings.dart';
import 'shop_details.dart';
import 'add_shop.dart';

// Class to represent the current page configuration
class PageConfig {
  final String path;
  final Map<String, dynamic>? params;

  const PageConfig(this.path, {this.params});
}

// Route Information Parser
class AppRouteParser extends RouteInformationParser<PageConfig> {
  @override
  Future<PageConfig> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location ?? '/');
    final path = '/' + (uri.pathSegments.isEmpty ? '' : uri.pathSegments.join('/'));
    final params = uri.queryParameters.isNotEmpty ? uri.queryParameters : null;
    return PageConfig(path, params: params);
  }

  @override
  RouteInformation restoreRouteInformation(PageConfig config) {
    if (config.params != null) {
      final queryParams = config.params!.entries.map((e) => '${e.key}=${e.value}').join('&');
      return RouteInformation(location: '${config.path}?$queryParams');
    }
    return RouteInformation(location: config.path);
  }
}

// Router Delegate for handling navigation
class AppRouterDelegate extends RouterDelegate<PageConfig>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<PageConfig> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  String currentPath = '/';
  Map<String, dynamic>? params;

  AppRouterDelegate() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null && currentPath != '/') {
        navigateTo('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        if (FirebaseAuth.instance.currentUser == null)
          MaterialPage(child: AdminLoginPage()), // Redirect to login if not authenticated
        if (currentPath == '/') MaterialPage(child: AdminLoginPage()), // Admin Login
        if (currentPath == '/dashboard') MaterialPage(child: AdminDashboard()), // Admin Dashboard
        if (currentPath == '/view_feedback') MaterialPage(child: ViewFeedbackPage()), // Manage Feedback
        if (currentPath == '/update_points') MaterialPage(child: UpdatePointsPage()),
        if (currentPath == '/manage_users') MaterialPage(child: UserManagementPage()),
        if (currentPath == '/manage_shops') MaterialPage(child: ManageShopsPage()),
        if (currentPath == '/add_user') MaterialPage(child: AddUserPage()),
        if (currentPath == '/add_shop') MaterialPage(child: AddShopPage()),
        if (currentPath == '/profile_settings') MaterialPage(child: AdminProfileSettingsPage()),
        if (currentPath == '/user_details' && params?['userId'] != null)
          MaterialPage(
            child: UserDetailsPage(userId: params!['userId']),
          ),
        if (currentPath == '/shop_details' && params?['shopId'] != null)
          MaterialPage(
            child: ShopDetailsPage(shopId: params!['shopId']),
          ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;

        // Prevent back navigation to authenticated pages if the user isn't logged in
        if (FirebaseAuth.instance.currentUser == null) {
          navigateTo('/');
        }
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(PageConfig config) async {
    if (FirebaseAuth.instance.currentUser == null && config.path != '/') {
      // Prevent navigating to protected routes if not authenticated
      navigateTo('/');
    } else {
      currentPath = config.path;
      params = config.params;
      notifyListeners();
    }
  }

  void navigateTo(String path, {Map<String, dynamic>? params}) async {
    if (path != '/' && !(await isAdmin())) {
      // Redirect to login if not authenticated as admin
      print("Unauthorized access attempt to $path. Redirecting to login.");
      currentPath = '/';
    } else {
      currentPath = path;
      this.params = params;
      print("Navigating to: $path with params: $params");
      notifyListeners();
    }
  }

  Future<bool> isAdmin() async {
    // Check if the current user has admin privileges using Firestore
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Fetch the document from the 'admin' collection using the user ID
        final adminDoc = await FirebaseFirestore.instance
            .collection('admin')
            .doc(currentUser.uid)
            .get();

        // Check if the admin document exists
        if (adminDoc.exists) {
          final data = adminDoc.data();
          return data?['role'] == 'admin';
        }
      } catch (e) {
        print("Error checking admin role: $e");
      }
    }
    return false;
  }

  @override
  PageConfig get currentConfiguration => PageConfig(currentPath, params: params);
}
