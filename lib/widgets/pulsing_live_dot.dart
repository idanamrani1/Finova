import 'dart:async';

import 'package:flutter/material.dart';

import '../design/tokens.dart' show FRadius;

/// ───────────────────────────────────────────────────────────────────────────
// נקודת LIVE פועמת - אנימציה עדינה
class PulsingLiveDot extends StatefulWidget {
  @override
  State<PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    // בדיקת מצב השוק כל דקה כדי לעדכן את הצבע בדיוק בסגירה/פתיחה
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // מחזיר את מצב הבורסה האמריקאית לפי שעון UTC (עוקף בעיות שעון קיץ בקירוב)
  // NYSE/NASDAQ: 9:30-16:00 ניו-יורק. בקיץ (EDT) = 13:30-20:00 UTC, בחורף (EST) = 14:30-21:00 UTC
  // משתמשים בחלון מורחב מעט שמכסה את שני המצבים, ומזהים סופ"ש.
  // מחזיר: 'open' / 'closed'
  String _marketStatus() {
    final now = DateTime.now().toUtc();
    final weekday = now.weekday; // 1=שני ... 6=שבת, 7=ראשון
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return 'closed';
    }
    final minutesUtc = now.hour * 60 + now.minute;
    // 13:30 UTC = 810, 21:00 UTC = 1260 (חלון שמכסה גם קיץ וגם חורף)
    const openMin = 13 * 60 + 30; // 810
    const closeMin = 21 * 60; // 1260
    if (minutesUtc >= openMin && minutesUtc < closeMin) {
      return 'open';
    }
    return 'closed';
  }

  @override
  Widget build(BuildContext context) {
    final status = _marketStatus();
    final isOpen = status == 'open';

    final Color color = isOpen
        ? const Color(0xFF4ade80)
        : const Color(0xFFf87171);
    final String label = isOpen ? 'LIVE' : 'CLOSED';

    Widget dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    // רק כשהשוק פתוח הנקודה פועמת; כשסגור היא קבועה
    if (isOpen) {
      dot = FadeTransition(
        opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
        child: dot,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: FRadius.lgAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
