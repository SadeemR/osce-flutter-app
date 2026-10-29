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
import '../widgets/motion.dart';
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
  int _totalTime = 300;
  Timer? _timer;
  bool _waitingForReply = false;
  bool _sessionActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timeRemaining = context.read<AppSettings>().simulationTime;
      _totalTime = _timeRemaining;
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
    // The exam can't be left with the back button.
    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        title: Text(
            AppStrings(context.watch<AppSettings>().isArabic).osceSimulation),
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
    ),
    );
  }

  Color get _timeColor {
    if (_timeRemaining <= 30) return AppColors.danger;
    if (_timeRemaining <= 60) return AppColors.warning;
    return AppColors.accent;
  }

  Widget _timerHeader() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    final fraction = _totalTime == 0 ? 0.0 : _timeRemaining / _totalTime;
    return AnimatedOpacity(
      duration: AppMotion.base,
      opacity: _sessionActive ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _LiveBadge(label: s.testPhase, active: _sessionActive),
                const Spacer(),
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: _timeColor),
                  duration: AppMotion.slow,
                  builder: (_, c, __) => Text(
                    _formattedTime,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: c,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Pressable(
                  scale: 0.94,
                  child: Material(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(100),
                    child: InkWell(
                      onTap: _endSession,
                      borderRadius: BorderRadius.circular(100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stop_rounded,
                                size: 16, color: AppColors.danger),
                            const SizedBox(width: 4),
                            Text(s.endSession,
                                style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(end: fraction.clamp(0.0, 1.0).toDouble()),
              duration: const Duration(milliseconds: 1000),
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceRaised,
                  valueColor: AlwaysStoppedAnimation(_timeColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatList(SessionManager session) {
    final now = DateTime.now();
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        ...session.messages.map((m) => FadeSlideIn(
              key: ValueKey(m.id),
              offset: 10,
              duration: AppMotion.base,
              // Only animate messages that just arrived, not on scroll-back.
              animate: now.difference(m.timestamp).inMilliseconds < 1500,
              child: MessageBubble(message: m),
            )),
        if (!_sessionActive)
          FadeSlideIn(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text(
                      AppStrings(context.watch<AppSettings>().isArabic)
                          .sessionEndedEval,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _inputBar() {
    final s = AppStrings(context.watch<AppSettings>().isArabic);
    final disabled = _isSendDisabled;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: _sessionActive,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: s.typeResponse,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.border)),
                disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            enabled: !disabled,
            scale: 0.88,
            child: GestureDetector(
              onTap: disabled ? null : _sendMessage,
              child: AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.enter,
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: disabled ? AppColors.surfaceRaised : AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.base,
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: _waitingForReply
                      ? const Padding(
                          key: ValueKey('wait'),
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.textSecondary),
                        )
                      : Icon(Icons.arrow_upward_rounded,
                          key: const ValueKey('send'),
                          size: 22,
                          color: disabled
                              ? AppColors.textMuted
                              : AppColors.onAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final String label;
  final bool active;
  const _LiveBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.textMuted,
        shape: BoxShape.circle,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          active ? Pulse(child: dot) : dot,
          const SizedBox(width: 7),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
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

  bool _isArabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);

  @override
  Widget build(BuildContext context) {
    if (_isSystem) {
      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(100)),
          child: Text(message.text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
      );
    }

    const big = Radius.circular(18);
    const small = Radius.circular(6);
    final radius = _isDoctor
        ? const BorderRadiusDirectional.only(
            topStart: big, topEnd: big, bottomStart: big, bottomEnd: small)
        : const BorderRadiusDirectional.only(
            topStart: big, topEnd: big, bottomStart: small, bottomEnd: big);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            _isDoctor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(message.sender.displayName,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isDoctor
                        ? AppColors.accent
                        : AppColors.textMuted)),
          ),
          const SizedBox(height: 5),
          AnimatedSize(
            duration: AppMotion.base,
            curve: AppMotion.enter,
            alignment: _isDoctor
                ? AlignmentDirectional.centerEnd.resolve(Directionality.of(context))
                : AlignmentDirectional.centerStart.resolve(Directionality.of(context)),
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: _isDoctor ? AppColors.accent : AppColors.surfaceRaised,
                borderRadius: radius,
                border: _isDoctor ? null : Border.all(color: AppColors.border),
              ),
              child: message.isLoading
                  ? const TypingIndicator()
                  : Text(
                      message.text,
                      textDirection: _isArabic(message.text)
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                          color:
                              _isDoctor ? AppColors.onAccent : AppColors.text,
                          fontSize: 15,
                          height: 1.45),
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(DateFormat.jm().format(message.timestamp),
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

/// Three dots that bounce in sequence while the patient is "typing".
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 18,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Each dot rises and brightens in turn.
            final t = ((_controller.value - i * 0.15) % 1.0 + 1.0) % 1.0;
            final wave = t < 0.4 ? Curves.easeInOut.transform(t < 0.2 ? t / 0.2 : (0.4 - t) / 0.2) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Transform.translate(
                offset: Offset(0, -4 * wave),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                        AppColors.textMuted, AppColors.text, wave),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
