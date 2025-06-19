import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationPicker extends StatefulWidget {
  final Function(String place, double lat, double lng) onLocationSelected;
  final String? initialPlace;
  final double? initialLat;
  final double? initialLng;

  const LocationPicker({
    Key? key,
    required this.onLocationSelected,
    this.initialPlace,
    this.initialLat,
    this.initialLng,
  }) : super(key: key);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  LatLng _mapCenter = LatLng(45.5019, -73.5674); // Montreal
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedPlace;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _mapCenter = LatLng(widget.initialLat!, widget.initialLng!);
      _selectedLat = widget.initialLat;
      _selectedLng = widget.initialLng;
      _selectedPlace = widget.initialPlace;
      _searchController.text = widget.initialPlace ?? '';
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=ca');
    final response = await http.get(url, headers: {
      'User-Agent': 'ServePupilFlutter/1.0 (akhilshaik991@gmail.com)'
    });
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        _searchResults = data.map<Map<String, dynamic>>((item) => item as Map<String, dynamic>).toList();
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _selectPlace(Map<String, dynamic> place) {
    final lat = double.tryParse(place['lat'] ?? '') ?? 0.0;
    final lon = double.tryParse(place['lon'] ?? '') ?? 0.0;
    final displayName = place['display_name'] ?? '';
    setState(() {
      _mapCenter = LatLng(lat, lon);
      _selectedLat = lat;
      _selectedLng = lon;
      _selectedPlace = displayName;
      _searchController.text = displayName;
      _searchResults = [];
    });
    widget.onLocationSelected(displayName, lat, lon);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search place',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            _searchPlace(val);
          },
        ),
        if (_searchResults.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
            ),
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  title: Text(place['display_name'] ?? ''),
                  onTap: () => _selectPlace(place),
                );
              },
            ),
          ),
        SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: FlutterMap(
            options: MapOptions(
              center: _mapCenter,
              zoom: 13.0,
              onTap: (tapPosition, latlng) {
                setState(() {
                  _mapCenter = latlng;
                  _selectedLat = latlng.latitude;
                  _selectedLng = latlng.longitude;
                  _selectedPlace = null;
                });
                widget.onLocationSelected('', latlng.latitude, latlng.longitude);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.servepupil',
              ),
              if (_selectedLat != null && _selectedLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_selectedLat!, _selectedLng!),
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}