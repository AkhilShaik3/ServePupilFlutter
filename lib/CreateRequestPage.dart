import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:servepupil/request_model.dart';

class CreateRequestPage extends StatefulWidget {
  @override
  _CreateRequestPageState createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();

  String description = '';
  String requestType = 'Help'; // fixed value
  String place = '';
  File? _pickedImage;
  String? imageUrl;

  bool loading = false;

  final dbRef = FirebaseDatabase.instance.ref();
  final ImagePicker _picker = ImagePicker();

  Future<bool> checkUserExists(String uid) async {
    final snapshot = await dbRef.child('users').child(uid).once();
    return snapshot.snapshot.value != null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('request_images')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  Future<void> createRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    bool exists = await checkUserExists(user.uid);
    if (!exists) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User record not found')),
      );
      return;
    }

    // Upload image & get URL
    final uploadedImageUrl = await _uploadImage(_pickedImage!, user.uid);
    if (uploadedImageUrl == null) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image')),
      );
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toDouble();

    final newRequest = RequestModel(
      id: '',
      description: description,
      requestType: requestType,
      place: place,
      latitude: 0.0,
      longitude: 0.0,
      timestamp: timestamp,
      imageUrl: uploadedImageUrl,
    );

    DatabaseReference newRequestRef = dbRef.child('requests').child(user.uid).push();

    await newRequestRef.set(newRequest.toMap());

    setState(() {
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request created successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Request')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Upload Image', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: _pickedImage == null
                      ? Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                  )
                      : Image.file(_pickedImage!, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Enter description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (val) => description = val,
                validator: (val) =>
                val == null || val.isEmpty ? 'Please enter a description' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Enter place',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => place = val,
                validator: (val) =>
                val == null || val.isEmpty ? 'Please enter a place' : null,
              ),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    createRequest();
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
