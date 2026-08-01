import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// Finova primitives.
///
/// Every widget here reads colour, radius, spacing and type from tokens.dart.
/// No literal colours, no literal radii. Screens are assembled from these.
/// ───────────────────────────────────────────────────────────────────────────

/// Wraps a tappable thing in the standard press feedback: scale to .985 over
/// 120ms plus a selection haptic.
///
/// It is also the app's single keyboard-accessibility seam. A bare
/// [GestureDetector] cannot take focus, so every card, chip and row built on
/// it would be unreachable by keyboard — a WCAG 2.1.1 (Level A) failure.
/// [FocusableActionDetector] makes each one tabbable, activatable with
/// Enter/Space, announced as a button, and draws the visible focus ring that
/// criterion 2.4.7 (Level AA) requires.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.985,
    this.haptic = true,
    this.semanticLabel,
    this.focusRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final String? semanticLabel;

  /// Corner radius of the focus ring. Defaults to the large card radius.
  final double? focusRadius;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  bool _focused = false;

  void _activate() {
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    final c = context.c;

    return FocusableActionDetector(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        onTap: _activate,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: _activate,
          child: AnimatedScale(
            scale: _down ? widget.scale : 1.0,
            duration: FMotion.respect(context, FMotion.press),
            curve: Curves.easeOut,
            child: DecoratedBox(
              // outline-offset 2px, בדיוק כמו בסעיף הנגישות בתכנית
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  (widget.focusRadius ?? FRadius.lg) + 2,
                ),
                border: _focused
                    ? Border.all(color: c.brandVioletBright, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts a section in on first build. [index] staggers siblings.
class EnterIn extends StatefulWidget {
  const EnterIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<EnterIn> createState() => _EnterInState();
}

class _EnterInState extends State<EnterIn> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    final delay = FMotion.stagger * widget.index;
    Future<void>.delayed(delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.reducedMotion) return widget.child;
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.035),
      duration: FMotion.screenEnter,
      curve: FMotion.enter,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: FMotion.screenEnter,
        curve: FMotion.enter,
        child: widget.child,
      ),
    );
  }
}

/// The standard card: surface background, hairline border, large radius.
class FCard extends StatelessWidget {
  const FCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = FRadius.lg,
    this.background,
    this.border,
    this.gradient,
    this.shadow,
    this.nested = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? background;
  final Border? border;

  /// Optional wash painted over the background (the hero card uses this).
  final Gradient? gradient;
  final List<BoxShadow>? shadow;

  /// Nested cards sit on --bg-surface-2 so they read against their parent.
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      focusRadius: radius,
      child: Container(
        padding: padding ?? const EdgeInsets.all(FSpace.cardPad),
        decoration: BoxDecoration(
          color: background ?? (nested ? c.bgSurface2 : c.bgSurface),
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: border ?? FBorder.card(c),
          boxShadow: shadow,
        ),
        child: child,
      ),
    );
  }
}

/// Tone of a chip / accent element. Green and red are reserved for market
/// direction and for the buy/sell verdict that sits next to it.
enum FTone { green, red, amber, violet, neutral }

extension FToneColors on FTone {
  Color fg(FScheme c) => switch (this) {
    FTone.green => c.accentGreen,
    FTone.red => c.accentRed,
    FTone.amber => c.accentAmber,
    FTone.violet => c.brandVioletBright,
    FTone.neutral => c.textSecondary,
  };

  Color bg(FScheme c) => switch (this) {
    FTone.green => c.accentGreenDim,
    FTone.red => c.accentRedDim,
    FTone.amber => c.accentAmberDim,
    FTone.violet => c.brandViolet.withValues(alpha: 0.15),
    FTone.neutral => c.hairline,
  };
}

/// A pill label. [large] is the hero card's recommendation chip.
class FChip extends StatelessWidget {
  const FChip({
    super.key,
    required this.label,
    this.tone = FTone.neutral,
    this.icon,
    this.large = false,
    this.onTap,
    this.bordered = false,
  });

