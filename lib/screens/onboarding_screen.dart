import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _requesting = false;

  Future<void> _doRequest(Future Function() fn) async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await fn();
    } finally {
      if (mounted) {
        setState(() => _requesting = false);
        _next();
      }
    }
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final steps = <_StepData>[
      _StepData(
        icon: Icons.star,
        iconColor: AppTheme.gold,
        bgColor: AppTheme.goldDark,
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
        btnLabel: l10n.onboardingWelcomeBtn,
        onBtn: _next,
        isPermission: false,
      ),
      _StepData(
        icon: Icons.notifications_active_outlined,
        iconColor: const Color(0xFFFFB74D),
        bgColor: const Color(0xFF3D2A00),
        title: l10n.onboardingNotifTitle,
        body: l10n.onboardingNotifBody,
        btnLabel: l10n.onboardingNotifBtn,
        onBtn: () =>
            _doRequest(() => AlarmService.instance.requestNotificationPermission()),
        isPermission: true,
        stepIndex: 1,
      ),
      _StepData(
        icon: Icons.alarm,
        iconColor: AppTheme.primaryBlue,
        bgColor: AppTheme.primaryDark,
        title: l10n.onboardingAlarmTitle,
        body: l10n.onboardingAlarmBody,
        btnLabel: l10n.onboardingAlarmBtn,
        onBtn: () =>
            _doRequest(() => AlarmService.instance.requestExactAlarmPermission()),
        isPermission: true,
        stepIndex: 2,
      ),
      _StepData(
        icon: Icons.battery_saver_outlined,
        iconColor: const Color(0xFF66BB6A),
        bgColor: const Color(0xFF1B3A1C),
        title: l10n.onboardingBatteryTitle,
        body: l10n.onboardingBatteryBody,
        btnLabel: l10n.onboardingBatteryBtn,
        onBtn: () =>
            _doRequest(() => AlarmService.instance.requestBatteryExemption()),
        isPermission: true,
        stepIndex: 3,
      ),
      _StepData(
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF66BB6A),
        bgColor: const Color(0xFF1B3A1C),
        title: l10n.onboardingDoneTitle,
        body: l10n.onboardingDoneBody,
        btnLabel: l10n.onboardingDoneBtn,
        onBtn: _complete,
        isPermission: false,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: steps.length,
                itemBuilder: (context, i) => _StepPage(
                  data: steps[i],
                  loading: _requesting && steps[i].isPermission,
                  totalPermissions: 3,
                ),
              ),
            ),
            _ProgressDots(count: steps.length, current: _page),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

// ─── Données d'une étape ─────────────────────────────────────────────────────

class _StepData {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String body;
  final String btnLabel;
  final VoidCallback onBtn;
  final bool isPermission;
  final int? stepIndex; // 1-3 pour les étapes de permission

  const _StepData({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.body,
    required this.btnLabel,
    required this.onBtn,
    required this.isPermission,
    this.stepIndex,
  });
}

// ─── Page d'une étape ────────────────────────────────────────────────────────

class _StepPage extends StatelessWidget {
  final _StepData data;
  final bool loading;
  final int totalPermissions;

  const _StepPage({
    required this.data,
    required this.loading,
    required this.totalPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 3),

          // Icône dans un cercle coloré
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.bgColor,
              border: Border.all(
                color: data.iconColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(data.icon, size: 46, color: data.iconColor),
          ),

          // Indicateur d'étape (ex. "1 / 3") pour les permissions
          if (data.stepIndex != null) ...[
            const SizedBox(height: 12),
            Text(
              '${data.stepIndex} / $totalPermissions',
              style: const TextStyle(
                color: Color(0xFF4A6B85),
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],

          const Spacer(flex: 1),

          // Titre
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
              height: 1.3,
            ),
          ),

          const Spacer(flex: 2),

          // Corps dans une carte
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E3A52)),
            ),
            child: Text(
              data.body,
              textAlign: isRtl ? TextAlign.right : TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8BAFC9),
                fontSize: 15,
                height: 1.65,
              ),
            ),
          ),

          const Spacer(flex: 3),

          // Bouton
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: loading ? null : data.onBtn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppTheme.primaryBlue.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      data.btnLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ─── Points de progression ───────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int count;
  final int current;
  const _ProgressDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primaryBlue
                : const Color(0xFF1E3A52),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
