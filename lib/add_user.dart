import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'profile_avatar.dart';
import 'app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddUserPage extends StatefulWidget {
  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  String adminName = 'Admin';
  String appName = 'TrashToTreasure';
  String currentDate = '';
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? adminEmail;
  User? adminUser;

  @override
  void initState() {
    super.initState();
    _checkAdminSession();
    _fetchAdminInfo();
    _getCurrentDate();
  }

  Future<void> _checkAdminSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email == adminEmail) {
      setState(() {
        adminUser = user; // Persist the admin session
      });
    }
  }

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

  Future<void> _fetchAdminInfo() async {
    try {
      final adminDoc = await FirebaseFirestore.instance.collection('admin').get();
      if (adminDoc.docs.isNotEmpty) {
        final data = adminDoc.docs.first.data();
        if (data != null && data.containsKey('email')) {
          setState(() {
            adminName = '${data['firstName'] ?? 'Admin'} ${data['lastName'] ?? ''}'.trim();
            adminEmail = data['email'];
          });
          print("Admin info fetched successfully: $adminEmail");

          // Check if current user matches admin email
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser?.email == adminEmail) {
            setState(() {
              adminUser = currentUser;
            });
            print("Debug: Admin session valid. User: $adminUser");
          } else {
            print("Debug: Admin session invalid. Current user: $currentUser");

            // Force Re-authentication
            print("Debug: Re-authenticating admin...");
            try {
              final adminCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: adminEmail!,
                password: "admin12", // Replace with secure password retrieval
              );
              setState(() {
                adminUser = adminCredential.user;
              });
              print("Debug: Re-authenticated admin successfully.");
            } catch (authError) {
              print("Error re-authenticating admin: $authError");
              _showErrorDialog("Admin session expired. Please log in again.");
            }
          }
        } else {
          throw Exception("Missing 'email' in admin document.");
        }
      } else {
        throw Exception("No admin document found in the 'admin' collection.");
      }
    } catch (e) {
      print("Error fetching admin info: $e");
      setState(() {
        adminName = 'Admin';
      });
      _showErrorDialog("Failed to fetch admin info. Please check your database.");
    }
  }



  Future<void> _addUser(BuildContext context) async {
    String errorMessage = '';

    // Validate inputs
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      errorMessage = "All fields are required.";
    } else if (passwordController.text != confirmPasswordController.text) {
      errorMessage = "Passwords do not match.";
    } else if (!RegExp(r"^[^@]+@[^@]+\.[^@]+$").hasMatch(emailController.text.trim())) {
      errorMessage = "Invalid email format.";
    } else if (passwordController.text.length < 6) {
      errorMessage = "Password must be at least 6 characters.";
    }

    if (errorMessage.isNotEmpty) {
      _showErrorDialog(errorMessage);
      return;
    }

    try {
      // Ensure admin session is active
      if (adminUser == null || adminEmail == null) {
        print("Debug: Admin User: $adminUser, Admin Email: $adminEmail");
        print("Debug: Firebase Current User: ${FirebaseAuth.instance.currentUser}");
        _showErrorDialog("Admin session expired. Please log in again.");
        return;
      }


      // Step 1: Create a new user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Step 2: Add the new user's details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
      });

      // Step 3: Send verification email to the new user
      await userCredential.user?.sendEmailVerification();

      // Step 4: Explicitly log out the newly created user
      await FirebaseAuth.instance.signOut();

      // Step 5: Re-authenticate admin using adminEmail
      UserCredential adminCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail!,
        password: "admin12", // Replace with secure admin password retrieval
      );

      adminUser = adminCredential.user; // Update adminUser with the authenticated admin

      // Step 6: Success dialog
      _showSuccessDialog("User added successfully! A verification link has been sent to their email.");
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = "Password is too weak.";
            break;
          case 'email-already-in-use':
            errorMessage = "This email is already in use.";
            break;
          default:
            errorMessage = "An error occurred: ${e.message}";
        }
      } else {
        errorMessage = "An unknown error occurred.";
      }
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error!"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Success!"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
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


  @override
  Widget build(BuildContext context) {
    final AppRouterDelegate routerDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
    final String currentPath = routerDelegate.currentPath;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(adminName, style: TextStyle(fontSize: 40, color: Color(0xFF138A36))),
            Spacer(),
            Text(appName, style: TextStyle(fontSize: 40, color: Color(0xFF138A36))),
            Spacer(),
            Text(currentDate, style: TextStyle(fontSize: 40, color: Color(0xFF138A36))),
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
                  "Add New User",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006400),
                  ),
                ),
                SizedBox(width: 8), // Add spacing between text and icon
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Instructions"),
                        content: Text(
                          "1. Fill out all required fields for the new user.\n"
                              "2. Ensure the email and password are valid.\n"
                              "3. Click 'Confirm' to add the user and send a verification email.\n"
                              "4. The admin session will remain active after the user is created.",
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
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ProfileAvatar(radius: 50),
                Icon(Icons.camera_alt, color: Colors.grey, size: 28),
              ],
            ),
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: "First Name"),
            ),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: "Last Name"),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
            ),
            SizedBox(height: 24), // Add spacing between text fields and button
            ElevatedButton(
              onPressed: () async {
                await _fetchAdminInfo(); // Fetch admin info before proceeding
                if (adminEmail != null) {
                  print("Debug: Admin email fetched successfully: $adminEmail");
                  await _addUser(context); // Then call _addUser
                } else {
                  _showErrorDialog("Failed to fetch admin info. Cannot proceed.");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF138A36),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Confirm"),
            ),

          ],
        ),
      ),
    );
  }
}
