import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_router.dart';
import 'profile_avatar.dart';

class AddShopPage extends StatefulWidget {
  @override
  _AddShopPageState createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  String adminName = 'Admin';
  String appName = 'TrashToTreasure';
  String currentDate = '';
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ownerIDController = TextEditingController();
  String? _selectedProvince;
  final List<String> _provinces = [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad'
  ];

  // Toggles for the days of the week
  bool isOpenMonday = false;
  bool isOpenTuesday = false;
  bool isOpenWednesday = false;
  bool isOpenThursday = false;
  bool isOpenFriday = false;
  bool isOpenSaturday = false;
  bool isOpenSunday = false;

  // Time pickers for each day
  TimeOfDay openingTimeMonday = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay closingTimeMonday = TimeOfDay(hour: 17, minute: 0);
  TimeOfDay openingTimeTuesday = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay closingTimeTuesday = TimeOfDay(hour: 17, minute: 0);
  TimeOfDay openingTimeWednesday = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay closingTimeWednesday = TimeOfDay(hour: 17, minute: 0);
  TimeOfDay openingTimeThursday = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay closingTimeThursday = TimeOfDay(hour: 17, minute: 0);
  TimeOfDay openingTimeFriday = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay closingTimeFriday = TimeOfDay(hour: 17, minute: 0);
  TimeOfDay openingTimeSaturday = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay closingTimeSaturday = TimeOfDay(hour: 17, minute: 0);
  TimeOfDay openingTimeSunday = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay closingTimeSunday = TimeOfDay(hour: 17, minute: 0);

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

