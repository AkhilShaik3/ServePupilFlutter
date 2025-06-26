import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:servepupil/location_picker.dart';

class EditRequestPage extends StatefulWidget {
  final String requestId;
  final String ownerUid;
  final String initialDescription;
  final String initialType;
  final String initialPlace;
  final String initialImageUrl;
  final double initialLat;
  final double initialLng;

  const EditRequestPage({
    super.key,
    required this.requestId,
    required this.ownerUid,
    required this.initialDescription,
    required this.initialType,
    required this.initialPlace,
    required this.initialImageUrl,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<EditRequestPage> createState() => _EditRequestPageState();
}

class _EditRequestPageState extends State<EditRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _typeController = TextEditingController();
  final _placeController = TextEditingController();

  File? _newImage;
  bool loading = false;

  double latitude = 0.0;
  double longitude = 0.0;

  @override
  void initState() {
    super.initState();
    _descController.text = widget.initialDescription;
    _typeController.text = widget.initialType;
    _placeController.text = widget.initialPlace;
    latitude = widget.initialLat;
    longitude = widget.initialLng;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImage = File(picked.path);
      });
    }
  }

  Future<void> _updateRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    String? newImageUrl = widget.initialImageUrl;

    if (_newImage != null) {
      try {
        if (widget.initialImageUrl.isNotEmpty) {
          final oldRef = FirebaseStorage.instance.refFromURL(widget.initialImageUrl);
          await oldRef.delete();
        }
        final storageRef = FirebaseStorage.instance
            .ref('requests/${widget.ownerUid}/${widget.requestId}/image.jpg');
        await storageRef.putFile(_newImage!);
        newImageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        print('Image upload error: $e');
      }
    }

    final ref = FirebaseDatabase.instance
        .ref('requests/${widget.ownerUid}/${widget.requestId}');

    await ref.update({
      'description': _descController.text,
      'requestType': _typeController.text,
      'place': _placeController.text,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': newImageUrl,
    });

    setState(() => loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Request")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _newImage != null
                    ? Image.file(_newImage!, height: 150)
                    : widget.initialImageUrl.isNotEmpty
                    ? Image.network(widget.initialImageUrl, height: 150)
                    : Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.camera_alt)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) =>
                value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: "Request Type"),
                validator: (value) =>
                value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              LocationPicker(
                onLocationSelected: (selectedPlace, lat, lng) {
                  setState(() {
                    _placeController.text = selectedPlace;
                    latitude = lat;
                    longitude = lng;
                  });
                },
                initialPlace: _placeController.text,
                initialLat: latitude,
                initialLng: longitude,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateRequest,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text("Update Request"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
