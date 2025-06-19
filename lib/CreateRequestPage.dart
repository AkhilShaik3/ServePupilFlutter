import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servepupil/location_picker.dart';

class CreateRequestPage extends StatefulWidget {
  @override
  _CreateRequestPageState createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  String description = '';
  String requestType = 'Help';
  String place = '';
  double latitude = 45.5019; // Montreal default
  double longitude = -73.5674;
  File? _pickedImage;
  bool loading = false;

  final dbRef = FirebaseDatabase.instance.ref();
  final ImagePicker _picker = ImagePicker();

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
          .child('request_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  Future<bool> _checkUserExists(String uid) async {
    final snapshot = await dbRef.child('users').child(uid).once();
    return snapshot.snapshot.exists;
  }

  Future<void> createRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    // Check user profile existence in /users
    final exists = await _checkUserExists(user.uid);
    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete your profile before creating a request.')),
      );
      return;
    }

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() => loading = true);

    final uploadedImageUrl = await _uploadImage(_pickedImage!, user.uid);
    if (uploadedImageUrl == null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image')),
      );
      return;
    }

    final requestRef = dbRef.child('requests').child(user.uid).push();
    final requestId = requestRef.key!;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toDouble();

    final requestData = {
      "description": description,
      "requestType": requestType,
      "place": place,
      "latitude": latitude,
      "longitude": longitude,
      "timestamp": timestamp,
      "imageUrl": uploadedImageUrl,
      "requestId": requestId,
      "ownerUid": user.uid,
      "likes": 0,
      "likedBy": {},
      "comments": {}
    };

    await requestRef.set(requestData);

    setState(() => loading = false);
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
                      ? Center(child: Icon(Icons.image, size: 50, color: Colors.grey[700]))
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
                validator: (val) => val == null || val.isEmpty ? 'Please enter a description' : null,
              ),
              SizedBox(height: 16),
              LocationPicker(
                onLocationSelected: (selectedPlace, lat, lng) {
                  setState(() {
                    place = selectedPlace;
                    latitude = lat;
                    longitude = lng;
                  });
                },
                initialPlace: place.isNotEmpty ? place : 'Montreal, QC, Canada',
                initialLat: latitude,
                initialLng: longitude,
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
