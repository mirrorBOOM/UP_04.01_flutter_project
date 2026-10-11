import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warningBefore;
  final VoidCallback onTimeout;
  final Widget child;

  const InactivityWatcher({
    super.key,
    this.timeout = const Duration(minutes: 3),
    this.warningBefore = const Duration(seconds: 30),
    required this.onTimeout,
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _actionTimer;
  Timer? _warningTimer;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _actionTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    _actionTimer?.cancel();
    _warningTimer?.cancel();

    if (_dialogShown && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogShown = false;
    }

    final warnTime = widget.timeout - widget.warningBefore;
    _warningTimer = Timer(warnTime > Duration.zero ? warnTime : Duration.zero, _showWarningDialog);
    _actionTimer = Timer(widget.timeout, widget.onTimeout);
  }

  void _showWarningDialog() {
    if (!mounted || _dialogShown) return;
    _dialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Предупреждение о неактивности'),
        content: const Text('Сессия завершится через 30 секунд из-за отсутствия активности.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _dialogShown = false;
              _restart();
            },
            child: const Text('Продолжить работу'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}