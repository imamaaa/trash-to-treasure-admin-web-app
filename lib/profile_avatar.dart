// profile_avatar.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileAvatar extends StatefulWidget {
  final double radius; // Allow custom radius for flexibility

  ProfileAvatar({this.radius = 24}); // Default radius

  @override
  _ProfileAvatarState createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String imageUrl = ''; // Store profile image URL

  @override
  void initState() {
    super.initState();
    _fetchProfileImage(); // Fetch profile image on widget load
  }

  Future<void> _fetchProfileImage() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot cashierSnapshot = await FirebaseFirestore.instance
            .collection('cashiers')
            .doc(user.uid)
            .get();

        if (cashierSnapshot.exists) {
          var data = cashierSnapshot.data() as Map<String, dynamic>;
          if (data.containsKey('profileImage') &&
              data['profileImage'] != null &&
              data['profileImage'].isNotEmpty) {
            setState(() {
              imageUrl = data['profileImage']; // Set the profile image URL
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius, // Use the radius passed from the widget
      backgroundColor: Colors.transparent,
      backgroundImage: imageUrl.isNotEmpty
          ? NetworkImage(imageUrl) // Use the profile image URL if available
          : null, // Otherwise, fall back to child widget
      child: imageUrl.isEmpty
          ? SvgPicture.asset(
        'assets/images/Avatar.svg', // Default avatar from assets
        width: widget.radius * 2, // Make it fit the radius
        height: widget.radius * 2, // Make it fit the radius
      )
          : null, // No child if profile image is available
    );
  }
}