  final String label;
  final FTone tone;
  final IconData? icon;
  final bool large;
  final VoidCallback? onTap;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = tone.fg(c);
    return PressScale(
      onTap: onTap,
      focusRadius: large ? FRadius.sm : FRadius.pill,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 10,
          vertical: large ? 8 : 5,
        ),
        decoration: BoxDecoration(
          color: tone.bg(c),
          borderRadius: BorderRadius.circular(
            large ? FRadius.sm : FRadius.pill,
          ),
          border: bordered
              ? Border.all(color: fg.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: large ? 18 : 13, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: large
                  ? FType.h3.copyWith(fontSize: 15, color: fg)
                  : FType.micro.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 52px violet gradient square that leads an action row.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 52,
    this.radius = FRadius.md,
    this.iconSize = 24,
    this.tone,
  });

  final IconData icon;
  final double size;
  final double radius;
  final double iconSize;

  /// Overrides the violet gradient with a flat dim tone (the "why?" tiles).
  final FTone? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: tone == null ? FGrad.icon(c) : null,
        color: tone?.bg(c),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: tone?.fg(c) ?? c.brandVioletBright,
      ),
    );
  }
}

/// Full-width row: icon tile, title + subtitle, chevron.
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.alignTextEnd = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// The reference puts the icon tile on the physical left with the Hebrew
  /// copy pushed to the right, so the row runs LTR while its text stays
  /// right-aligned. Set this when the row is placed inside an LTR subtree.
  final bool alignTextEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FCard(
      onTap: onTap,
      padding: const EdgeInsets.all(FSpace.cardGap),
      child: Row(
        children: [
          IconTile(icon: icon),
          const SizedBox(width: FSpace.cardGap),
          Expanded(
            child: Column(
              crossAxisAlignment: alignTextEnd
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: alignTextEnd ? TextAlign.end : TextAlign.start,
                  style: FType.h3.copyWith(color: c.textPrimary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: alignTextEnd ? TextAlign.end : TextAlign.start,
                    style: FType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: FSpace.sm),
          trailing ??
              Icon(
                // Points "forward" — flips automatically with the direction.
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: c.textTertiary,
              ),
        ],
      ),
    );
  }
}

/// Section heading, right-aligned in Hebrew, with an optional leading glyph.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.text,
    this.leading,
    this.trailing,
  });

  final String text;

  /// The two emoji the design keeps: 🔥 on the carousel, 👋 on the greeting.
  final String? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: FSpace.md),
      child: Row(
        children: [
          if (leading != null) ...[
            Text(leading!, style: FType.h3),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(text, style: FType.h3.copyWith(color: c.textPrimary)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Animated score ring. Sweeps clockwise from 12 o'clock over 900ms.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    required this.color,
    this.size = 84,
    this.strokeWidth = 6,
    this.label,
    this.semanticLabel,
    this.animate = true,
  });

  final int score;
  final Color color;
  final double size;
  final double strokeWidth;

  /// Centre content. Defaults to the score over /100.
  final Widget? label;
  final String? semanticLabel;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final duration = animate
        ? FMotion.respect(context, FMotion.ring)
        : Duration.zero;

    return Semantics(
      image: true,
      label: semanticLabel ?? 'ציון $score מתוך 100',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
              duration: duration,
              curve: FMotion.ringCurve,
              builder: (context, value, _) => CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: value,
                  color: color,
                  track: c.textPrimary.withValues(alpha: 0.07),
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
            label ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$score', style: FType.display.copyWith(color: color)),
                    Text(
                      '/100',
                      style: FType.caption.copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    // -90deg puts the start at the top; positive sweep runs clockwise.
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, arcPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.strokeWidth != strokeWidth;
}

/// Loading placeholder: the real component's silhouette with a moving sheen.
class FSkeleton extends StatefulWidget {
  const FSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = FRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<FSkeleton> createState() => _FSkeletonState();
}

class _FSkeletonState extends State<FSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: FMotion.shimmer,
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final base = c.bgSurface2;

    if (context.reducedMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        // Sheen travels from one edge to the other; -1..2 keeps it off-screen
        // at both ends so the loop doesn't visibly restart mid-box.
        final t = _ctl.value * 3 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 0.6, 0),
              end: Alignment(t + 0.6, 0),
              colors: [base, c.textPrimary.withValues(alpha: 0.05), base],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton shaped like a card, for list/grid loading states.
class FSkeletonCard extends StatelessWidget {
  const FSkeletonCard({super.key, this.height = 96, this.lines = 2});

  final double height;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < lines; i++) ...[
              FSkeleton(width: i == 0 ? 140 : double.infinity),
              if (i != lines - 1) const SizedBox(height: FSpace.md),
            ],
          ],
        ),
      ),
    );
  }
}

