import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child("posts");
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users");

  File? _imageFile;
  final TextEditingController _captionController = TextEditingController();
  bool _loading = false;

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> uploadImageToImgBB(File image) async {
    final apiKey = dotenv.env['IMGBB_KEY'];
    // Replace with your API Key
    final uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");
    final request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath("image", image.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    final data = jsonDecode(respStr);

    if (data['success'] == true) {
      return data['data']['url'];
    }
    return null;
  }

  Future<void> addPost() async {
    if (_imageFile == null && _captionController.text.isEmpty) return;

    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? "";

    final userSnapshot = await usersRef.child(phone).get();
    final userMap = userSnapshot.value as Map<dynamic, dynamic>?;

    String userName = userMap?['name'] ?? "Unknown";
    String profilePic = userMap?['profilePicUrl'] ?? "";

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await uploadImageToImgBB(_imageFile!);
    }

    final postRef = dbRef.push();
    await postRef.set({
      "userPhone": phone,
      "userName": userName,
      "profilePic": profilePic,
      "caption": _captionController.text.trim(),
      "imageUrl": imageUrl ?? "",
      "likes": 0,
      "comments": 0,
      "watchLater": 0,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });

    _captionController.clear();
    setState(() {
      _imageFile = null;
      _loading = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post added successfully!")),
    );
  }

  Widget postCard(Map<dynamic, dynamic> post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.green.withAlpha((0.4 * 255).toInt()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- User Info ---
          ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: post['profilePic'] != null && post['profilePic'] != ""
                  ? NetworkImage(post['profilePic'])
                  : null,
              child: (post['profilePic'] == null || post['profilePic'] == "")
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              post['userName'] ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: post['timestamp'] != null
                ? Text(
              DateTime.fromMillisecondsSinceEpoch(post['timestamp'])
                  .toLocal()
                  .toString()
                  .split('.')[0],
              style: const TextStyle(fontSize: 12),
            )
                : null,
          ),
          // --- Image ---
          if (post['imageUrl'] != null && post['imageUrl'] != "")
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.zero, bottom: Radius.circular(16)),
              child: Image.network(
                post['imageUrl'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
              ),
            ),
          // --- Caption ---
          if (post['caption'] != null && post['caption'] != "")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                post['caption'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          const Divider(height: 1),
          // --- Actions Row ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.thumb_up_alt_outlined, color: Colors.green[700]),
                  onPressed: () {
                    int likes = post['likes'] ?? 0;
                    dbRef.child(post['key']).update({"likes": likes + 1});
                  },
                ),
                IconButton(
                  icon: Icon(Icons.comment_outlined, color: Colors.blue[700]),
                  onPressed: () {
                    openCommentsSheet(post['key']);
                  },
                ),

                IconButton(
                  icon: Icon(Icons.watch_later_outlined, color: Colors.orange[700]),
                  onPressed: () {
                    int watchLater = post['watchLater'] ?? 0;
                    dbRef.child(post['key']).update({"watchLater": watchLater + 1});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Posts"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () {
              showModalBottomSheet(
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
                      leading: const Icon(Icons.camera_alt),
                      title: const Text("Camera"),
                      onTap: () {
                        pickImage(ImageSource.camera);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (_imageFile != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: "Write a caption...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _loading ? null : addPost,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Post"),
          ),
          const Divider(),

          // --- Posts List ---
          Expanded(
            child: StreamBuilder(
              stream: dbRef.orderByChild("timestamp").onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text("No posts yet"));
                }

                final postsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final postsList = postsMap.entries.toList()
                  ..sort((a, b) {
                    final aTime = a.value['timestamp'] ?? 0;
                    final bTime = b.value['timestamp'] ?? 0;
                    return bTime.compareTo(aTime);
                  });

                return ListView.builder(
                  itemCount: postsList.length,
                  itemBuilder: (context, index) {
                    final post = Map<String, dynamic>.from(postsList[index].value as Map);
                    post['key'] = postsList[index].key;
                    return postCard(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void openCommentsSheet(String postKey) {
    final TextEditingController commentController = TextEditingController();
    final commentRef = dbRef.child(postKey).child("comments");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [

                // --- Header ---
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "Comments",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),

                // --- Comments List ---
                Expanded(
                  child: StreamBuilder(
                    stream: commentRef.onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.snapshot.value == null) {
                        return const Center(child: Text("No comments yet"));
                      }

                      final commentsMap = snapshot.data!.snapshot.value
                      as Map<dynamic, dynamic>;
                      final commentsList = commentsMap.entries.toList()
                        ..sort((a, b) =>
                            (b.value['timestamp'] ?? 0)
                                .compareTo(a.value['timestamp'] ?? 0));

                      return ListView.builder(
                        itemCount: commentsList.length,
                        itemBuilder: (context, index) {
                          final comment = commentsList[index].value;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: comment['profilePic'] != ""
                                  ? NetworkImage(comment['profilePic'])
                                  : null,
                              child: comment['profilePic'] == ""
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(comment['userName'] ?? "User"),
                            subtitle: Text(comment['text'] ?? ""),
                            trailing: Text(
                              DateTime.fromMillisecondsSinceEpoch(
                                  comment['timestamp'])
                                  .toLocal()
                                  .toString()
                                  .split('.')[0],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const Divider(),

                // --- Comment Input ---
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: "Write a comment...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.green),
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;

                          final user = FirebaseAuth.instance.currentUser;
                          final phone = user?.phoneNumber ?? "";

                          final userSnap = await usersRef.child(phone).get();
                          final userMap =
                          userSnap.value as Map<dynamic, dynamic>?;

                          String userName = userMap?['name'] ?? "Unknown";
                          String profilePic =
                              userMap?['profilePicUrl'] ?? "";

                          await commentRef.push().set({
                            "userPhone": phone,
                            "userName": userName,
                            "profilePic": profilePic,
                            "text": commentController.text.trim(),
                            "timestamp": DateTime.now().millisecondsSinceEpoch
                          });

                          commentController.clear();
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
