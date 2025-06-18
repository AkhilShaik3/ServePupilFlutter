import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../user_profile.dart';
import 'ProfileViewPage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final phoneController = TextEditingController();
  File? _imageFile;
  String? _existingImageUrl;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final snapshot =
    await FirebaseDatabase.instance.ref().child('users/$uid').get();
    if (snapshot.exists) {
      final userProfile =
      UserProfile.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      nameController.text = userProfile.name;
      bioController.text = userProfile.bio;
      phoneController.text = userProfile.phone;
      _existingImageUrl = userProfile.imageUrl;

      setState(() {}); // Refresh UI with loaded values
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (uid == null) return;

    String imageUrl = _existingImageUrl ?? '';
    if (_imageFile != null) {
      final ref =
      FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    final updatedProfile = UserProfile(
      name: nameController.text.trim(),
      bio: bioController.text.trim(),
      phone: phoneController.text.trim(),
      imageUrl: imageUrl,
      followers: 0, // Optional: Retain original if needed
      following: 0,
    );

    await FirebaseDatabase.instance
        .ref()
        .child('users/$uid')
        .set(updatedProfile.toJson());

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: 150,
                color: Colors.grey[300],
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : _existingImageUrl != null
                    ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 60),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Enter name"),
            ),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(hintText: "Enter bio"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(hintText: "Enter phone number"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
