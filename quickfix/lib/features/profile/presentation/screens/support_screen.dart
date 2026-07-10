import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _presets = [
    'I want a refund',
    'My provider is delayed',
    'Cancel appointment',
  ];

  @override
  void initState() {
    super.initState();
    // Default welcoming bot message
    final user = ref.read(authProvider).user;
    final displayName = user != null && user['name'] != null && (user['name'] as String).isNotEmpty
        ? (user['name'] as String).split(' ')[0]
        : 'User';
    _messages.add(
      ChatMessage(
        text: 'Hello $displayName! Welcome to QuickFix Support desk. How can I help you today?',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    AppHaptics.lightTap();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _messageController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    // Trigger simulated reply
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text: _getBotResponse(text),
              isUser: false,
              time: DateTime.now(),
            ),
          );
        });
        AppHaptics.successNotification();
        _scrollToBottom();
      }
    });
  }

  String _getBotResponse(String userText) {
    final query = userText.toLowerCase();
    if (query.contains('refund')) {
      return 'I have initiated a query for booking #QF-8947265. The refund of ₹548 will be credited to your QuickFix Wallet within 24 hours of confirmation.';
    } else if (query.contains('delay')) {
      return 'Apologies for the delay! I have reached out to Rohan Sharma. He is currently on the bike, 0.6 km away, and will reach your location in 6 minutes.';
    } else if (query.contains('cancel')) {
      return 'To cancel your active booking, please visit the Booking History page, select your current booking and click "Cancel Booking". Let me know if you need help.';
    }
    return 'Thank you for reaching out. A customer support manager has been assigned to your ticket and will join this chat in a few moments.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support Helpdesk', style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 15)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Online (Instant Reply)', style: TextStyle(fontSize: 10, color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(currentNavIndexProvider.notifier).state = 0;
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // 1. Message Bubble list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg.isUser 
                          ? AppColors.primary 
                          : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
                        bottomRight: Radius.circular(msg.isUser ? 0 : 16),
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: msg.isUser 
                            ? Colors.white 
                            : (isDark ? Colors.white : AppColors.secondary),
                      ),
                    ),
                  ),
                ).animate().slideY(begin: 0.1, end: 0, duration: 250.ms);
              },
            ),
          ),

          // Typing status animation
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text('Assistant is typing', style: AppTextStyles.bodySmall(isDark)),
                    const SizedBox(width: 4),
                    const Icon(Icons.more_horiz, size: 16, color: AppColors.textSecondaryLight),
                  ],
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(),
              ),
            ),

          // 2. Preset Quick selection pills
          if (_messages.length == 1)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final preset = _presets[index];
                  return GestureDetector(
                    onTap: () => _sendMessage(preset),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Text(
                        preset,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),

          // 3. Bottom text input panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type support message here...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                      ),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(_messageController.text),
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
