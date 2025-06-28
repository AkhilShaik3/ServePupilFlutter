class UserProfile {
  final String name;
  final String bio;
  final String phone;
  final String imageUrl;
  final int followers;
  final int following;

  UserProfile({
    required this.name,
    required this.bio,
    required this.phone,
    required this.imageUrl,
    required this.followers,
    required this.following,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'bio': bio,
    'phone': phone,
    'imageUrl': imageUrl,
    // Save followers and following as empty maps (or update logic as needed)
    'followers': {},
    'following': {},
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? '',
    bio: json['bio'] ?? '',
    phone: json['phone'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    followers: json['followers'] is Map
        ? (json['followers'] as Map).length
        : (json['followers'] ?? 0),
    following: json['following'] is Map
        ? (json['following'] as Map).length
        : (json['following'] ?? 0),
  );
}
