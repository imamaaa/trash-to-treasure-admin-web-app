import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_router.dart';
import 'profile_avatar.dart';
import 'login.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String adminName = 'Imama Amjad'; // Placeholder for Admin's name
  String appName = 'TrashToTreasure'; // App name to display
  String currentDate = ''; // Placeholder for current date

  @override
  void initState() {
    super.initState();
    _fetchAdminInfo();
    _getCurrentDate();
  }
  Future<void> _fetchAdminInfo() async {
    try {
      // Fetch admin details from the 'admin' collection (assuming there's only one document)
      final adminDoc = await FirebaseFirestore.instance.collection('admin').get();

      if (adminDoc.docs.isNotEmpty) {
        final data = adminDoc.docs.first.data() as Map<String, dynamic>;

        setState(() {
          adminName = '${data['firstName'] ?? 'Admin'} ${data['lastName'] ?? ''}'.trim();
        });

        print("Admin info fetched successfully: $data");
      } else {
        print("No admin document found in the 'admin' collection.");
        setState(() {
          adminName = 'Admin'; // Default fallback
        });
      }
    } catch (e) {
      print("Error fetching admin info: $e");
      setState(() {
        adminName = 'Admin'; // Default fallback
      });
    }
  }


  // Get current date and format it correctly
  void _getCurrentDate() {
    DateTime now = DateTime.now();
    setState(() {
      currentDate = DateFormat('d MMM y').format(now);
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Log the admin out
      await FirebaseAuth.instance.signOut();

      // Use AppRouterDelegate to navigate to the login page
      final routerDelegate = Router.of(context).routerDelegate as AppRouterDelegate;

      // Navigate to the login page and update the currentPath
      routerDelegate.navigateTo('/');
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Get the current route path from AppRouterDelegate
    final AppRouterDelegate routerDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
    final String currentPath = routerDelegate.currentPath;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 48),
            Text(
              adminName, // Display Admin's name
              style: TextStyle(fontSize: 25, color: Color(0xFF138A36)),
            ),
            Spacer(),
            Text(
              appName, // Display App name
              style: TextStyle(fontSize: 25, color: Color(0xFF138A36)),
            ),
            Spacer(),
            Text(
              currentDate, // Display Current date
              style: TextStyle(fontSize: 25, color: Color(0xFF138A36)),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(currentPath, routerDelegate, context),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height, // Full height
          alignment: Alignment.center, // Center the content vertically and horizontally
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              _buildGreenRoundedButton(
                context,
                'Update Points',
                Icons.edit,
                '/update_points',
              ),
              SizedBox(height: 24), // Add space between buttons
              _buildGreenRoundedButton(
                context,
                'Manage Users',
                Icons.people,
                '/manage_users',
              ),
              SizedBox(height: 24), // Add space between buttons
              _buildGreenRoundedButton(
                context,
                'Manage Shops',
                Icons.store,
                '/manage_shops',
              ),
              SizedBox(height: 24), // Add space between buttons
              _buildGreenRoundedButton(
                context,
                'View Feedback',
                Icons.feedback,
                '/view_feedback',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(String currentPath, AppRouterDelegate routerDelegate, BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFF138A36),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF138A36)),
              child: const Text(
                'TrashToTreasure',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    'Dashboard',
                    'assets/images/mainPage.svg',
                    '/dashboard',
                    currentPath,
                    routerDelegate,
                  ),
                  _buildDrawerItem(
                    'Update Points',
                    'assets/images/coinshand.svg',
                    '/update_points',
                    currentPath,
                    routerDelegate,
                  ),
                  _buildDrawerItem(
                    'Manage Users',
                    'assets/images/Borrower.svg',
                    '/manage_users',
                    currentPath,
                    routerDelegate,
                  ),
                  _buildDrawerItem(
                    'Manage Shops',
                    'assets/images/shop.svg',
                    '/manage_shops',
                    currentPath,
                    routerDelegate,
                  ),
                  _buildDrawerItem(
                    'View Feedback',
                    'assets/images/view_feedback.svg',
                    '/view_feedback',
                    currentPath,
                    routerDelegate,
                  ),
                  const SizedBox(height: 30),
                  Divider(color: Colors.white54),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/logout.svg',
                      color: Colors.white,
                      width: 24,
                      height: 24,
                    ),
                    title: Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white54),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  ProfileAvatar(radius: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        TextButton(
                          onPressed: () {
                            routerDelegate.navigateTo('/profile_settings');
                          },
                          child: const Text(
                            'View Profile',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, String iconPath, String route, String currentPath, AppRouterDelegate routerDelegate) {
    return Container(
      decoration: BoxDecoration(
        color: currentPath == route ? Color(0xFF4ABD6F) : Color(0xFF138A36),
        border: currentPath == route ? Border.all(color: Colors.white, width: 2.0) : null,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: SvgPicture.asset(
          iconPath,
          color: Colors.white,
          width: 24,
          height: 24,
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        onTap: () {
          if (currentPath != route) {
            routerDelegate.navigateTo(route);
          }
        },
      ),
    );
  }

  Widget _buildGreenRoundedButton(
      BuildContext context, String title, IconData icon, String routeName) {
    return ElevatedButton.icon(
      onPressed: () {
        final routerDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
        routerDelegate.navigateTo(routeName); // Navigate using RouterDelegate
      },
      icon: Icon(icon, size: 40), // Make the icon bigger
      label: Text(
        title,
        style: TextStyle(fontSize: 24), // Increase text size
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF138A36), // Green color
        foregroundColor: Colors.white, // Sets text and icon color to white
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 60), // Increase padding for larger buttons
      ),
    );
  }
}
