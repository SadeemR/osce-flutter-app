enum MessageSender {
  doctor('user'),
  parent('assistant'),
  system('system');

  const MessageSender(this.raw);
  final String raw;
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
