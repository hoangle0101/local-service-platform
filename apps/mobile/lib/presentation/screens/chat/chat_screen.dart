import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/chat_datasource.dart';

/// Chat screen with WebSocket real-time messaging
class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String? otherUserName;

  const ChatScreen({
    super.key,
    required this.bookingId,
    this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatDataSource _chatDataSource = ChatDataSource();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  IO.Socket? _socket;
  String? _conversationId;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  bool _isConnected = false;
  String? _currentUserId; // Added _currentUserId

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _disconnectSocket();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    setState(() => _isLoading = true);

    try {
      // Decode user ID from token
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        // Simple JWT decode without external library dependency if possible,
        // or just use what we have. Since we don't have jwt_decoder imported in this file,
        // checking if we can add it or parse manually.
        // For robustness, let's assume we can rely on senderId comparison if we can't decode easily.
        // Wait, we need _currentUserId for that.
        // Let's parse the JWT payload manually (it's base64).
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final resp = utf8.decode(base64Url.decode(normalized));
            final payloadMap = json.decode(resp);
            _currentUserId = payloadMap['userId']?.toString();
            debugPrint('[ChatScreen] Current User ID: $_currentUserId');
          }
        } catch (e) {
          debugPrint('[ChatScreen] Error decoding token: $e');
        }
      }

      // Create or get conversation
      debugPrint(
          '[ChatScreen] Getting conversation for bookingId: ${widget.bookingId}');
      final conversation =
          await _chatDataSource.getOrCreateConversation(widget.bookingId);
      debugPrint('[ChatScreen] Conversation response: $conversation');
      _conversationId = conversation['id'];
      debugPrint('[ChatScreen] Conversation ID: $_conversationId');

      // Load initial messages
      debugPrint(
          '[ChatScreen] Loading messages for conversation: $_conversationId');
      final messages = await _chatDataSource.getMessages(_conversationId!);
      debugPrint('[ChatScreen] Loaded ${messages.length} messages');
      setState(() => _messages = messages);

      // Connect to WebSocket
      await _connectSocket();

      setState(() => _isLoading = false);
      _scrollToBottom();
    } catch (e) {
      debugPrint('[ChatScreen] Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _connectSocket() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint('[ChatScreen] No token found for socket');
      return;
    }

    debugPrint('[ChatScreen] Connecting to socket: http://10.0.2.2:3000/chat');

    _socket = IO.io(
      'http://10.0.2.2:3000/chat',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Allow polling fallback
          .setAuth({'token': token})
          // .setQuery({'token': token}) // Try query param too if auth fails
          .disableAutoConnect() // Connect manually after listeners
          .setReconnectionAttempts(5)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[ChatScreen] Socket connected: ${_socket?.id}');
      if (mounted) setState(() => _isConnected = true);

      // Join conversation room
      debugPrint('[ChatScreen] Joining conversation room: $_conversationId');
      _socket!.emit('join_conversation', {'conversationId': _conversationId});
    });

    _socket!.onConnectError((data) {
      debugPrint('[ChatScreen] Socket connect error: $data');
      if (mounted) setState(() => _isConnected = false);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[ChatScreen] Socket disconnected');
      if (mounted) setState(() => _isConnected = false);
    });

    _socket!.on('new_message', (data) {
      debugPrint('[ChatScreen] New message received: $data');
      if (mounted) {
        final senderData = data['sender'];
        final newMessage = ChatMessage(
          id: data['id']?.toString() ?? '',
          conversationId: data['conversationId']?.toString() ?? '',
          senderId: data['senderId']?.toString() ?? '',
          senderName: senderData?['profile']?['fullName'] ?? data['senderName'],
          senderAvatar:
              senderData?['profile']?['avatarUrl'] ?? data['senderAvatar'],
          body: data['body'] ?? '',
          readAt: null,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'].toString())
              : DateTime.now(),
        );

        setState(() {
          // Avoid duplicates
          if (!_messages.any((m) => m.id == newMessage.id)) {
            _messages.add(newMessage);
          }
        });
        _scrollToBottom();
      }
    });

    _socket!.onError((error) {
      debugPrint('[ChatScreen] Socket error: $error');
    });

    _socket!.on('reconnect', (_) => debugPrint('[ChatScreen] Reconnected'));
    _socket!
        .on('reconnecting', (_) => debugPrint('[ChatScreen] Reconnecting...'));

    _socket!.connect();
  }

  void _disconnectSocket() {
    if (_socket != null) {
      // Remove listeners to prevent setState calls during dispose
      _socket!.off('disconnect');
      _socket!.off('connect');
      _socket!.off('new_message');
      _socket!.off('connect_error');

      if (_conversationId != null) {
        _socket!
            .emit('leave_conversation', {'conversationId': _conversationId});
      }
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  Future<void> _sendMessage() async {
    if (_conversationId == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      if (_socket != null && _isConnected) {
        // Send via WebSocket for real-time
        _socket!.emit('send_message', {
          'conversationId': _conversationId,
          'content': text,
        });
      } else {
        // Fallback to REST API
        await _chatDataSource.sendMessage(_conversationId!, text);
        // Reload messages
        final messages = await _chatDataSource.getMessages(_conversationId!);
        setState(() => _messages = messages);
      }
      _scrollToBottom();
    } catch (e) {
      debugPrint('[ChatScreen] Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gửi tin nhắn thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.otherUserName ?? 'Nhắn tin',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              _isConnected ? 'Đang trực tuyến' : 'Đang kết nối...',
              style: TextStyle(
                color:
                    _isConnected ? AppColors.success : AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    Expanded(child: _buildMessageList()),
                    _buildMessageInput(),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Đã có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initChat,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Chưa có tin nhắn',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy gửi tin nhắn đầu tiên!',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // Determine if message is from 'me' based on ID comparison
    final isMine = _currentUserId != null
        ? message.senderId == _currentUserId
        : message.senderName != widget.otherUserName;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMine
                    ? Colors.white.withAlpha(179)
                    : AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isSending ? AppColors.textTertiary : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    if (messageDate == today) {
      return '$hour:$minute';
    } else {
      return '${time.day}/${time.month} $hour:$minute';
    }
  }
}
