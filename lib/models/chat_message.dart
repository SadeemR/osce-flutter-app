enum MessageSender {
  doctor('user', 'doctor'),
  parent('assistant', 'patient'),
  system('system', 'system');

  const MessageSender(this.raw, this.displayName);
  final String raw;
  final String displayName;
}

class ChatMessage {
  final String id;
  final MessageSender sender;
  String text;
  final DateTime timestamp;
  bool isLoading;

  ChatMessage({
    String? id,
    required this.sender,
    required this.text,
    DateTime? timestamp,
    this.isLoading = false,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  String toApi() => text;
}
