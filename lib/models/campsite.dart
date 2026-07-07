class Campsite {
  const Campsite({
    required this.id,
    required this.name,
    required this.region,
    required this.description,
    required this.rating,
    this.amenities = const [],
  });

  final String id;
  final String name;
  final String region;
  final String description;
  final double rating;
  final List<String> amenities;

  factory Campsite.fromJson(Map<String, dynamic> json) {
    return Campsite(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      region: json['region'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

class CamperUpdate {
  const CamperUpdate({
    required this.id,
    required this.userId,
    required this.userName,
    required this.displayName,
    required this.updateType,
    required this.text,
    this.imageUrl,
    this.timestamp,
  });

  final String id;
  final String userId;
  final String userName;
  final String displayName;
  final String updateType;
  final String text;
  final String? imageUrl;
  final DateTime? timestamp;

  factory CamperUpdate.fromJson(Map<String, dynamic> json) {
    return CamperUpdate(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      updateType: json['updateType'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}
