class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.imageUrl,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final String? imageUrl;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String? ?? '',
      sentAt: DateTime.parse(json['sentAt'] as String),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class ConversationPreview {
  const ConversationPreview({
    required this.id,
    required this.otherUserId,
    required this.otherUser,
    required this.lastMessage,
    required this.updatedAt,
  });

  final String id;
  final String otherUserId;
  final String otherUser;
  final String lastMessage;
  final DateTime updatedAt;

  factory ConversationPreview.fromJson(Map<String, dynamic> json) {
    return ConversationPreview(
      id: json['id'] as String,
      otherUserId: json['otherUserId'] as String,
      otherUser: json['otherUser'] as String,
      lastMessage: json['lastMessage'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
