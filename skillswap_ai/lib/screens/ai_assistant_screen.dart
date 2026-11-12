import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_typography.dart';
import '../providers/profile_provider.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isGeminiReady = false;

  final List<Map<String, String>> _quickPrompts = [
    {
      'title': '🪙 Time Tokens',
      'query': 'How does the Time Token economy work on SkillSwap?',
    },
    {
      'title': '🎯 4D Matching',
      'query': 'Explain how the 4-Dimensional AI Matching algorithm pairs me with peers.',
    },
    {
      'title': '📅 Plan a Curriculum',
      'query': 'Can you generate a 3-session curriculum plan to exchange skills?',
    },
    {
      'title': '📜 Blockchain Badges',
      'query': 'How do Cryptographic Proof-of-Skill Badges work?',
    },
    {
      'title': '💬 Propose a Swap',
      'query': 'Give me a friendly, persuasive template message to propose a skill swap to a peer.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initGemini();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWelcomeMessage();
    });
  }

  void _initGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty && !apiKey.startsWith('AQ.')) {
      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          systemInstruction: Content.text(
            'You are the SkillSwap AI Copilot, an expert advisor inside the SkillSwap AI peer learning platform. '
            'SkillSwap operates on a Time-as-Currency economy: 1 hour taught = 1 Time Token earned, with zero tuition fees. '
            'New users receive 3 welcome tokens. '
            'Our 4-Dimensional Matching engine evaluates Learning Style Compatibility (Visual, Kinesthetic, Auditory, Reading/Writing), '
            'Timezone Proximity, Proficiency Balance (Teacher tier >= Learner target tier), and Peer Ratings. '
            'Sessions occur via Jitsi Meet video conferencing, and completed hours mint cryptographic SHA-256 Proof-of-Skill Badges. '
            'Provide structured, enthusiastic, helpful, and concise answers tailored to skill exchangers.',
          ),
        );
        _chat = _model!.startChat();
        _isGeminiReady = true;
      } catch (e) {
        _isGeminiReady = false;
      }
    }
  }

  void _initWelcomeMessage() {
    final profile = ref.read(userProfileProvider).value;
    final name = (profile != null && profile.fullName.isNotEmpty)
        ? profile.fullName
        : ((profile != null && profile.username.isNotEmpty) ? profile.username : 'there');

    final teach = (profile != null && profile.teachingSkills.isNotEmpty)
        ? profile.teachingSkills.join(', ')
        : 'your skills';
    final learn = (profile != null && profile.learningSkills.isNotEmpty)
        ? profile.learningSkills.join(', ')
        : 'new skills';

    setState(() {
      _messages.add(
        _ChatMessage(
          isUser: false,
          text: 'Hello $name! ✨ I am your SkillSwap AI Copilot.\n\n'
              'I see you are offering **$teach** and looking to learn **$learn**.\n\n'
              'I can help you design collaborative lesson plans, explain our Time Token economy, '
              'craft swap proposals, or find your highest-compatibility matches. Tap any suggestion below or ask me anything!',
        ),
      );
    });
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

  Future<void> _handleSendMessage([String? overrideText]) async {
    final text = (overrideText ?? _messageController.text).trim();
    if (text.isEmpty || _isTyping) return;

    if (overrideText == null) {
      _messageController.clear();
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    // 1. Try Gemini API first if configured
    if (_isGeminiReady && _chat != null) {
      try {
        final response = await _chat!.sendMessage(Content.text(text));
        final reply = response.text;
        if (reply != null && reply.trim().isNotEmpty) {
          if (mounted) {
            setState(() {
              _messages.add(_ChatMessage(text: reply.trim(), isUser: false));
              _isTyping = false;
            });
            _scrollToBottom();
            return;
          }
        }
      } catch (e) {
        // Fall back to built-in knowledge engine on API failure
      }
    }

    // 2. Built-in SkillSwap Knowledge Engine (instant, resilient, high-quality answers)
    await Future.delayed(const Duration(milliseconds: 550));
    final localResponse = _generateSkillSwapAnswer(text);

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: localResponse, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  String _generateSkillSwapAnswer(String query) {
    final lower = query.toLowerCase();
    final profile = ref.read(userProfileProvider).value;
    final teach = (profile != null && profile.teachingSkills.isNotEmpty)
        ? profile.teachingSkills.first
        : 'your skill';
    final learn = (profile != null && profile.learningSkills.isNotEmpty)
        ? profile.learningSkills.first
        : 'your target topic';

    if (lower.contains('token') || lower.contains('currency') || lower.contains('wallet') || lower.contains('economy')) {
      return '### 🪙 The Time Token Economy\n\n'
          'SkillSwap uses a **Time-as-Currency** model:\n\n'
          '• **1 Hour Taught = 1 Time Token Earned (+1)**\n'
          '• **1 Hour Learned = 1 Time Token Spent (-1)**\n'
          '• **Welcome Gift:** Every newly verified user receives **3 starting Time Tokens**.\n'
          '• **Zero Tuition:** Knowledge is exchanged purely on reciprocity, making premium 1-on-1 education accessible to everyone.\n'
          '• **Automated Settlement:** When both peers complete a scheduled session, our immutable ledger immediately transfers 1 token from learner to teacher.';
    }

    if (lower.contains('match') || lower.contains('4d') || lower.contains('dimension') || lower.contains('algorithm')) {
      return '### 🎯 4-Dimensional AI Matchmaking Engine\n\n'
          'Our matching core evaluates four weighted criteria to ensure high swap success:\n\n'
          '1. **Learning Style Compatibility (30%):** Matches visual, auditory, kinesthetic, and reading/writing preferences for effective comprehension.\n'
          '2. **Timezone & Proximity (25%):** Minimizes calendar friction by ranking peers with overlapping availability hours.\n'
          '3. **Proficiency Balance (25%):** Ensures the teacher\'s expertise tier meets or exceeds the learner\'s target goal.\n'
          '4. **Peer Feedback Rating (20%):** Weights completed swap reliability and mentor reputation.';
    }

    if (lower.contains('curriculum') || lower.contains('plan') || lower.contains('lesson') || lower.contains('agenda')) {
      return '### 📅 Suggested 3-Session Swap Curriculum\n'
          '**Exchanging $teach ⟷ $learn**\n\n'
          '**Session 1: Foundations & Goal Alignment (45 min)**\n'
          '• 20 min: Intro to core principles and workspace setup in $teach.\n'
          '• 20 min: Foundational concepts & pronunciation/vocabulary in $learn.\n'
          '• 5 min: Recap & quick weekly challenge assignment.\n\n'
          '**Session 2: Hands-on Practice & Feedback (45 min)**\n'
          '• 20 min: Live guided exercise in $teach with real-time peer critique.\n'
          '• 20 min: Conversational drill & practice exercise in $learn.\n'
          '• 5 min: Q&A and next steps.\n\n'
          '**Session 3: Capstone Mini-Project (60 min)**\n'
          '• 30 min: Review portfolio piece / code in $teach.\n'
          '• 30 min: Fluent real-world application in $learn.\n'
          '• Ledger audit & Cryptographic Proof Badge issuance upon completion!';
    }

    if (lower.contains('badge') || lower.contains('blockchain') || lower.contains('proof') || lower.contains('credential') || lower.contains('verify')) {
      return '### 📜 Cryptographic Proof-of-Skill Badges\n\n'
          'SkillSwap issues tamper-proof verified credentials for completed teaching and learning milestones:\n\n'
          '• **Minting Signature:** Every badge computes a deterministic SHA-256 hash containing learner ID, mentor ID, skill name, hours, and timestamp.\n'
          '• **Progression Tiers:**\n'
          '  - 🥉 **Verified Novice:** 1+ completed hours\n'
          '  - 🥈 **Intermediate Practitioner:** 5+ completed hours\n'
          '  - 🥇 **Advanced Specialist:** 10+ completed hours\n'
          '  - 👑 **Master Mentor:** 20+ completed hours\n'
          '• **Public Verification:** Shareable modal with one-click cryptographic proof verification.';
    }

    if (lower.contains('propose') || lower.contains('message') || lower.contains('pitch') || lower.contains('request') || lower.contains('template')) {
      return '### 💬 High-Conversion Swap Proposal Template\n\n'
          'Feel free to copy and personalize this message when requesting a swap:\n\n'
          '```text\n'
          'Hi [Peer Name]! 👋 I came across your profile on SkillSwap and noticed you teach $learn. '
          'I am looking to improve my skills and would love to exchange 1-on-1 sessions. In return, I can teach you $teach '
          'with tailored exercises based on your learning style. '
          'Let me know if you would be open to a 30-min intro swap this week!\n'
          '```';
    }

    // Default conversational response
    return 'I can help you make the most of SkillSwap AI!\n\n'
        '• Ask me to **plan a tailored curriculum** between $teach and $learn.\n'
        '• Learn how **Time Tokens** allow you to learn without paying tuition.\n'
        '• Understand your **4D Match Score** with candidate peers.\n'
        '• Discover how to earn and verify **Proof-of-Skill Badges**.\n\n'
        'What would you like to explore next?';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryEmerald = Color(0xFF059669);

    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgCard,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronDown, color: textPrimary),
          onPressed: () => context.pop(),
          tooltip: 'Close AI Assistant',
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SkillSwap AI Copilot',
                  style: AppTypography.headlineMd.copyWith(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Multi-Agent Core • Ready',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: strokeColor),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Column(
              children: [
            // USER CONTEXT BADGE
            if (profile != null && (profile.teachingSkills.isNotEmpty || profile.learningSkills.isNotEmpty))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryEmerald.withValues(alpha: 0.06),
                  border: Border(bottom: BorderSide(color: strokeColor)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.userCheck, size: 14, color: primaryEmerald),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active Profile: Teaching ${profile.teachingSkills.isNotEmpty ? profile.teachingSkills.first : "Skills"} • Learning ${profile.learningSkills.isNotEmpty ? profile.learningSkills.first : "Topics"} • ${profile.timeTokens} Tokens',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // CHAT MESSAGES
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildTypingIndicator(bgCard, strokeColor, primaryEmerald);
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, bgCard, strokeColor, textPrimary, textSecondary, primaryEmerald, isDark);
                },
              ),
            ),

            // QUICK PROMPT CHIPS
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return ActionChip(
                    label: Text(
                      prompt['title']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    backgroundColor: bgCard,
                    side: BorderSide(color: strokeColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _handleSendMessage(prompt['query']),
                  );
                },
              ),
            ),

            // BOTTOM MESSAGE INPUT BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgCard,
                border: Border(top: BorderSide(color: strokeColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: strokeColor),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask about matches, curriculum, tokens...',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: (val) => _handleSendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(
                      color: primaryEmerald,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                      tooltip: 'Send prompt',
                      onPressed: () => _handleSendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    _ChatMessage msg,
    Color bgCard,
    Color strokeColor,
    Color textPrimary,
    Color textSecondary,
    Color primaryEmerald,
    bool isDark,
  ) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: primaryEmerald.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: primaryEmerald.withValues(alpha: 0.3)),
              ),
              child: Icon(LucideIcons.bot, color: primaryEmerald, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? primaryEmerald : bgCard,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isUser ? const Radius.circular(3) : null,
                  bottomLeft: !isUser ? const Radius.circular(3) : null,
                ),
                border: Border.all(
                  color: isUser ? primaryEmerald : strokeColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : textPrimary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _copyToClipboard(msg.text),
                          child: Row(
                            children: [
                              Icon(LucideIcons.copy, size: 12, color: textSecondary),
                              const SizedBox(width: 4),
                              Text('Copy', style: TextStyle(color: textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(Color bgCard, Color strokeColor, Color primaryEmerald) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primaryEmerald.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: primaryEmerald.withValues(alpha: 0.3)),
            ),
            child: Icon(LucideIcons.bot, color: primaryEmerald, size: 16),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: strokeColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryEmerald),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SkillSwap AI is thinking...',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
