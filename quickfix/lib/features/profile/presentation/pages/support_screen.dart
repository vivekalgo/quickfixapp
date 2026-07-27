import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/auth/presentation/controllers/auth_providers.dart';
import 'package:quickfix/features/profile/data/helpdesk_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String senderName;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.senderName = '',
    required this.time,
  });
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final HelpdeskService _helpdeskService = HelpdeskService();
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String? _activeTicketId;
  String _activeTicketStatus = 'open';
  Timer? _pollTimer;

  final List<String> _presets = [
    'I want a refund',
    'My provider is delayed',
    'Cancel appointment',
    'Talk to Human Agent',
    'Emergency Issue',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialGreetingAndTickets();
    _startMessagePolling();
  }

  void _startMessagePolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_activeTicketId != null && mounted) {
        _syncTicketMessages(_activeTicketId!, silent: true);
      }
    });
  }

  Future<void> _loadInitialGreetingAndTickets() async {
    final user = ref.read(authProvider).user;
    final displayName =
        user != null && user['name'] != null && (user['name'] as String).isNotEmpty
            ? (user['name'] as String).split(' ')[0]
            : 'Valued Customer';

    try {
      final tickets = await _helpdeskService.fetchUserTickets();
      if (tickets.isNotEmpty) {
        final latest = tickets.first as Map<String, dynamic>;
        final ticketId = latest['id'] ?? latest['ticketId'];
        if (ticketId != null && ticketId.toString().isNotEmpty) {
          await _syncTicketMessages(ticketId.toString());
        }
      }
    } catch (_) {}

    if (_messages.isEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Hello $displayName! Welcome to QuickFix 24/7 AI Customer Support. How can I assist you with your bookings, payments, or services today?',
            isUser: false,
            senderName: 'QuickFix AI Support',
            time: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _syncTicketMessages(String ticketId, {bool silent = false}) async {
    try {
      final ticket = await _helpdeskService.fetchTicketDetail(ticketId);
      if (ticket != null && mounted) {
        final conversation = ticket['fullConversation'] as List<dynamic>?;
        final status = ticket['status']?.toString() ?? 'open';

        setState(() {
          _activeTicketId = ticket['id'] ?? ticket['ticketId'] ?? ticketId;
          _activeTicketStatus = status;
        });

        if (conversation != null && conversation.isNotEmpty) {
          final loadedMessages = <ChatMessage>[];
          for (var m in conversation) {
            if (m is Map<String, dynamic>) {
              final sender = m['sender']?.toString() ?? 'user';
              final isUserMsg = (sender == 'user' || sender == 'customer');
              final text = m['text']?.toString() ?? '';
              final senderName = m['senderName']?.toString() ??
                  (isUserMsg
                      ? 'You'
                      : (sender == 'admin'
                          ? 'Support Admin'
                          : 'QuickFix AI Support'));
              final timeStr = m['timestamp']?.toString();
              final timeVal = timeStr != null
                  ? (DateTime.tryParse(timeStr) ?? DateTime.now())
                  : DateTime.now();

              if (text.isNotEmpty) {
                loadedMessages.add(
                  ChatMessage(
                    text: text,
                    isUser: isUserMsg,
                    senderName: senderName,
                    time: timeVal,
                  ),
                );
              }
            }
          }

          if (loadedMessages.isNotEmpty) {
            final prevCount = _messages.length;
            setState(() {
              _messages.clear();
              _messages.addAll(loadedMessages);
            });
            if (!silent || _messages.length > prevCount) {
              _scrollToBottom();
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    AppHaptics.lightTap();

    final userText = text.trim();
    setState(() {
      _messages.add(
        ChatMessage(
          text: userText,
          isUser: true,
          senderName: 'You',
          time: DateTime.now(),
        ),
      );
      _messageController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    // Call Backend Helpdesk AI Agent
    try {
      final res = await _helpdeskService.sendChatMessage(
        message: userText,
        ticketId: _activeTicketId,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          final replyObj = res['reply'] as Map<String, dynamic>?;
          final aiText = replyObj?['text'] ?? res['aiResult']?['answerText'] ?? 'Thank you. A support manager has been notified.';
          
          _messages.add(
            ChatMessage(
              text: aiText,
              isUser: false,
              senderName: replyObj?['senderName'] ?? 'QuickFix AI Support',
              time: DateTime.now(),
            ),
          );

          if (res['ticket'] != null) {
            final t = res['ticket'] as Map<String, dynamic>;
            _activeTicketId = t['id'] ?? t['ticketId'];
            _activeTicketStatus = t['status'] ?? 'open';
          }
        });
        if (_activeTicketId != null) {
          await _syncTicketMessages(_activeTicketId!, silent: true);
        }
        AppHaptics.successNotification();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text: 'I have logged your request. A QuickFix support representative will update your ticket shortly.',
              isUser: false,
              senderName: 'QuickFix AI Support',
              time: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white,
                child: Icon(Icons.support_agent_rounded, size: 22, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QuickFix AI Support Desk',
                  style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14.5),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _activeTicketId != null
                          ? 'Ticket #$_activeTicketId (${_activeTicketStatus.toUpperCase()})'
                          : 'AI Assistant Active • 24×7',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
          // Active Ticket Status Banner
          if (_activeTicketId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark
                  ? AppColors.primaryAccent.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 16,
                    color: isDark ? AppColors.primaryAccent : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Support Ticket #$_activeTicketId is currently ${_activeTicketStatus.toUpperCase().replaceAll('_', ' ')}.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                          ? AppColors.primaryAccent
                          : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
                        bottomRight: Radius.circular(msg.isUser ? 0 : 16),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!msg.isUser && msg.senderName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              msg.senderName,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.primaryAccent : AppColors.primary,
                              ),
                            ),
                          ),
                        Text(
                          msg.text,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            height: 1.35,
                            color: msg.isUser
                                ? Colors.white
                                : (isDark ? Colors.white : AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.1, end: 0, duration: 200.ms);
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
                    Text(
                      'AI Assistant is thinking',
                      style: AppTextStyles.bodySmall(isDark),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.more_horiz,
                      size: 16,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ],
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(),
              ),
            ),

          // 2. Preset Quick selection pills
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.primaryAccent.withValues(alpha: 0.4)
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      preset,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 3. Bottom text input panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
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
                      onSubmitted: (val) => _sendMessage(val),
                      decoration: InputDecoration(
                        hintText: 'Ask QuickFix AI or describe issue...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: GoogleFonts.inter(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 13,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primaryAccent,
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
