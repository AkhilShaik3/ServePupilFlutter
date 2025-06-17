class RequestModel {
  final String id;
  final String description;
  final String requestType;
  final String place;
  final double latitude;
  final double longitude;
  final double timestamp;
  final String? imageUrl;

  RequestModel({
    required this.id,
    required this.description,
    required this.requestType,
    required this.place,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.imageUrl,
  });

  factory RequestModel.fromMap(String id, Map<dynamic, dynamic> data) {
    return RequestModel(
      id: id,
      description: data['description'] ?? '',
      requestType: data['requestType'] ?? '',
      place: data['place'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'requestType': requestType,
      'place': place,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
