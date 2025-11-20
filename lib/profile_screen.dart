import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  bool loading = true;
  String phone = "";
  String? profilePicUrl;

  final DatabaseReference dbRef =
  FirebaseDatabase.instance.ref().child("users");

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    phone = user?.phoneNumber ?? "";

    final snapshot = await dbRef.child(phone).get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      nameController.text = data["name"] ?? "";
      bioController.text = data["bio"] ?? "";
      profilePicUrl = data["profilePicUrl"];
    }

    setState(() => loading = false);
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> uploadImageToImgBB(File image) async {
    final apiKey = dotenv.env['IMGBB_KEY'];
    // Replace with your ImgBB API Key
    final uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");
    final request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath("image", image.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    final data = jsonDecode(respStr);

    if (data['success'] == true) {
      return data['data']['url'];
    } else {
      return null;
    }
  }

  Future<void> saveProfile() async {
    setState(() => loading = true);

    String? imageUrl = profilePicUrl;
    if (_imageFile != null) {
      imageUrl = await uploadImageToImgBB(_imageFile!);
    }

    await dbRef.child(phone).set({
      "name": nameController.text.trim(),
      "bio": bioController.text.trim(),
      "phone": phone,
      "profilePicUrl": imageUrl ?? "",
    });

    setState(() => profilePicUrl = imageUrl);
    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green.shade200,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : profilePicUrl != null
                      ? NetworkImage(profilePicUrl!) as ImageProvider
                      : null,
                  child: (_imageFile == null && profilePicUrl == null)
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo),
                          title: const Text("Gallery"),
                          onTap: () {
                            pickImage(ImageSource.gallery);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera),
                          title: const Text("Camera"),
                          onTap: () {
                            pickImage(ImageSource.camera);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: bioController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: phone),
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Phone Number",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                hintText: phone,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
