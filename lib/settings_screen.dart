import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'otp_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? profilePicUrl;
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child("users");
  String phone = "";

  @override
  void initState() {
    super.initState();
    loadProfilePic();
  }

  Future<void> loadProfilePic() async {
    final user = FirebaseAuth.instance.currentUser;
    phone = user?.phoneNumber ?? "";

    final snapshot = await dbRef.child(phone).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        profilePicUrl = data["profilePicUrl"];
      });
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OTPScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          // --- Profile Button ---
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.green,
              backgroundImage:
              profilePicUrl != null ? NetworkImage(profilePicUrl!) : null,
              child: profilePicUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: const Text(
              "Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(user?.phoneNumber ?? "Unknown"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) {
                // Reload profile pic after returning from ProfileScreen
                loadProfilePic();
              });
            },
          ),
          const Divider(height: 30),
          // --- Logout Button ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(fontSize: 18),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
