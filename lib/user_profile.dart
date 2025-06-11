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
    'followers': followers,
    'following': following,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'],
    bio: json['bio'],
    phone: json['phone'],
    imageUrl: json['imageUrl'],
    followers: json['followers'],
    following: json['following'],
  );
}