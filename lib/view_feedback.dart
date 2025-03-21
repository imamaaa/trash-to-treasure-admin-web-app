import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_router.dart';
import 'profile_avatar.dart';
import 'login.dart';

class ViewFeedbackPage extends StatefulWidget {
  @override
  _ViewFeedbackPageState createState() => _ViewFeedbackPageState();
}

class _ViewFeedbackPageState extends State<ViewFeedbackPage> {
  String adminName = 'Admin'; // Default Admin name
  String appName = 'TrashToTreasure'; // App name
  String currentDate = ''; // Current date

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

      // Clear navigation history and set path to login
      routerDelegate.navigateTo('/');
      routerDelegate.setNewRoutePath(PageConfig('/')); // Reset the currentPath
    } catch (e) {
      print("Error logging out: $e");
    }
  }


  Future<void> _toggleReadStatus(String feedbackId, bool isRead) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(feedbackId)
          .update({'isRead': !isRead});
    } catch (e) {
      print("Error updating read status: $e");
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Client Feedback Management',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006400),
                  ),
                ),
                const SizedBox(width: 8), // Space between the text and the info button
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Instructions for Feedback Management"),
                        content: Text(
                          "1. View all user feedback categorized as Read or Unread.\n"
                              "2. Mark feedback as Read or Unread as needed.\n"
                              "3. Use the drawer to navigate between other admin functions.",
                          style: TextStyle(fontSize: 18), // Larger font for readability
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
                    shape: CircleBorder(), // Circular outline for the button
                    side: BorderSide(color: Colors.black, width: 2), // Black border
                    padding: EdgeInsets.all(8), // Adjust padding for icon size
                  ),
                  child: Icon(
                    Icons.info,
                    color: Colors.black, // Black icon color
                    size: 30, // Icon size
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feedback')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final feedbackDocs = snapshot.data!.docs;

                final unreadFeedback = feedbackDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return !(data['isRead'] ?? false);
                }).toList();

                final readFeedback = feedbackDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isRead'] == true;
                }).toList();

                return ListView(
                  children: [
                    _buildFeedbackCategory('Unread', unreadFeedback, true),
                    _buildFeedbackCategory('Read', readFeedback, false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCategory(
      String title, List<QueryDocumentSnapshot> feedbackDocs, bool isUnread) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Center-align categories
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isUnread ? Colors.red : Colors.green,
            ),
            textAlign: TextAlign.center, // Center-align text
          ),
        ),
        ...feedbackDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final formattedDate = DateFormat('d MMM y, hh:mm a').format(timestamp);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: GestureDetector(
              onTap: () => _openFeedbackDetail(context, doc.id, data),
              child: Card(
                color: Colors.white, // Background color of the card
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity, // Take full width of the screen
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center-align content
                    children: [
                      Text(
                        data['subject'] ?? 'No Subject',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }


  void _openFeedbackDetail(
      BuildContext context, String feedbackId, Map<String, dynamic> data) async {
    final userId = data['userId'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['subject'] ?? 'No Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Content: ${data['content'] ?? 'No Content'}'),
            Text('User ID: $userId'),
            Text(
                'Timestamp: ${DateFormat('d MMM y, hh:mm a').format((data['timestamp'] as Timestamp).toDate())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('feedback')
                  .doc(feedbackId)
                  .update({'isRead': !(data['isRead'] ?? false)});
              Navigator.of(context).pop();
            },
            child:
            Text((data['isRead'] ?? false) ? 'Mark as Unread' : 'Mark as Read'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
      String currentPath, AppRouterDelegate routerDelegate, BuildContext context) {
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

  Widget _buildDrawerItem(String title, String iconPath, String route,
      String currentPath, AppRouterDelegate routerDelegate) {
    return Container(
      decoration: BoxDecoration(
        color: currentPath == route ? Color(0xFF4ABD6F) : Color(0xFF138A36),
        border: currentPath == route
            ? Border.all(color: Colors.white, width: 2.0)
            : null,
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
