import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alarm/alarm.dart' as alarm_pkg;
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class AlarmScreen extends StatefulWidget {
  final alarm_pkg.AlarmSettings settings;
  final Alarm? alarm;

  const AlarmScreen({
    super.key,
    required this.settings,
    this.alarm,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bellCtrl;
  late final AnimationController _pulseCtrl;
  late Timer _clockTimer;
  Timer? _countdownTimer;

  String _currentTime = '';
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  DateTime? _stopAt;  // heure absolue de fin (évite les dérives de Timer)
  bool _stopping = false;

  @override
  void initState() {
    super.initState();

    _totalSeconds = widget.alarm?.ringDurationSeconds ?? 0;
    _currentTime = _formatTime(DateTime.now());

    if (_totalSeconds > 0) {
      // Ancrer le stop sur l'heure de déclenchement programmée, pas sur l'heure
      // d'affichage de l'écran (qui peut être tardive sur MIUI).
      final fired = widget.settings.dateTime;
      final ideal = fired.add(Duration(seconds: _totalSeconds));
      _stopAt = ideal.isAfter(DateTime.now())
          ? ideal
          : DateTime.now().add(const Duration(seconds: 2));
      _remainingSeconds = _stopAt!.difference(DateTime.now()).inSeconds.clamp(0, _totalSeconds);
    } else {
      _remainingSeconds = 0;
    }

    // Bell shake animation
    _bellCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);

    // Glow pulse animation
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Clock + countdown — un seul timer pour les deux
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final now = DateTime.now();

      // Mettre à jour l'heure et le compte à rebours dans setState
      if (_stopAt != null) {
        final remaining = _stopAt!.difference(now).inSeconds;
        setState(() {
          _currentTime = _formatTime(now);
          _remainingSeconds = remaining > 0 ? remaining : 0;
        });
        // Appel stop HORS de setState
        if (remaining <= 0) _stopAlarm();
      } else {
        setState(() => _currentTime = _formatTime(now));
      }
    });
  }

  @override
  void dispose() {
    _bellCtrl.dispose();
    _pulseCtrl.dispose();
    _clockTimer.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);

  String _formatCountdown(int seconds) {
    if (seconds <= 0) return '0:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _stopAlarm() async {
    if (_stopping) return;
    _stopping = true;
    _clockTimer.cancel();
    _countdownTimer?.cancel();
    await alarm_pkg.Alarm.stop(widget.settings.id);
    AlarmService.activeRing.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.alarm?.name ??
        widget.settings.notificationSettings.title;
    final body = widget.settings.notificationSettings.body;
    final progress =
        _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : null;

    return Scaffold(
      backgroundColor: const Color(0xFF040C14),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Animated bell icon
            _PulsingBell(bellCtrl: _bellCtrl, pulseCtrl: _pulseCtrl),

            const SizedBox(height: 36),

            // Current time
            Text(
              _currentTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.w100,
                letterSpacing: 6,
                height: 1,
              ),
            ),

            const SizedBox(height: 20),

            // Alarm name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                name,
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF5A7A99),
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const Spacer(flex: 2),

            // Countdown ring
            if (_totalSeconds > 0) ...[
              _CountdownRing(
                progress: progress!,
                remaining: _formatCountdown(_remainingSeconds),
              ),
              const Spacer(flex: 1),
            ] else ...[
              const Text(
                'Jusqu\'à désactivation',
                style: TextStyle(
                  color: Color(0xFF3A5A79),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(flex: 1),
            ],

            // Stop button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 68,
                child: ElevatedButton(
                  onPressed: _stopping ? null : _stopAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: const Color(0xFF050E18),
                    disabledBackgroundColor: AppTheme.gold.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(34),
                    ),
                    elevation: 12,
                    shadowColor: AppTheme.gold.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Arrêter',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── Bell animée ──────────────────────────────────────────────────────────────

class _PulsingBell extends StatelessWidget {
  const _PulsingBell({
    required this.bellCtrl,
    required this.pulseCtrl,
  });

  final AnimationController bellCtrl;
  final AnimationController pulseCtrl;

  @override
  Widget build(BuildContext context) {
    final shake = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: bellCtrl, curve: Curves.easeInOut),
    );
    final pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: pulseCtrl, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([bellCtrl, pulseCtrl]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Opacity(
              opacity: 1 - pulse.value,
              child: Container(
                width: 130 + pulse.value * 30,
                height: 130 + pulse.value * 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.gold.withOpacity(0.15),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Icon container
            Transform.rotate(
              angle: shake.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF1E3D60), Color(0xFF071018)],
                  ),
                  border: Border.all(color: AppTheme.gold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppTheme.gold,
                  size: 50,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Compte à rebours ─────────────────────────────────────────────────────────

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.progress, required this.remaining});

  final double progress;
  final String remaining;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox.expand(
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                trackColor: const Color(0xFF1A3A5C),
                fillColor: AppTheme.gold,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remaining,
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 30,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 1,
                ),
              ),
              const Text(
                'restant',
                style: TextStyle(
                  color: Color(0xFF4A6B88),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 5.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Full circle (track)
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc (clockwise from top)
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