  Future<void> _saveShopDetails() async {
    try {
      // Create new shop document
      DocumentReference shopRef = FirebaseFirestore.instance.collection('shops').doc();
      String shopId = shopRef.id;
      String userId = FirebaseAuth.instance.currentUser!.uid;

      await shopRef.set({
        'name': _shopNameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'state': _selectedProvince,
        'createdBy': userId,
        'ownerID': _ownerIDController.text.trim(), // Fixed the issue here
        'operatingHours': {
          'Monday': isOpenMonday
              ? '${openingTimeMonday.format(context)} - ${closingTimeMonday.format(context)}'
              : 'Closed',
          'Tuesday': isOpenTuesday
              ? '${openingTimeTuesday.format(context)} - ${closingTimeTuesday.format(context)}'
              : 'Closed',
          'Wednesday': isOpenWednesday
              ? '${openingTimeWednesday.format(context)} - ${closingTimeWednesday.format(context)}'
              : 'Closed',
          'Thursday': isOpenThursday
              ? '${openingTimeThursday.format(context)} - ${closingTimeThursday.format(context)}'
              : 'Closed',
          'Friday': isOpenFriday
              ? '${openingTimeFriday.format(context)} - ${closingTimeFriday.format(context)}'
              : 'Closed',
          'Saturday': isOpenSaturday
              ? '${openingTimeSaturday.format(context)} - ${closingTimeSaturday.format(context)}'
              : 'Closed',
          'Sunday': isOpenSunday
              ? '${openingTimeSunday.format(context)} - ${closingTimeSunday.format(context)}'
              : 'Closed',
        },
      });

      // Create corresponding shopHistory document
      await FirebaseFirestore.instance.collection('shopHistory').add({
        'shopId': shopId,
        'action': 'created',
        'timestamp': Timestamp.now(),
        'performedBy': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shop added successfully!')),
      );

      Navigator.pop(context); // Navigate back
    } catch (e) {
      print("Error saving shop details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving shop details: $e')),
      );
    }
  }

  Widget _buildTimePickerRow(
      String day,
      TimeOfDay openingTime,
      ValueChanged<TimeOfDay> onOpeningTimeChanged,
      TimeOfDay closingTime,
      ValueChanged<TimeOfDay> onClosingTimeChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$day Opening:', style: TextStyle(fontSize: 16)),
          ElevatedButton(
            onPressed: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: openingTime,
              );
              if (picked != null) {
                onOpeningTimeChanged(picked);
              }
            },
            child: Text(openingTime.format(context)),
          ),
          SizedBox(width: 16),
          Text('Closing:', style: TextStyle(fontSize: 16)),
          ElevatedButton(
            onPressed: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: closingTime,
              );
              if (picked != null) {
                onClosingTimeChanged(picked);
              }
            },
            child: Text(closingTime.format(context)),
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


  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final routerDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
      routerDelegate.navigateTo('/');
    } catch (e) {
      print("Error logging out: $e");
    }
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
    body: SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Heading and Instructions Button
    Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Text(
    "Add New Shop",
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
    "1. Fill in the fields below with the required information.\n"
    "2. Click the Save button to save a new shop.\n"
    "3. Ensure all required fields are filled before saving.",
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
    const SizedBox(height: 16),

    // Form Fields
    TextField(
    controller: _shopNameController,
    decoration: InputDecoration(
    labelText: 'Shop Name',
    border: OutlineInputBorder(),
    ),
    ),
    SizedBox(height: 16),
    TextField(
    controller: _addressController,
    decoration: InputDecoration(
    labelText: 'Address',
    border: OutlineInputBorder(),
    ),
    ),
    SizedBox(height: 16),
    TextField(
    controller: _cityController,
    decoration: InputDecoration(
    labelText: 'City',
    border: OutlineInputBorder(),
    ),
    ),
    SizedBox(height: 16),
    DropdownButtonFormField<String>(
    value: _selectedProvince,
    decoration: InputDecoration(
    labelText: 'Province',
    border: OutlineInputBorder(),
    ),
    items: _provinces.map((province) {
    return DropdownMenuItem(
    value: province,
    child: Text(province),
    );
    }).toList(),
    onChanged: (value) {
    setState(() {
    _selectedProvince = value;
    });
    },
    ),
    SizedBox(height: 16),
    TextField(
    controller: _emailController,
    decoration: InputDecoration(
    labelText: 'Email',
    border: OutlineInputBorder(),
    ),
    ),
    SizedBox(height: 16),
    TextField(
    controller: _phoneController,
    decoration: InputDecoration(
    labelText: 'Phone',
    border: OutlineInputBorder(),
    ),
    ),
      SizedBox(height: 16),
      TextField(
        controller: _ownerIDController,
        decoration: InputDecoration(
          labelText: 'OwnerID',
          border: OutlineInputBorder(),
        ),
      ),
    SizedBox(height: 24),

    // Operating Hours Section
    ...[
    {'day': 'Monday', 'isOpen': isOpenMonday, 'opening': openingTimeMonday, 'closing': closingTimeMonday},
    {'day': 'Tuesday', 'isOpen': isOpenTuesday, 'opening': openingTimeTuesday, 'closing': closingTimeTuesday},
    {'day': 'Wednesday', 'isOpen': isOpenWednesday, 'opening': openingTimeWednesday, 'closing': closingTimeWednesday},
    {'day': 'Thursday', 'isOpen': isOpenThursday, 'opening': openingTimeThursday, 'closing': closingTimeThursday},
    {'day': 'Friday', 'isOpen': isOpenFriday, 'opening': openingTimeFriday, 'closing': closingTimeFriday},
    {'day': 'Saturday', 'isOpen': isOpenSaturday, 'opening': openingTimeSaturday, 'closing': closingTimeSaturday},
    {'day': 'Sunday', 'isOpen': isOpenSunday, 'opening': openingTimeSunday, 'closing': closingTimeSunday},
    ].map((dayInfo) {
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    SwitchListTile(

      title: Text('Open on ${dayInfo['day']}'),
      value: (dayInfo['isOpen'] ?? false) as bool, // Provide a default value if nullable

      onChanged: (value) {
    setState(() {
    switch (dayInfo['day']) {
      case 'Monday':
        isOpenMonday = value;
        break;
      case 'Tuesday':
        isOpenTuesday = value;
        break;
      case 'Wednesday':
        isOpenWednesday = value;
        break;
      case 'Thursday':
        isOpenThursday = value;
        break;
      case 'Friday':
        isOpenFriday = value;
        break;
      case 'Saturday':
        isOpenSaturday = value;
        break;
      case 'Sunday':
        isOpenSunday = value;
        break;
    }
    });
    },
    ),
      if ((dayInfo['isOpen'] ?? false) as bool)
        _buildTimePickerRow(
          dayInfo['day'] as String,
          dayInfo['opening'] as TimeOfDay,
              (newTime) {
            setState(() {
              switch (dayInfo['day']) {
                case 'Monday':
                  openingTimeMonday = newTime;
                  break;
                case 'Tuesday':
                  openingTimeTuesday = newTime;
                  break;
                case 'Wednesday':
                  openingTimeWednesday = newTime;
                  break;
                case 'Thursday':
                  openingTimeThursday = newTime;
                  break;
                case 'Friday':
                  openingTimeFriday = newTime;
                  break;
                case 'Saturday':
                  openingTimeSaturday = newTime;
                  break;
                case 'Sunday':
                  openingTimeSunday = newTime;
                  break;
              }
            });
          },
          dayInfo['closing'] as TimeOfDay,
              (newTime) {
            setState(() {
              switch (dayInfo['day']) {
                case 'Monday':
                  closingTimeMonday = newTime;
                  break;
                case 'Tuesday':
                  closingTimeTuesday = newTime;
                  break;
                case 'Wednesday':
                  closingTimeWednesday = newTime;
                  break;
                case 'Thursday':
                  closingTimeThursday = newTime;
                  break;
                case 'Friday':
                  closingTimeFriday = newTime;
                  break;
                case 'Saturday':
                  closingTimeSaturday = newTime;
                  break;
                case 'Sunday':
                  closingTimeSunday = newTime;
                  break;
              }
            });
          },
        ),
    ],
    );
    }).toList(),
      ElevatedButton(
        onPressed: _saveShopDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF138A36), // Correct parameter
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        ),
        child: Text(
          'Save Shop',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    ],
    ),
    ),
    );
  }
}

