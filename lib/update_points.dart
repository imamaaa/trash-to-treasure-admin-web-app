import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'app_router.dart';
import 'profile_avatar.dart';
import 'login.dart';

class UpdatePointsPage extends StatefulWidget {
  @override
  _UpdatePointsPageState createState() => _UpdatePointsPageState();
}

class _UpdatePointsPageState extends State<UpdatePointsPage> {
  String adminName = 'Admin'; // Default Admin name
  String appName = 'TrashToTreasure'; // App name
  String currentDate = ''; // Current date
  final Map<String, TextEditingController> _controllers = {}; // For text fields

  @override
  void initState() {
    super.initState();
    _fetchAdminInfo();
    _getCurrentDate();
    _initializeControllers();
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


  void _getCurrentDate() {
    DateTime now = DateTime.now();
    setState(() {
      currentDate = DateFormat('d MMM y').format(now);
    });
  }

  void _initializeControllers() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('points').get();
      if (querySnapshot.docs.isEmpty) {
        print("No points data found.");
      }
      setState(() {
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          print("Fetched category: ${doc.id}, value: ${data['value']}");
          _controllers[doc.id] =
              TextEditingController(text: data['value'].toString());
        }
      });
    } catch (e) {
      print("Error fetching points data: $e");
    }
  }


  Future<void> _updatePoints() async {
    try {
      for (var entry in _controllers.entries) {
        final docId = entry.key;
        final newValue = int.tryParse(entry.value.text);

        if (newValue != null) {
          await FirebaseFirestore.instance
              .collection('points')
              .doc(docId)
              .update({'value': newValue});
        }
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Success!"),
          content: Text("Updated trash category points successfully."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error updating points: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppRouterDelegate routerDelegate =
    Router.of(context).routerDelegate as AppRouterDelegate;
    final String currentPath = routerDelegate.currentPath;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 48),
            Text(
              adminName,
              style: TextStyle(fontSize: 40, color: Color(0xFF138A36)),
            ),
            Spacer(),
            Text(
              appName,
              style: TextStyle(fontSize: 40, color: Color(0xFF138A36)),
            ),
            Spacer(),
            Text(
              currentDate,
              style: TextStyle(fontSize: 40, color: Color(0xFF138A36)),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(currentPath, routerDelegate, context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Manage Trash Category Points",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006400),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Instructions"),
                        content: Text(
                          "1. Adjust the points for each trash category.\n"
                              "2. Click Save to update the points.\n"
                              "3. Only changed values will be updated.",
                          style: TextStyle(fontSize: 18),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: CircleBorder(),
                    side: BorderSide(color: Colors.black, width: 2),
                    padding: EdgeInsets.all(8),
                  ),
                  child: Icon(
                    Icons.info,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: _controllers.entries.map((entry) {
                  final docId = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0), // Add padding inside the card
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Category: $docId", // Add "Category:" before the name
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Black text color
                              ),
                            ),
                            SizedBox(height: 8), // Space between category and text field
                            TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: "Value",
                                labelStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black, // Black label color
                                ),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: _updatePoints,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF138A36), // Use backgroundColor instead of primary
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text("Save", style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
              ),
            ),
          ],
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
}
