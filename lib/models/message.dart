class Message {
  int? id;
  int senderId;
  int receiverId;
  String message;
  String timestamp;
  bool isRead;

  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead ? 1 : 0,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      message: map['message'],
      timestamp: map['timestamp'],
      isRead: map['isRead'] == 1,
    );
  }
}
