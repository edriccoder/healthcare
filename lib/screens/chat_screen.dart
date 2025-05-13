import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/doctor.dart';
import '../models/message.dart';
import '../utils/database_helper.dart';

class ChatScreen extends StatefulWidget {
  final User user;
  final Doctor doctor;
  final bool isDoctor; // Add flag to indicate if the sender is a doctor

  const ChatScreen({
    super.key,
    required this.user,
    required this.doctor,
    this.isDoctor = false, // Default is patient view
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      _messages = await DatabaseHelper().getMessages(
        widget.user.id!,
        widget.doctor.id!,
      );
      setState(() => _isLoading = false);

      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final message = Message(
      // If doctor is sending, senderId should be doctor ID, otherwise user ID
      senderId: widget.isDoctor ? widget.doctor.id! : widget.user.id!,
      // If doctor is sending, receiverId should be user ID, otherwise doctor ID
      receiverId: widget.isDoctor ? widget.user.id! : widget.doctor.id!,
      message: text,
      timestamp: DateTime.now().toIso8601String(),
    );

    // Add message to UI immediately for better UX
    setState(() {
      _messages.add(message);
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      await DatabaseHelper().insertMessage(message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set the app bar title based on the current view
    final String appBarTitle = widget.isDoctor
        ? widget.user.name // Doctor sees patient name
        : widget.doctor.name; // Patient sees doctor name

    final String appBarSubtitle = widget.isDoctor
        ? "Patient" // Doctor sees patient role
        : widget.doctor.specialty; // Patient sees doctor specialty

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                widget.isDoctor
                    ? widget.user.name
                        .substring(0, 1) // First letter of patient name
                    : widget.doctor.name
                        .substring(0, 1), // First letter of doctor name
                style: const TextStyle(color: Colors.deepPurple),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appBarTitle,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  appBarSubtitle,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Send a message to start the conversation',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            // Check if this message was sent by current user
                            // If doctor view: check if senderId is doctor's ID
                            // If patient view: check if senderId is user's ID
                            final isMe = widget.isDoctor
                                ? message.senderId == widget.doctor.id
                                : message.senderId == widget.user.id;

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.deepPurple
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.message,
                                      style: TextStyle(
                                        color:
                                            isMe ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('h:mm a').format(
                                        DateTime.parse(message.timestamp),
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
