class Comment {
  final String uid;
  final String text;
  final int timestamp;

  Comment({required this.uid, required this.text, required this.timestamp});

  factory Comment.fromMap(Map<dynamic, dynamic> data) {
    return Comment(
      uid: data['uid'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

class RequestModel {
  final String id;
  final String description;
  final String requestType;
  final String place;
  final double latitude;
  final double longitude;
  final double timestamp;
  final String? imageUrl;
  final String ownerUid;
  final int likes;
  final List<String> likedBy;
  final List<Comment> comments;

  RequestModel({
    required this.id,
    required this.description,
    required this.requestType,
    required this.place,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.imageUrl,
    required this.ownerUid,
    required this.likes,
    required this.likedBy,
    required this.comments,
  });

  factory RequestModel.fromMap(String id, String ownerUid, Map<dynamic, dynamic> data) {
    final likedByList = List<String>.from(data['likedBy'] ?? []);
    final commentsMap = Map<String, dynamic>.from(data['comments'] ?? {});
    final commentList = commentsMap.values
        .map((e) => Comment.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return RequestModel(
      id: id,
      description: data['description'] ?? '',
      requestType: data['requestType'] ?? '',
      place: data['place'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      ownerUid: ownerUid,
      likes: data['likes'] ?? 0,
      likedBy: likedByList,
      comments: commentList,
    );
  }
}
