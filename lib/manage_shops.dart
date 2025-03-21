import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_router.dart';

class ManageShopsPage extends StatefulWidget {
  @override
  _ManageShopsPageState createState() => _ManageShopsPageState();
}

class _ManageShopsPageState extends State<ManageShopsPage> {
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
      await FirebaseAuth.instance.signOut();
      final routerDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
      routerDelegate.navigateTo('/');
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchShops({String? searchQuery, String? searchFilter}) async {
    final querySnapshot = await FirebaseFirestore.instance.collection('shops').get();
    final List<Map<String, dynamic>> shops = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final shopId = doc.id;

      if (searchQuery != null && searchFilter != null) {
        String fieldValue = '';
        if (searchFilter == 'Name') {
          fieldValue = data['name'] ?? '';
        } else if (searchFilter == 'Email') {
          fieldValue = data['email'] ?? '';
        } else if (searchFilter == 'ID') {
          fieldValue = shopId;
        }

        if (!fieldValue.toLowerCase().contains(searchQuery.toLowerCase())) {
          continue;
        }
      }

      shops.add({
        'shopId': shopId,
        'name': data['name'] ?? 'Unknown Name',
        'email': data['email'] ?? 'Unknown Email',
        'address': data['address'] ?? 'Unknown Address',
      });
    }

    return shops;
  }

  void _onSearch() {
    setState(() {
      errorMessage = '';
    });

    _fetchShops(searchQuery: searchQuery, searchFilter: searchFilter).then((shops) {
      if (shops.isEmpty) {
        setState(() {
          errorMessage = "No results found for '$searchQuery'. Try searching by changing the category.";
        });
      }
    });
  }

  void _navigateToShopDetails(String shopId) {
    final routerDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
    routerDelegate.navigateTo('/shop_details', params: {'shopId': shopId});
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Manage Shops",
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
                          "1. Use the search bar to find shops by name, email, or ID.\n"
                              "2. Click on a shop to view and manage its details.\n"
                              "3. Add a new shop using the 'Add a New Shop' button.",
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
              future: _fetchShops(searchQuery: searchQuery, searchFilter: searchFilter),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final shops = snapshot.data!;
                return ListView.builder(
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];

                    final name = shop['name'] ?? 'Unknown Name';
                    final email = shop['email'] ?? 'Unknown Email';
                    final address = shop['address'] ?? 'Unknown Address';
                    final shopId = shop['shopId'] ?? 'Unknown ID';

                    return GestureDetector(
                      onTap: () => _navigateToShopDetails(shopId),
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('Email: $email\nAddress: $address\nShop ID: $shopId'),
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
                routerDelegate.navigateTo('/add_shop');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF138A36),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text(
                "Add a New Shop",
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
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
