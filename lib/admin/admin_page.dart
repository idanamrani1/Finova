import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../design/logo.dart';
import '../design/primitives.dart';
import '../design/tokens.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// מסך התחברות ופאנל ניהול.
///
/// עמוד מלא ונפרד, ולא סקשן מתקפל בתוך ההגדרות: מפתחות ה-API הם הדבר
/// הרגיש היחיד באפליקציה, ואין סיבה שהם יופיעו במסך שכל משתמש פותח.
/// הכניסה אליו היא דרך שורה אחת ב"עוד", וכל מה שמאחוריה נמצא כאן.
///
/// הדף מחזיק את המצב שלו בעצמו (טוקן, שדות, שגיאות) ופונה ישירות לשרת,
/// כדי שסודות לא יישבו ב-state של מסך הדשבורד הראשי.
///
/// לא נוצרה כאן מערכת משתמשים: השרת מכיר סיסמת מנהל אחת (PBKDF2 + טוקן
/// סשן) וזה בדיוק מה שהמסך הזה מפעיל.
/// ───────────────────────────────────────────────────────────────────────────
class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.apiBase,
    required this.tr,
    required this.scheme,
    required this.isRtl,
  });

  final String apiBase;
  final String Function(String) tr;
  final FScheme scheme;
  final bool isRtl;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _passwordController = TextEditingController();
  final _finnhubController = TextEditingController();
  final _groqController = TextEditingController();
  final _geminiController = TextEditingController();
  final _discordController = TextEditingController();

  bool _statusLoaded = false;
  bool _configured = false;
  bool _busy = false;
  String? _token;
  String? _error;
  String? _message;
  String _finnhubMasked = '';
  String _groqMasked = '';
  String _geminiMasked = '';
  String _discordMasked = '';

  bool _discordTestBusy = false;
  String? _discordTestResult;
  bool _discordTestFailed = false;

  String tr(String k) => widget.tr(k);

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _finnhubController.dispose();
    _groqController.dispose();
    _geminiController.dispose();
    _discordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final res = await http.get(
        Uri.parse('${widget.apiBase}/api/admin/status'),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _configured = data['configured'] == true;
          _statusLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statusLoaded = true);
    }
  }

  Future<void> _submitPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // setup בפעם הראשונה, login מכאן והלאה
      final endpoint = _configured ? 'login' : 'setup';
      final res = await http.post(
        Uri.parse('${widget.apiBase}/api/admin/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _token = data['token'];
          _configured = true;
          _passwordController.clear();
        });
        await _loadKeys();
      } else if (res.statusCode == 429) {
        // fail2ban חוסם ניסיונות חוזרים, וזו הודעה אחרת מ"סיסמה שגויה"
        setState(() => _error = tr('tooManyAttempts'));
      } else {
        setState(() => _error = tr('wrongPassword'));
      }
    } catch (_) {
      if (mounted) setState(() => _error = tr('connectionError'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadKeys() async {
    if (_token == null) return;
    try {
      final res = await http.get(
        Uri.parse('${widget.apiBase}/api/admin/keys'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _finnhubMasked = data['finnhubKey'] ?? '';
          _groqMasked = data['groqKey'] ?? '';
          _geminiMasked = data['geminiKey'] ?? '';
          _discordMasked = data['discordWebhookUrl'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveKeys() async {
    if (_token == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      // רק שדה שמולא נשלח - שדה ריק פירושו "אל תיגע במפתח הקיים"
      final body = <String, String>{};
      if (_finnhubController.text.trim().isNotEmpty) {
        body['finnhubKey'] = _finnhubController.text.trim();
      }
      if (_groqController.text.trim().isNotEmpty) {
        body['groqKey'] = _groqController.text.trim();
      }
      if (_geminiController.text.trim().isNotEmpty) {
        body['geminiKey'] = _geminiController.text.trim();
      }
      if (_discordController.text.trim().isNotEmpty) {
        body['discordWebhookUrl'] = _discordController.text.trim();
      }

      final res = await http.post(
        Uri.parse('${widget.apiBase}/api/admin/keys'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _finnhubController.clear();
        _groqController.clear();
        _geminiController.clear();
        _discordController.clear();
        setState(() => _message = tr('savedOk'));
        await _loadKeys();
      } else if (res.statusCode == 401) {
        setState(() {
          _token = null;
          _error = tr('sessionExpired');
        });
      } else {
        setState(() => _error = tr('saveFailed'));
      }
    } catch (_) {
      if (mounted) setState(() => _error = tr('connectionError'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _logout() {
    setState(() {
      _token = null;
      _message = null;
      _error = null;
      _finnhubController.clear();
      _groqController.clear();
      _geminiController.clear();
      _discordController.clear();
      _discordTestResult = null;
    });
  }

  Future<void> _sendDiscordTest() async {
    if (_token == null) return;
    setState(() {
      _discordTestBusy = true;
      _discordTestResult = null;
      _discordTestFailed = false;
    });
    try {
      final res = await http.post(
        Uri.parse('${widget.apiBase}/api/admin/discord-test'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => _discordTestResult = tr('discordTestSent'));
      } else {
        final body = jsonDecode(res.body);
        final notConfigured = body['error'] == 'not_configured';
        setState(() {
          _discordTestFailed = true;
          _discordTestResult = notConfigured
              ? tr('discordNotConfigured')
              : tr('discordTestFailed');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _discordTestFailed = true;
          _discordTestResult = tr('connectionError');
        });
      }
    } finally {
      if (mounted) setState(() => _discordTestBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.scheme;
    return FTheme(
      scheme: c,
      child: Directionality(
        textDirection: widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: c.bgApp,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(c),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      FSpace.screen,
                      FSpace.lg,
                      FSpace.screen,
                      FSpace.xxxl,
                    ),
                    children: [
                      if (_token == null) _buildLogin(c) else _buildPanel(c),
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

  Widget _buildHeader(FScheme c) {
    return SizedBox(
      height: FSpace.headerHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FSpace.screen),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              PressScale(
                semanticLabel: tr('back'),
                focusRadius: FRadius.pill,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: FSpace.md),
                  decoration: BoxDecoration(
                    color: c.bgSurface2,
                    borderRadius: FRadius.pillAll,
                    border: FBorder.subtle(c),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: c.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tr('back'),
                        style: FType.h3.copyWith(
                          fontSize: 14,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (_token != null)
                PressScale(
                  semanticLabel: tr('logout'),
                  focusRadius: FRadius.pill,
                  onTap: _logout,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: FSpace.md),
                    decoration: BoxDecoration(
                      color: c.accentRedDim,
                      borderRadius: FRadius.pillAll,
                      border: Border.all(
                        color: c.accentRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: c.accentRed,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tr('logout'),
                          style: FType.h3.copyWith(
                            fontSize: 14,
                            color: c.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── מסך התחברות ──
  Widget _buildLogin(FScheme c) {
    final firstTime = _statusLoaded && !_configured;
    return Column(
      children: [
        const SizedBox(height: FSpace.xxxl),
        const Logo(variant: LogoVariant.mark, markSize: 56),
        const SizedBox(height: FSpace.xl),
        Text(
          tr('adminPanel'),
          style: FType.h1.copyWith(color: c.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: FSpace.sm),
        Text(
          firstTime ? tr('setPasswordHint') : tr('enterPasswordHint'),
          style: FType.body.copyWith(color: c.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: FSpace.xxl),
        FCard(
          child: Column(
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                style: FType.body.copyWith(color: c.textPrimary),
                cursorColor: c.brandVioletBright,
                decoration: InputDecoration(
                  labelText: tr('password'),
                  labelStyle: FType.body.copyWith(color: c.textTertiary),
                  filled: true,
                  fillColor: c.bgSurface2,
                  border: OutlineInputBorder(
                    borderRadius: FRadius.mdAll,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: FRadius.mdAll,
                    borderSide: BorderSide(color: c.hairlineStrong),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: FRadius.mdAll,
                    borderSide: BorderSide(
                      color: c.brandVioletBright,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(Icons.lock_outline, color: c.textTertiary),
                ),
                onSubmitted: (_) => _submitPassword(),
              ),
              if (_error != null) ...[
                const SizedBox(height: FSpace.md),
                _buildNotice(c, _error!, isError: true),
              ],
              const SizedBox(height: FSpace.lg),
              FPrimaryButton(
                label: firstTime ? tr('setPassword') : tr('login'),
                expand: true,
                busy: _busy,
                icon: Icons.login_rounded,
                onPressed: _submitPassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: FSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 14, color: c.textTertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                tr('adminSecurityNote'),
                style: FType.micro.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── הפאנל עצמו ──
  Widget _buildPanel(FScheme c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('adminPanel'), style: FType.h1.copyWith(color: c.textPrimary)),
        const SizedBox(height: FSpace.xs),
        Text(
          tr('adminPanelSub'),
          style: FType.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: FSpace.xl),
        FCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.key_rounded, size: 18, color: c.brandVioletBright),
                  const SizedBox(width: FSpace.sm),
                  Text(
                    tr('apiKeysPrivate'),
                    style: FType.h3.copyWith(color: c.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: FSpace.sm),
              Text(
                tr('onlyFillToChange'),
                style: FType.caption.copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: FSpace.lg),
              _buildKeyField(
                c,
                _finnhubController,
                'FINNHUB_KEY',
                _finnhubMasked,
              ),
              _buildKeyField(c, _groqController, 'GROQ_KEY', _groqMasked),
              _buildKeyField(c, _geminiController, 'GEMINI_KEY', _geminiMasked),
              if (_error != null) ...[
                _buildNotice(c, _error!, isError: true),
                const SizedBox(height: FSpace.md),
              ],
              if (_message != null) ...[
                _buildNotice(c, _message!, isError: false),
                const SizedBox(height: FSpace.md),
              ],
              FPrimaryButton(
                label: tr('save'),
                expand: true,
                busy: _busy,
                icon: Icons.save_rounded,
                onPressed: _saveKeys,
              ),
            ],
          ),
        ),
        const SizedBox(height: FSpace.xl),
        FCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.forum_rounded,
                    size: 18,
                    color: Color(0xFF5865F2), // צבע המותג של Discord
                  ),
                  const SizedBox(width: FSpace.sm),
                  Text(
                    tr('discordAlerts'),
                    style: FType.h3.copyWith(color: c.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: FSpace.sm),
              Text(
                tr('discordAlertsSub'),
                style: FType.caption.copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: FSpace.lg),
              _buildKeyField(
                c,
                _discordController,
                'DISCORD_WEBHOOK_URL',
                _discordMasked,
              ),
              if (_discordTestResult != null) ...[
                _buildNotice(
                  c,
                  _discordTestResult!,
                  isError: _discordTestFailed,
                ),
                const SizedBox(height: FSpace.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: FPrimaryButton(
                      label: tr('save'),
                      expand: true,
                      busy: _busy,
                      icon: Icons.save_rounded,
                      onPressed: _saveKeys,
                    ),
                  ),
                  const SizedBox(width: FSpace.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_discordMasked.isEmpty || _discordTestBusy)
                          ? null
                          : _sendDiscordTest,
                      icon: _discordTestBusy
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.textSecondary,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        tr('sendTestAlert'),
                        style: FType.h3.copyWith(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textPrimary,
                        side: BorderSide(color: c.hairlineStrong),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: FRadius.pillAll,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyField(
    FScheme c,
    TextEditingController controller,
    String label,
    String masked,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FSpace.md),
      child: TextField(
        controller: controller,
        style: FType.body.copyWith(color: c.textPrimary),
        cursorColor: c.brandVioletBright,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: FType.caption.copyWith(color: c.textTertiary),
          // המפתח עצמו לעולם לא חוזר מהשרת, רק צורתו הממוסכת
          hintText: masked.isNotEmpty
              ? '${tr('currentMasked')}: $masked'
              : tr('notSet'),
          hintStyle: FType.caption.copyWith(color: c.textQuiet),
          filled: true,
          fillColor: c.bgSurface2,
          border: OutlineInputBorder(
            borderRadius: FRadius.mdAll,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: FRadius.mdAll,
            borderSide: BorderSide(color: c.hairlineStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: FRadius.mdAll,
            borderSide: BorderSide(color: c.brandVioletBright, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildNotice(FScheme c, String text, {required bool isError}) {
    final color = isError ? c.accentRed : c.accentGreen;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FSpace.md),
      decoration: BoxDecoration(
        color: isError ? c.accentRedDim : c.accentGreenDim,
        borderRadius: FRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: FSpace.sm),
          Expanded(
            child: Text(text, style: FType.caption.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
