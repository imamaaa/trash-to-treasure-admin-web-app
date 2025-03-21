import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_router.dart';
import 'profile_avatar.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String adminName = 'Admin';
  String appName = 'TrashToTreasure';
  String currentDate = '';
  String searchQuery = '';
  String searchFilter = 'Name';
  String errorMessage = '';
  final TextEditingController searchController = TextEditingController();

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

      // Navigate to the login page and update the currentPath
      routerDelegate.navigateTo('/');
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUsers({String? searchQuery, String? searchFilter}) async {
    final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
    final List<Map<String, dynamic>> users = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = doc.id;

      if (data['role'] == 'admin') continue;

      if (searchQuery != null && searchFilter != null) {
        String fieldValue = '';
        if (searchFilter == 'Name') {
          fieldValue = (data['firstName'] ?? '') + ' ' + (data['lastName'] ?? '');
        } else if (searchFilter == 'Email') {
          fieldValue = data['email'] ?? '';
        } else if (searchFilter == 'ID') {
          fieldValue = userId;
        }

        if (!fieldValue.toLowerCase().contains(searchQuery.toLowerCase())) {
          continue;
        }
      }

      users.add({
        'userId': userId,
        'firstName': data['firstName'] ?? 'Unknown First Name',
        'lastName': data['lastName'] ?? 'Unknown Last Name',
        'email': data['email'] ?? 'Unknown Email',
        'profilePhoto': data['profilePhoto'] ?? '',
      });
    }

    return users;
  }

  void _onSearch() {
    setState(() {
      errorMessage = '';
    });

    _fetchUsers(searchQuery: searchQuery, searchFilter: searchFilter).then((users) {
      if (users.isEmpty) {
        setState(() {
          errorMessage = "No results found for '$searchQuery'. Try searching by changing the category.";
        });
      }
    });
  }

  void _navigateToUserDetails(String userId) {
    final routerDelegate = Router.of(context).routerDelegate as AppRouterDelegate;

    // Navigate to the UserDetailsPage with the userId as a parameter
    routerDelegate.navigateTo('/user_details', params: {'userId': userId});
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
    Text(currentDate, style: TextStyle(fontSize: 40, color: Color(0xFF138A36)))
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
    "User Management",
    style: TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
     color:   Color(0xFF006400),
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
    "1. Use the search bar to find users by name, email, or ID.\n"
    "2. Click on a user to view and manage their details.\n"
    "3. Add a new user using the 'Add a New User' button.",
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
    ),
    _buildSearchBar(),
    if (errorMessage.isNotEmpty)
    Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
    errorMessage,
    style: TextStyle(color: Colors.red, fontSize: 16),
    ),
    ),
    Expanded(
    child: FutureBuilder<List<Map<String, dynamic>>>(
    future: _fetchUsers(searchQuery: searchQuery, searchFilter: searchFilter),
    builder: (context, snapshot) {
    if (!snapshot.hasData) {
    return Center(child: CircularProgressIndicator());
    }
    final users = snapshot.data!;
    return ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, index) {
    final user = users[index];

    final profilePhoto = user['profilePhoto'] ?? '';
    final name = user['firstName'] ?? 'Unknown First Name';
    final lname = user['lastName'] ?? 'Unknown Last Name';
    final email = user['email'] ?? 'Unknown Email';
    final userId = user['userId'] ?? 'Unknown ID';

    return GestureDetector(
    onTap: () => _navigateToUserDetails(userId),
    child: Card(
    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: ListTile(
    leading: CircleAvatar(
    backgroundColor: Colors.transparent,
    backgroundImage: profilePhoto.isNotEmpty
    ? NetworkImage(profilePhoto)
        : null,
    child: profilePhoto.isEmpty
    ? SvgPicture.asset(
    'assets/images/Avatar.svg',
    width: 48,
    height: 48,
    )
        : null,
    ),
    title: Text("$name $lname"),
    subtitle: Text('Email: $email\nUser ID: $userId'),
    ),
    ),
    );
    },
    );
    },
    ),
    ),
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: ElevatedButton(
    onPressed: () {
    final routerDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
    routerDelegate.navigateTo('/add_user');
    },
    style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF138A36),
    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
    textStyle: TextStyle(fontSize: 18),
    ),
    child: Text("Add a New User",
      style: TextStyle(
        color: Color(0xFFFFFFFF),
      ),),
    ),
    ),
    ],
    ),
    );
    }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by $searchFilter',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _onSearch,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          SizedBox(width: 16),
          DropdownButton<String>(
            value: searchFilter,
            onChanged: (value) {
              setState(() {
                searchFilter = value!;
              });
            },
            items: ['Name', 'ID', 'Email'].map((filter) {
              return DropdownMenuItem(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
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
}
