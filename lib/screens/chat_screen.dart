import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/media_service.dart';
import '../services/van_dwellers_api.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherUserId});

  final String otherUserId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  UserProfile? _otherUser;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final me = await VanDwellersApi.instance.getMe();
      final other = await VanDwellersApi.instance.getUserById(widget.otherUserId);
      final messages = await VanDwellersApi.instance.getMessages(widget.otherUserId);
      if (mounted) {
        setState(() {
          _currentUserId = me.id;
          _otherUser = other;
          _messages = messages;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await VanDwellersApi.instance.sendMessage(otherUserId: widget.otherUserId, text: text);
    await _load();
  }

  Future<void> _sendPhoto() async {
    final file = await MediaService.instance.pickPhoto(source: ImageSource.gallery);
    if (file == null) return;
    await VanDwellersApi.instance.sendPhotoMessage(otherUserId: widget.otherUserId, file: file);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final title = _otherUser?.displayName.isNotEmpty == true
        ? _otherUser!.displayName
        : _otherUser?.username ?? 'Chat';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
                      final isMe = msg.senderId == _currentUserId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _MessageBody(message: msg),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  IconButton(onPressed: _sendPhoto, icon: const Icon(Icons.photo)),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(hintText: 'Message…'),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  IconButton(onPressed: _sendText, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.imageUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(message.imageUrl!, width: 200, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image)),
          ),
          if (message.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(message.text),
          ],
        ],
      );
    }
    return Text(message.text);
  }
}
