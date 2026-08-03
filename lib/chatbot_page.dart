import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'cart.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<dynamic> products;
  ChatMessage({required this.text, required this.isUser, required this.time, this.products = const []});
}

class ChatSession {
  final int sessionId;
  final String preview;
  final String time;
  ChatSession({required this.sessionId, required this.preview, required this.time});
}

class ChatbotPage extends StatefulWidget {
  final String? initialMessage;
  const ChatbotPage({super.key, this.initialMessage});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  static const String _baseUrl = 'http://localhost:5000';

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  bool _isLoading = false;
  String _userEmail = '';
  int _currentSession = 1;
  bool _viewingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndHistory().then((_) {
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        _messageController.text = widget.initialMessage!;
        _sendMessage();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('user_email') ?? '';
    if (_userEmail.isNotEmpty) {
      await _loadHistory();
    } else {
      setState(() {
        _messages.add(ChatMessage(
          text: "Hello! 🌿 I'm HomeHarvest AI Assistant. Ask me anything about plants, diseases, or care tips!",
          isUser: false,
          time: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/chat-history?email=$_userEmail'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final data = jsonDecode(response.body);
      final history = data['history'] as List? ?? [];
      final sessionsRaw = data['sessions'] as List? ?? [];
      setState(() {
        _currentSession = data['current_session'] ?? 1;
        _sessions = sessionsRaw
            .map((s) => ChatSession(
                  sessionId: s['session_id'],
                  preview: s['preview'] ?? 'Chat',
                  time: s['time'] ?? '',
                ))
            .toList();
        _messages.clear();
        if (history.isEmpty) {
          _messages.add(ChatMessage(
            text: "Hello! 🌿 I'm HomeHarvest AI Assistant. Ask me anything about plants!",
            isUser: false,
            time: DateTime.now(),
          ));
        } else {
          for (final h in history) {
            _messages.add(ChatMessage(
              text: h['message'],
              isUser: h['role'] == 'user',
              time: DateTime.tryParse(h['time'] ?? '') ?? DateTime.now(),
            ));
          }
        }
        _viewingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Hello! 🌿 I'm HomeHarvest AI Assistant. Ask me anything about plants!",
          isUser: false,
          time: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _loadSession(int sessionId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/chat-session?email=$_userEmail&session_id=$sessionId'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final data = jsonDecode(response.body);
      final history = data['history'] as List? ?? [];
      setState(() {
        _messages.clear();
        _viewingHistory = sessionId != _currentSession;
        for (final h in history) {
          _messages.add(ChatMessage(
            text: h['message'],
            isUser: h['role'] == 'user',
            time: DateTime.tryParse(h['time'] ?? '') ?? DateTime.now(),
          ));
        }
      });
      Navigator.pop(context); // close drawer
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _deleteSession(int sessionId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/delete-chat-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _userEmail, 'session_id': sessionId}),
      );
      // If deleting current session, start new chat
      if (sessionId == _currentSession) {
        await _startNewChat();
      } else {
        await _loadHistory();
      }
    } catch (_) {}
  }

  Future<void> _startNewChat() async {
    if (_userEmail.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/new-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _userEmail}),
      );
      final data = jsonDecode(response.body);
      final newSession = data['session_id'] as int;
      // Reload sessions list for drawer without changing current messages
      final histResponse = await http
          .get(Uri.parse('$_baseUrl/chat-history?email=$_userEmail'))
          .timeout(const Duration(seconds: 10));
      final histData = jsonDecode(histResponse.body);
      final sessionsRaw = histData['sessions'] as List? ?? [];
      setState(() {
        _currentSession = newSession;
        _viewingHistory = false;
        _sessions = sessionsRaw
            .map((s) => ChatSession(
                  sessionId: s['session_id'],
                  preview: s['preview'] ?? 'Chat',
                  time: s['time'] ?? '',
                ))
            .toList();
        _messages.clear();
        _messages.add(ChatMessage(
          text: "Hello! 🌿 Starting a new chat. Ask me anything about plants!",
          isUser: false,
          time: DateTime.now(),
        ));
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_viewingHistory) return;
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text, 'email': _userEmail}),
      ).timeout(const Duration(seconds: 120));

      if (!mounted) return;
      final data = jsonDecode(response.body);
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: response.statusCode == 200
              ? (data['reply'] ?? 'Sorry, I could not understand that.')
              : (data['message'] ?? 'Something went wrong.'),
          isUser: false,
          time: DateTime.now(),
          products: response.statusCode == 200 ? (data['products'] ?? []) : [],
        ));
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(
            text: 'Cannot connect to server. Make sure Flask is running.\n\nError: ${e.toString()}',
            isUser: false,
            time: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildHistoryDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5233),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF4A7C4A),
              child: Icon(Icons.eco, color: Colors.white, size: 20),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HomeHarvest Assistant',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Plant Expert AI', style: TextStyle(color: Color(0xFFa7f3d0), fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          // New Chat button
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            tooltip: 'New Chat',
            onPressed: _startNewChat,
          ),
          // History button
          if (_userEmail.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              tooltip: 'Chat History',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Viewing history banner
          if (_viewingHistory)
            Container(
              color: const Color(0xFFFFF3CD),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF856404), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Viewing past chat history',
                        style: TextStyle(color: Color(0xFF856404), fontSize: 13)),
                  ),
                  GestureDetector(
                    onTap: _loadHistory,
                    child: const Text('Go to current',
                        style: TextStyle(color: Color(0xFF2D5233), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),

          // Quick suggestion chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('🌿 Plant care tips'),
                  _buildChip('🐛 Pest control'),
                  _buildChip('💧 Watering guide'),
                  _buildChip('🌱 Best fertilizer'),
                  _buildChip('🍂 Seasonal plants'),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) return _buildTypingIndicator();
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _viewingHistory ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isLoading && !_viewingHistory,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _viewingHistory ? 'Start a new chat to send messages...' : 'Ask about plants...',
                        hintStyle: const TextStyle(color: Color(0xFFB5BAC1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _viewingHistory ? null : _sendMessage,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: (_isLoading || _viewingHistory)
                          ? const Color(0xFF4A7C4A).withOpacity(0.4)
                          : const Color(0xFF2D5233),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            color: const Color(0xFF2D5233),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chat History',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_userEmail, style: const TextStyle(color: Color(0xFFa7f3d0), fontSize: 12)),
              ],
            ),
          ),
          // New Chat button inside drawer
          ListTile(
            leading: const Icon(Icons.add_comment_outlined, color: Color(0xFF2D5233)),
            title: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5233))),
            onTap: () {
              Navigator.pop(context);
              _startNewChat();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _sessions.isEmpty
                ? const Center(
                    child: Text('No chat history yet', style: TextStyle(color: Color(0xFF9CA3AF))),
                  )
                : ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[_sessions.length - 1 - index];
                      final isCurrent = session.sessionId == _currentSession;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isCurrent
                              ? const Color(0xFF2D5233)
                              : const Color(0xFFE8F5E8),
                          child: Icon(Icons.chat_bubble_outline,
                              size: 16,
                              color: isCurrent ? Colors.white : const Color(0xFF4A7C4A)),
                        ),
                        title: Text(
                          session.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          isCurrent ? 'Current chat' : session.time.substring(0, 16),
                          style: TextStyle(
                            fontSize: 11,
                            color: isCurrent ? const Color(0xFF2D5233) : const Color(0xFF9CA3AF),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Delete this chat',
                          onPressed: () async {
                            Navigator.pop(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Chat'),
                                content: const Text('Delete this chat session?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) _deleteSession(session.sessionId);
                          },
                        ),
                        onTap: () => _loadSession(session.sessionId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return GestureDetector(
      onTap: () {
        if (_viewingHistory) return;
        _messageController.text = label.substring(2).trim();
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4A7C4A)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF2D5233), fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF2D5233),
                child: Icon(Icons.eco, color: Colors.white, size: 16)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.isUser ? const Color(0xFF2D5233) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                        bottomRight: Radius.circular(message.isUser ? 4 : 18),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                    ),
                    child: message.isUser
                        ? SelectableText(
                            message.text,
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                          )
                        : MarkdownBody(
                            data: message.text,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 14, color: Color(0xFF1A2E1A), height: 1.5),
                              strong: const TextStyle(fontSize: 14, color: Color(0xFF1A2E1A), fontWeight: FontWeight.bold),
                              listBullet: const TextStyle(fontSize: 14, color: Color(0xFF1A2E1A)),
                              h1: const TextStyle(fontSize: 16, color: Color(0xFF1A2E1A), fontWeight: FontWeight.bold),
                              h2: const TextStyle(fontSize: 15, color: Color(0xFF1A2E1A), fontWeight: FontWeight.bold),
                              h3: const TextStyle(fontSize: 14, color: Color(0xFF1A2E1A), fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                ),
                if (!message.isUser && message.products.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: message.products.length,
                      itemBuilder: (context, i) => _buildProductCard(message.products[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final name     = product['name'] ?? '';
    final price    = product['price'] ?? 0.0;
    final imageUrl = product['image_url'] ?? '';
    final category = product['category'] ?? 'Medicine';
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.network(
              imageUrl,
              height: 90, width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 90,
                color: const Color(0xFFE8F5E8),
                child: const Icon(Icons.eco, color: Color(0xFF4A7C4A), size: 36),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Rs.${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Color(0xFF2D5233), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () {
                      CartStorage().addItem(name, price.toDouble(), imageUrl, category);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name added to cart!'),
                          backgroundColor: const Color(0xFF2D5233),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5233),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 13),
                        SizedBox(width: 4),
                        Text('Add to Cart', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2D5233),
              child: Icon(Icons.eco, color: Colors.white, size: 16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _buildDot(0), const SizedBox(width: 4),
              _buildDot(1), const SizedBox(width: 4),
              _buildDot(2),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFF9CA3AF), const Color(0xFF2D5233), value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
