/// Role of a chat message.
enum AIMessageRole { system, user, assistant }

/// A single message in a chat conversation.
class AIMessage {
  final AIMessageRole role;
  final String content;

  /// Optional base64-encoded image (PNG/JPEG) for vision models.
  final String? imageBase64;

  const AIMessage({
    required this.role,
    required this.content,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        if (imageBase64 != null) 'image_base64': imageBase64,
      };

  AIMessage copyWith({
    AIMessageRole? role,
    String? content,
    String? imageBase64,
  }) =>
      AIMessage(
        role: role ?? this.role,
        content: content ?? this.content,
        imageBase64: imageBase64 ?? this.imageBase64,
      );
}
