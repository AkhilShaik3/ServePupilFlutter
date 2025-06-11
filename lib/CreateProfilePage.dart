import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../user_profile.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final phoneController = TextEditingController();
  File? _imageFile;

  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> uploadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _imageFile == null) return;

    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    await ref.putFile(_imageFile!);
    final imageUrl = await ref.getDownloadURL();

    final profile = UserProfile(
      name: nameController.text.trim(),
      bio: bioController.text.trim(),
      phone: phoneController.text.trim(),
      imageUrl: imageUrl,
      followers: 0,
      following: 0,
    );

    await FirebaseDatabase.instance.ref().child('users/$uid').set(profile.toJson());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile created successfully!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150,
                width: 150,
                color: Colors.grey[300],
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
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
              onPressed: uploadProfile,
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}