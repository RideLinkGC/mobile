import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/convex_functions.dart';

class ChatConversation {
  final String id;
  final String tripId;
  final String bookingId;
  final List<String> participants;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageAt;

  // Display helpers
  final String displayName;

  const ChatConversation({
    required this.id,
    this.tripId = '',
    this.bookingId = '',
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.displayName = '',
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      participants: (json['participants'] as List?)?.cast<String>() ?? [],
      lastMessage: json['lastMessage'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastMessageAt'] as int)
          : null,
      displayName: json['displayName'] as String? ??
          json['name'] as String? ??
          '',
    );
  }

  String get timeAgo {
    if (lastMessageAt == null) return '';
    final diff = DateTime.now().difference(lastMessageAt!);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays}d ago';
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isSent;
  final DateTime? sentAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isSent,
    this.sentAt,
  });

  factory ChatMessage.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      isSent: (json['senderId'] as String?) == currentUserId,
      sentAt: json['_creationTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['_creationTime'] as int)
          : null,
    );
  }

  String get time {
    if (sentAt == null) return '';
    final h = sentAt!.hour.toString().padLeft(2, '0');
    final m = sentAt!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class ChatProvider extends ChangeNotifier {
  final ConvexClient? _convex;
  final String _currentUserId;

  SubscriptionHandle? _conversationsSubscription;
  SubscriptionHandle? _messagesSubscription;

  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];
  bool _loadingConversations = false;
  bool _loadingMessages = false;
  String? _error;
  String? _activeConversationId;

  List<ChatConversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  bool get loadingConversations => _loadingConversations;
  bool get loadingMessages => _loadingMessages;
  String? get error => _error;

  static final _mockConversations = [
    const ChatConversation(
      id: 'conv1',
      displayName: 'Abebe Kebede',
      lastMessage: "I'm 5 minutes away",
    ),
    const ChatConversation(
      id: 'conv2',
      displayName: 'Tigist Hailu',
      lastMessage: 'Thanks for the ride!',
    ),
    const ChatConversation(
      id: 'conv3',
      displayName: 'Dawit Alemu',
      lastMessage: 'See you at the pickup point',
    ),
  ];

  static final _mockMessages = [
    const ChatMessage(id: 'm1', text: "Hi! I'm on my way", isSent: false),
    const ChatMessage(
        id: 'm2',
        text: "Great, I'll be at the pickup point",
        isSent: true),
    const ChatMessage(id: 'm3', text: "I'm 5 minutes away", isSent: false),
    const ChatMessage(
        id: 'm4', text: 'Perfect, see you soon!', isSent: true),
  ];

  ChatProvider(this._convex, this._currentUserId);

  Future<void> loadConversations() async {
    _loadingConversations = true;
    _error = null;
    notifyListeners();

    if (_convex == null) {
      _conversations = _mockConversations;
      _loadingConversations = false;
      notifyListeners();
      return;
    }

    try {
      _conversationsSubscription?.cancel();
      _conversationsSubscription = await _convex.subscribe(
        name: ConvexFunctions.getUserConversations,
        args: {},
        onUpdate: (value) {
          try {
            final list = jsonDecode(value) as List;
            _conversations = list
                .map((e) =>
                    ChatConversation.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (e) {
            debugPrint('Conversation parse error: $e');
            _conversations = _mockConversations;
          }
          _loadingConversations = false;
          notifyListeners();
        },
        onError: (message, value) {
          debugPrint('Conversations error: $message');
          _conversations = _mockConversations;
          _loadingConversations = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to conversations: $e');
      _conversations = _mockConversations;
      _loadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String conversationId) async {
    _activeConversationId = conversationId;
    _loadingMessages = true;
    _error = null;
    notifyListeners();

    if (_convex == null) {
      _messages = _mockMessages;
      _loadingMessages = false;
      notifyListeners();
      return;
    }

    try {
      _messagesSubscription?.cancel();
      _messagesSubscription = await _convex.subscribe(
        name: ConvexFunctions.getConversationMessages,
        args: {'conversationId': conversationId},
        onUpdate: (value) {
          try {
            final list = jsonDecode(value) as List;
            _messages = list
                .map((e) => ChatMessage.fromJson(
                    e as Map<String, dynamic>, _currentUserId))
                .toList();
          } catch (e) {
            debugPrint('Messages parse error: $e');
            _messages = _mockMessages;
          }
          _loadingMessages = false;
          notifyListeners();
        },
        onError: (message, value) {
          debugPrint('Messages error: $message');
          _messages = _mockMessages;
          _loadingMessages = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to messages: $e');
      _messages = _mockMessages;
      _loadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (_activeConversationId == null || content.trim().isEmpty) return;

    final tempMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: content,
      isSent: true,
      sentAt: DateTime.now(),
    );
    _messages = [..._messages, tempMessage];
    notifyListeners();

    try {
      await _convex?.mutation(
        name: ConvexFunctions.sendMessage,
        args: {
          'conversationId': _activeConversationId!,
          'content': content,
        },
      );
    } catch (e) {
      debugPrint('Failed to send message: $e');
      _error = 'Failed to send message';
      notifyListeners();
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _convex?.mutation(
        name: ConvexFunctions.markMessagesAsRead,
        args: {'conversationId': conversationId},
      );
    } catch (e) {
      debugPrint('Failed to mark messages as read: $e');
    }
  }

  void disposeMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _messages = [];
    _activeConversationId = null;
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
