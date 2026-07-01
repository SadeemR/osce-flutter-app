import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../state/session_manager.dart';
import '../theme/app_theme.dart';
import 'evaluation_screen.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  int _timeRemaining = 300;
  Timer? _timer;
  bool _waitingForReply = false;
  bool _sessionActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timeRemaining = context.read<AppSettings>().simulationTime;
      _startTimer();
      setState(() {});
    });
    _input.addListener(() => setState(() {}));
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _endSession();
      }
    });
  }

  String get _formattedTime {
    final m = _timeRemaining ~/ 60;
    final s = (_timeRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  ApiService _api() => ApiService(context.read<AppSettings>().apiBaseURL);

  bool get _isSendDisabled =>
      !_sessionActive || _input.text.trim().isEmpty || _waitingForReply;

  Future<void> _sendMessage() async {
    final text = _input.text.trim();
    if (text.isEmpty || _waitingForReply || !_sessionActive) return;
    final session = context.read<SessionManager>();

    session.addMessage(ChatMessage(sender: MessageSender.doctor, text: text));
    _input.clear();
    _scrollToEnd();

    setState(() => _waitingForReply = true);
    final loading =
        ChatMessage(sender: MessageSender.parent, text: '...', isLoading: true);
    session.addMessage(loading);
    _scrollToEnd();

    try {
      final reply = await _api().sendMessage(session.sessionId, text);
      if (reply.trim().isEmpty) {
        session.removeMessage(loading.id);
      } else {
        session.replaceMessage(
            loading.id, ChatMessage(sender: MessageSender.parent, text: reply));
      }
    } catch (e) {
      session.removeMessage(loading.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      session.removeLoadingMessages();
      if (mounted) setState(() => _waitingForReply = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _endSession() {
    if (!_sessionActive) return;
    _timer?.cancel();
    setState(() => _sessionActive = false);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EvaluationScreen()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    return Scaffold(
      backgroundColor: AppColors.offWhiteCream,
      appBar: AppBar(
        title: Text(AppStrings(context.watch<AppSettings>().isArabic).osceSimulation),
        backgroundColor: AppColors.offWhiteCream,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _timerHeader(),
            Expanded(child: _chatList(session)),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _timerHeader() {
    return Opacity(
      opacity: _sessionActive ? 1.0 : 0.6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Column(
          children: [
            Text('${AppStrings(context.watch<AppSettings>().isArabic).taskTimeRemaining}$_formattedTime',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, size: 15, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(AppStrings(context.watch<AppSettings>().isArabic).testPhase,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _endSession,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(100)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stop, size: 15, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(AppStrings(context.watch<AppSettings>().isArabic).endSession,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatList(SessionManager session) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      children: [
        ...session.messages.map((m) => MessageBubble(message: m)),
        if (!_sessionActive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(AppStrings(context.watch<AppSettings>().isArabic).sessionEndedEval,
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _inputBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: _sessionActive,
              style: const TextStyle(color: Colors.white),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: AppStrings(context.watch<AppSettings>().isArabic).typeResponse,
                filled: true,
                fillColor: AppColors.cardCream,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSendDisabled ? null : _sendMessage,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isSendDisabled ? Colors.grey : AppColors.brandPrimary,
                shape: BoxShape.circle,
              ),
              child: _waitingForReply
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});

  bool get _isDoctor => message.sender == MessageSender.doctor;
  bool get _isSystem => message.sender == MessageSender.system;

  bool _isArabic(String s) => RegExp(r'[\u0600-\u06FF]').hasMatch(s);

  @override
  Widget build(BuildContext context) {
    if (_isSystem) {
      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100)),
          child: Text(message.text,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment:
            _isDoctor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(message.sender.displayName,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isDoctor
                        ? AppColors.brandPrimary
                        : AppColors.apricot)),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 80),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isDoctor ? AppColors.brandPrimary : AppColors.apricotPale,
              borderRadius: BorderRadius.circular(16),
              border: _isDoctor
                  ? null
                  : Border.all(color: AppColors.apricot.withValues(alpha: 0.4), width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: message.isLoading
                ? const TypingIndicator()
                : Text(
                    message.text,
                    textDirection: _isArabic(message.text)
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: TextStyle(
                        color: _isDoctor ? Colors.white : Colors.white,
                        height: 1.4),
                  ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(DateFormat.jm().format(message.timestamp),
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final t = (_controller.value + i * 0.18) % 1.0;
              final scale = 0.8 + 0.4 * (1 - (2 * t - 1).abs());
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.white60, shape: BoxShape.circle),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}