/// Nothing here yet — an outline glyph, a line of explanation, one action.
class FEmptyState extends StatelessWidget {
  const FEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: FSpace.xxxl,
        horizontal: FSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: c.textTertiary),
          const SizedBox(height: FSpace.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: FType.body.copyWith(color: c.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: FSpace.lg),
            FPrimaryButton(label: actionLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );
  }
}

/// Something failed — short line plus a retry.
class FErrorState extends StatelessWidget {
  const FErrorState({
    super.key,
    required this.message,
    required this.retryLabel,
    this.onRetry,
    this.hint,
  });

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: FSpace.xxxl,
        horizontal: FSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 34, color: c.accentAmber),
          const SizedBox(height: FSpace.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: FType.body.copyWith(color: c.textPrimary),
          ),
          if (hint != null) ...[
            const SizedBox(height: FSpace.xs),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: FType.caption.copyWith(color: c.textTertiary),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: FSpace.lg),
            FPrimaryButton(label: retryLabel, onPressed: onRetry!),
          ],
        ],
      ),
    );
  }
}

/// Primary action button — brand violet, pill.
class FPrimaryButton extends StatelessWidget {
  const FPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expand;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: busy ? null : onPressed,
      focusRadius: FRadius.pill,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
          horizontal: FSpace.xl,
          vertical: FSpace.md,
        ),
        decoration: BoxDecoration(
          color: c.brandViolet,
          borderRadius: FRadius.pillAll,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: FType.h3.copyWith(fontSize: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stock logo slot. No logo provider exists, so this is the documented
/// fallback: the first letter on a neutral tile.
class TickerAvatar extends StatelessWidget {
  const TickerAvatar({
    super.key,
    required this.ticker,
    this.logoUrl,
    this.size = 52,
    this.radius = FRadius.sm,
  });

  final String ticker;

  /// Must be same-origin (the backend proxies it): Flutter web paints through
  /// CanvasKit, and a cross-origin image without CORS headers silently fails
  /// to draw rather than erroring.
  final String? logoUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final letter = ticker.trim().isEmpty ? '?' : ticker.trim()[0].toUpperCase();

    final fallback = ColoredBox(
      color: c.bgSurface2,
      child: Center(
        child: Text(
          letter,
          style: FType.h2.copyWith(
            fontSize: size * 0.42,
            color: c.textSecondary,
          ),
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.bgSurface2,
        borderRadius: BorderRadius.circular(radius),
        border: FBorder.subtle(c),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl == null
          ? fallback
          : Image.network(
              logoUrl!,
              width: size,
              height: size,
              // cover ולא contain: כל לוגו מגיע עם רקע משלו (NVIDIA שחור,
              // מיקרוסופט לבן, טסלה אדום). ב-contain נוצרת מסגרת בתוך
              // מסגרת - הרקע שלנו מציץ סביב הריבוע שלהם. ב-cover הרקע של
              // הלוגו הוא המשבצת, וכולם יושבים אותו דבר. הלוגואים ריבועיים
              // אז אין חיתוך בפועל.
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              // אין לוגו לטיקר, או שהבקשה נכשלה - חוזרים לאות הראשונה
              errorBuilder: (context, _, _) => fallback,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}

/// Pagination dots under the carousel.
class FDots extends StatelessWidget {
  const FDots({super.key, required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: FMotion.respect(context, FMotion.tab),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: on
                ? c.brandVioletBright
                : c.textPrimary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

/// A directional glyph that must never mirror.
///
/// Material marks the trending arrows as text-direction-aware, so in Hebrew an
/// "up" arrow is drawn mirrored and reads exactly like a "down" arrow — on a
/// price chip that inverts the meaning of the number next to it.
class TrendIcon extends StatelessWidget {
  const TrendIcon(this.icon, {super.key, this.size = 14, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Icon(icon, size: size, color: color ?? context.c.textPrimary),
    );
  }
}

/// Thin separator used inside cards.
class FDivider extends StatelessWidget {
  const FDivider({super.key, this.vertical = FSpace.md});

  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Container(height: 1, color: context.c.hairline),
    );
  }
}
