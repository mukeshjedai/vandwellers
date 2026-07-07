class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.vanType,
    required this.homeBase,
    this.photoUrls = const [],
    this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String vanType;
  final String homeBase;
  final List<String> photoUrls;
  final DateTime? createdAt;

  bool get hasProfile =>
      displayName.isNotEmpty && bio.isNotEmpty && vanType.isNotEmpty;

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? vanType,
    String? homeBase,
    List<String>? photoUrls,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      vanType: vanType ?? this.vanType,
      homeBase: homeBase ?? this.homeBase,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      vanType: json['vanType'] as String? ?? '',
      homeBase: json['homeBase'] as String? ?? '',
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final UserProfile user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
