import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' show ImageFilter;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin/admin_page.dart';
import 'design/logo.dart';
import 'i18n/strings.dart';
import 'legal/accessibility.dart';
import 'legal/privacy.dart';
import 'legal/terms.dart';
import 'logic/formatting.dart' as fmt;
import 'design/primitives.dart';
import 'design/tokens.dart';
import 'screens/splash_screen.dart';
import 'widgets/mini_chart_painter.dart';
import 'widgets/pulsing_live_dot.dart';

// ───────────────────────────────────────────
// גשר ל-JS של התראות דחיפה (מוגדר ב-index.html)
// ───────────────────────────────────────────
@JS('finovaDoc.applyLang')
external void _jsApplyLang(JSString lang);

@JS('finovaPush.supported')
external bool _jsPushSupported();

@JS('finovaPush.subscribe')
external JSPromise<JSString> _jsPushSubscribe(JSString vapidKey);

@JS('finovaPush.current')
external JSPromise<JSString> _jsPushCurrent();

@JS('finovaPush.unsubscribe')
external JSPromise<JSString> _jsPushUnsubscribe();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter web מצייר לקנבס, ועץ ה-semantics - מה שקורא מסך באמת קורא -
  // נבנה רק אחרי שהמשתמש מוצא ולוחץ על כפתור "הפעל נגישות" מוסתר.
  // בלי זה קורא מסך שומע דף ריק. כאן מפעילים אותו מראש.
  SemanticsBinding.instance.ensureSemantics();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;
  double textScale = 1.0;
  String lang = 'he'; // 'he' או 'en'
  bool _showSplash = true; // מסך פתיחה
  String userName = 'עידן';

  @override
  void initState() {
    super.initState();
    // מסך הפתיחה מוצג *מעל* האפליקציה ולא במקומה, כך שהדשבורד נבנה
    // מיד ומתחיל למשוך נתונים במקביל. קודם הוא הוחלף בו, ולכן הבקשה
    // הראשונה לשרת יצאה רק אחרי שהספלאש נגמר.
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showSplash = false);
    });
    // אחרי הפריים הראשון, כי לפניו Flutter עוד לא כתב את הערכים שלו
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyDocumentLang(lang),
    );
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('finova_user_name');
    if (saved != null && saved.trim().isNotEmpty && mounted) {
      setState(() => userName = saved.trim());
    }
  }

  Future<void> setUserName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    setState(() => userName = clean);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('finova_user_name', clean);
  }

  void toggleTheme(bool isDark) {
    setState(() {
      isDarkMode = isDark;
    });
  }

  void setTextScale(double scale) {
    setState(() {
      textScale = scale;
    });
  }

  void setLang(String newLang) {
    setState(() {
      lang = newLang;
    });
    _applyDocumentLang(newLang);
  }

  /// מסנכרן את <html lang> / dir / title עם שפת האפליקציה. חייב לרוץ אחרי
  /// ש-Flutter סיים לאתחל, אחרת הוא דורס את הערכים בחזרה.
  void _applyDocumentLang(String l) {
    try {
      _jsApplyLang(l.toJS);
    } catch (_) {
      // בסביבה שאין בה את הגשר (בדיקות) פשוט מדלגים
    }
  }

  /// Bridges the design tokens into Material's own theme, so the widgets that
  /// still read `Theme.of(context).cardColor` land on the same palette as the
  /// ones built from [FScheme].
  ThemeData _material(FScheme c) {
    final base = c.brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: c.bgApp,
      cardColor: c.bgSurface,
      primaryColor: c.brandViolet,
      dividerColor: c.hairline,
      canvasColor: c.bgElevated,
      iconTheme: IconThemeData(color: c.textPrimary),
      colorScheme: base.colorScheme.copyWith(
        primary: c.brandViolet,
        secondary: c.brandVioletBright,
        surface: c.bgSurface,
        error: c.accentRed,
      ),
      // ספרות ברוחב אחיד: המחיר מתעדכן כל 15 שניות, ובגופן רגיל
      // הרוחב משתנה עם הספרות והמספר "קופץ" בכל רענון
      textTheme: base.textTheme
          .apply(fontFamily: FType.family)
          .copyWith(
            bodyMedium: FType.body.copyWith(color: c.textPrimary),
            bodySmall: FType.caption.copyWith(color: c.textSecondary),
          ),
      // מחוון פוקוס גלוי - דרישה של רמה AA (קריטריון 2.4.7). ברירת המחדל
      // של Flutter על רקע כמעט-שחור כמעט לא נראית. הטבעת עצמה מצוירת
      // ב-PressScale, שדרכו עוברות כל הלחיצות באפליקציה.
      focusColor: c.brandVioletBright.withValues(alpha: 0.25),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = isDarkMode ? FScheme.dark : FScheme.light;
    return FTheme(
      scheme: scheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: lang == 'he'
            ? 'Finova - ניתוח מניות חכם'
            : 'Finova - smart stock research',
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: _material(FScheme.light),
        darkTheme: _material(FScheme.dark),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            // RTL היא ברירת המחדל של האפליקציה, ברמת השורש ולא פר-מסך.
            // קודם כל מסך הגדיר Directionality משלו (או לא הגדיר בכלל),
            // ולכן חלק מהמסכים יישרו שמאלה גם בעברית.
            child: Directionality(
              textDirection: lang == 'he'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: FTheme(scheme: scheme, child: child!),
            ),
          );
        },
        home: Stack(
          children: [
            DashboardScreen(
              onThemeChanged: toggleTheme,
              isDarkMode: isDarkMode,
              onTextScaleChanged: setTextScale,
              textScale: textScale,
              lang: lang,
              onLangChanged: setLang,
              userName: userName,
              onUserNameChanged: setUserName,
            ),
            // דהייה החוצה במקום היעלמות פתאומית
            IgnorePointer(
              ignoring: !_showSplash,
              child: AnimatedOpacity(
                opacity: _showSplash ? 1 : 0,
                duration: const Duration(milliseconds: 450),
                child: const SplashScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;
  final Function(double) onTextScaleChanged;
  final double textScale;
  final String lang;
  final Function(String) onLangChanged;
  final String userName;
  final Function(String) onUserNameChanged;

  const DashboardScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
    required this.onTextScaleChanged,
    required this.textScale,
    required this.lang,
    required this.onLangChanged,
    required this.userName,
    required this.onUserNameChanged,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // קיצור לתרגום
  String tr(String key) => T.get(key, widget.lang);

  /// אחוז שינוי חתום. הלוגיקה עצמה חיה ב-logic/formatting.dart ונבדקת שם
  /// ביחידה - כאן רק קריאה אליה.
  static String _pct(num value, {int digits = 2}) =>
      fmt.pctString(value, digits: digits);

  /// כתובת הלוגו של החברה, דרך הפרוקסי שלנו (ראה /api/logo בשרת).
  /// מוחזר null כשידוע לנו שאין לוגו, כדי לא לשלוח בקשה שתיכשל.
  String? _logoUrl(String ticker) {
    final t = ticker.trim().toUpperCase();
    if (t.isEmpty) return null;
    if (_tickersWithoutLogo.contains(t)) return null;
    return '$_apiBase/api/logo/$t';
  }

  /// טיקרים שהשרת כבר אמר עליהם שאין להם לוגו
  final Set<String> _tickersWithoutLogo = {};

  // ── הטאבים בניווט התחתון, בסדר שבו הם מופיעים משמאל לימין ──
  static const int _tabHome = 0;
  static const int _tabMarket = 1;
  static const int _tabSearch = 2;
  static const int _tabWatchlist = 3;
  static const int _tabMore = 4;

  int _selectedIndex = _tabHome;
  bool _headerScrolled = false;

  /// מאיפה הגענו לטאב הנוכחי. "קרא ניתוח מלא" מקפיץ למסך החיפוש, וצריכה
  /// להיות דרך חזרה - גם בכפתור בהדר וגם בכפתור החזרה של המכשיר.
  final List<int> _tabHistory = [];

  /// ציוני Finova שכבר ראינו, לפי טיקר. נשמר בין הפעלות כדי שהתג בכרטיס
  /// הראשי יוכל לטעון "הזדמנות מובילה" רק כשזו באמת המובילה מבין הידועים.
  Map<String, int> _knownScores = {};

  /// מניות שהמשתמש בחר לעקוב אחריהן. עד היום "מעקב" היה רק התראות מחיר,
  /// כלומר כדי לעקוב אחרי מניה היה צריך להמציא לה מחיר יעד.
  List<String> _watchlist = [];

  /// מתי חזר הניתוח האחרון - ממנו נגזר "עודכן לפני X דקות" בכרטיס הראשי
  DateTime? _analysisFetchedAt;

  /// מתעדכן כל דקה כדי שהכיתוב "עודכן לפני..." לא יקפא
  Timer? _freshnessTimer;

  final ScrollController _homeScroll = ScrollController();
  final PageController _oppsPage = PageController(viewportFraction: 0.36);
  int _oppsPageIndex = 0;

  String symbol = "NVDA";
  String exchange = "";
  int? _chartTouchIndex;

  // שינוי יומי לצ'יפים של המניות הפופולריות, כדי שהשורה תהיה מידע
  // ולא רק קיצורי דרך. משתמש באותו endpoint של "המניות שלי".
  Map<String, double> _popularChanges = {};

  Future<void> _fetchPopularChanges() async {
    try {
      final res = await http
          .post(
            Uri.parse('$_apiBase/api/movers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'tickers': popularTickers}),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted || res.statusCode != 200) return;
      final map = <String, double>{};
      final missing = <String>{};
      for (final raw in (jsonDecode(res.body) as List)) {
        final m = Map<String, dynamic>.from(raw);
        final t = m['ticker']?.toString();
        final c = (m['change'] as num?)?.toDouble();
        if (t != null && c != null) map[t] = c;
        if (t != null && (m['logo']?.toString() ?? '').isEmpty) missing.add(t);
      }
      setState(() {
        _popularChanges = map;
        _tickersWithoutLogo.addAll(missing);
      });
    } catch (_) {}
  }

  // האם כבר יש מחיר להצגה (מגיע מהר, לפני שניתוח ה-AI מסתיים)
  bool hasQuickQuote = false;
  int _loadingStage = 0;
  Timer? _loadingStageTimer;
  int _activeRequestId = 0;
  String currentPrice = "...";
  Timer? _priceTimer;

  double? dailyChange;
  List<double>? chartPrices;

  bool isLoading = false;
  bool isNotFound = false;
  bool isUnknownSymbol = false;
  String _lastAttemptedTicker = "NVDA";
  Map<String, dynamic>? analysisData;
  Map<String, dynamic>? finovaScore;

  // חיפוש עם השלמה אוטומטית
  List<Map<String, dynamic>> searchSuggestions = [];
  bool isSearching = false;
  Timer? _searchDebounce;

  // Daily Brief state
  Map<String, dynamic>? dailyBriefData;
  bool isBriefLoading = false;
  bool briefError = false;

  // "המניות שלי" בסיכום היומי - נבנה מהטיקרים שיש עליהם התראות
  List<Map<String, dynamic>> _myMovers = [];
  List<Map<String, dynamic>> _briefArchive = [];

  Future<void> _fetchMyMovers() async {
    final tickers = _priceAlerts
        .map((a) => (a['ticker'] as String?)?.trim().toUpperCase())
        .whereType<String>()
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    if (tickers.isEmpty) {
      if (mounted && _myMovers.isNotEmpty) setState(() => _myMovers = []);
      return;
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_apiBase/api/movers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'tickers': tickers}),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted || res.statusCode != 200) return;
      final list = (jsonDecode(res.body) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() => _myMovers = list);
    } catch (_) {}
  }

  Future<void> _fetchBriefArchive() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_apiBase/api/daily-brief/archive?lang=${widget.lang}'),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted || res.statusCode != 200) return;
      final list = (jsonDecode(res.body) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() => _briefArchive = list);
    } catch (_) {}
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) _showSnack(tr('connectionError'));
      }
    } catch (_) {
      if (mounted) _showSnack(tr('connectionError'));
    }
  }

  final List<String> popularTickers = [
    'NVDA',
    'AAPL',
    'MSFT',
    'PLTR',
    'UBER',
    'TSLA',
  ];

  // מצב פאנל הניהול ומפתחות ה-API חי עכשיו ב-AdminPage בלבד, כדי שטוקן
  // סשן ומפתחות לא ישבו ב-state של המסך שכל משתמש רואה.

  static const String _apiBase = 'https://finovam.ddns.net';

  // ── Price alerts state ──
  List<Map<String, dynamic>> _priceAlerts = [];
  Timer? _alertsCheckTimer;
  final TextEditingController _alertTickerController = TextEditingController();
  final TextEditingController _alertPriceController = TextEditingController();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.userName,
  );
  String _alertCondition = 'above';
  bool _alertsBusy = false;

  Future<void> _loadKnownScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('finova_scores');
    if (raw == null || !mounted) return;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw));
      setState(() {
        _knownScores = map.map((k, v) => MapEntry(k, (v as num).toInt()));
      });
    } catch (_) {}
  }

  Future<void> _rememberScore(String ticker, int score) async {
    setState(() => _knownScores[ticker] = score);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('finova_scores', jsonEncode(_knownScores));
  }

  /// האם המניה המוצגת היא באמת בעלת הציון הגבוה מבין אלה שאנחנו מכירים.
  /// דורש לפחות שתי מניות ידועות - "המובילה" מתוך אחת היא חסרת משמעות.
  bool get _isTopScorer {
    final current = _knownScores[symbol];
    if (current == null || _knownScores.length < 2) return false;
    return _knownScores.values.every((v) => v <= current);
  }

  Future<void> _loadWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('finova_watchlist');
    if (list == null || !mounted) return;
    setState(() => _watchlist = list);
    unawaited(_fetchWatchlistMovers());
  }

  Future<void> _saveWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('finova_watchlist', _watchlist);
  }

  bool get _isFollowingCurrent => _watchlist.contains(symbol);

  Future<void> _toggleFollow(String ticker) async {
    final t = ticker.trim().toUpperCase();
    if (t.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_watchlist.contains(t)) {
        _watchlist.remove(t);
      } else {
        _watchlist.insert(0, t);
      }
    });
    await _saveWatchlist();
    unawaited(_fetchWatchlistMovers());
  }

  /// שינוי יומי לכל מניה ברשימת המעקב, דרך אותו endpoint של המובילות
  Map<String, double> _watchlistChanges = {};

  Future<void> _fetchWatchlistMovers() async {
    if (_watchlist.isEmpty) {
      if (mounted && _watchlistChanges.isNotEmpty) {
        setState(() => _watchlistChanges = {});
      }
      return;
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_apiBase/api/movers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'tickers': _watchlist}),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted || res.statusCode != 200) return;
      final map = <String, double>{};
      final missing = <String>{};
      for (final raw in (jsonDecode(res.body) as List)) {
        final m = Map<String, dynamic>.from(raw);
        final t = m['ticker']?.toString();
        final c = (m['change'] as num?)?.toDouble();
        if (t != null && c != null) map[t] = c;
        if (t != null && (m['logo']?.toString() ?? '').isEmpty) missing.add(t);
      }
      setState(() {
        _watchlistChanges = map;
        _tickersWithoutLogo.addAll(missing);
      });
    } catch (_) {}
  }

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('finova_price_alerts');
    if (raw == null) return;
    try {
      final decoded = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (mounted) setState(() => _priceAlerts = decoded);
    } catch (_) {}
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('finova_price_alerts', jsonEncode(_priceAlerts));
    // מסנכרנים לשרת כדי שההתראות יעבדו גם כשהאפליקציה סגורה
    unawaited(_syncAlertsToServer());
  }

  // ── התראות דחיפה (Web Push) ──
  bool _pushSupported = false;
  bool _pushEnabled = false;
  bool _pushBusy = false;
  String? _pushEndpoint;

  Future<void> _initPush() async {
    try {
      _pushSupported = _jsPushSupported();
    } catch (_) {
      _pushSupported = false;
    }
    if (!_pushSupported) {
      if (mounted) setState(() {});
      return;
    }
    try {
      // אם המשתמש כבר אישר בעבר - מתחברים בשקט, בלי לבקש הרשאה שוב
      final raw = (await _jsPushCurrent().toDart).toDart;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final endpoint = data['endpoint'] as String?;
      if (endpoint != null && endpoint.isNotEmpty) {
        _pushEndpoint = endpoint;
        _pushEnabled = true;
        // מושכים מהשרת אילו התראות כבר הופעלו בזמן שהאפליקציה הייתה סגורה
        unawaited(_pullServerAlertState());
        await _registerSubscription(data);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _enablePush() async {
    if (_pushBusy) return;
    setState(() => _pushBusy = true);
    try {
      final keyRes = await http
          .get(Uri.parse('$_apiBase/api/push/key'))
          .timeout(const Duration(seconds: 15));
      if (keyRes.statusCode != 200) throw Exception('no key');
      final publicKey = (jsonDecode(keyRes.body)['publicKey'] as String?) ?? '';
      if (publicKey.isEmpty) throw Exception('empty key');

      final raw = (await _jsPushSubscribe(publicKey.toJS).toDart).toDart;
      final data = jsonDecode(raw) as Map<String, dynamic>;

      if (data['error'] != null) {
        if (!mounted) return;
        final err = data['error'].toString();
        _showSnack(err == 'denied' ? tr('pushDenied') : tr('pushFailed'));
        return;
      }

      await _registerSubscription(data);
      if (!mounted) return;
      setState(() {
        _pushEndpoint = data['endpoint'] as String?;
        _pushEnabled = true;
      });
      await _syncAlertsToServer();
      if (mounted) _showSnack(tr('pushEnabled'));
    } catch (_) {
      if (mounted) _showSnack(tr('pushFailed'));
    } finally {
      if (mounted) setState(() => _pushBusy = false);
    }
  }

  Future<void> _disablePush() async {
    if (_pushBusy) return;
    setState(() => _pushBusy = true);
    try {
      final endpoint = _pushEndpoint;
      await _jsPushUnsubscribe().toDart;
      if (endpoint != null) {
        await http
            .post(
              Uri.parse('$_apiBase/api/push/unsubscribe'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'endpoint': endpoint}),
            )
            .timeout(const Duration(seconds: 15));
      }
      if (!mounted) return;
      setState(() {
        _pushEnabled = false;
        _pushEndpoint = null;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _pushBusy = false);
    }
  }

  Future<void> _registerSubscription(Map<String, dynamic> data) async {
    try {
      await http
          .post(
            Uri.parse('$_apiBase/api/push/subscribe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'endpoint': data['endpoint'],
              'p256dh': data['p256dh'],
              'auth': data['auth'],
              'lang': widget.lang,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  // השרת יודע על הפעלות שקרו כשהאפליקציה הייתה סגורה - מיישרים לפיו,
  // אחרת המשתמש יראה "פעיל" על התראה שכבר נשלחה
  Future<void> _pullServerAlertState() async {
    final endpoint = _pushEndpoint;
    if (endpoint == null) return;
    try {
      final res = await http
          .post(
            Uri.parse('$_apiBase/api/push/alerts/list'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'endpoint': endpoint}),
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted || res.statusCode != 200) return;

      final serverAlerts = (jsonDecode(res.body) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final triggeredIds = {
        for (final a in serverAlerts)
          if (a['triggered'] == true) a['id'] as String: a['lastPrice'],
      };
      if (triggeredIds.isEmpty) return;

      var changed = false;
      for (final local in _priceAlerts) {
        final id = local['id'];
        if (id != null &&
            triggeredIds.containsKey(id) &&
            local['triggered'] != true) {
          local['triggered'] = true;
          local['lastPrice'] = triggeredIds[id];
          changed = true;
        }
      }
      if (changed) {
        setState(() {});
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('finova_price_alerts', jsonEncode(_priceAlerts));
      }
    } catch (_) {}
  }

  Future<void> _syncAlertsToServer() async {
    final endpoint = _pushEndpoint;
    if (endpoint == null || !_pushEnabled) return;
    try {
      await http
          .post(
            Uri.parse('$_apiBase/api/push/alerts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'endpoint': endpoint,
              'alerts': _priceAlerts
                  .map(
                    (a) => {
                      'id': a['id'],
                      'ticker': a['ticker'],
                      'condition': a['condition'],
                      'target': a['target'],
                      'triggered': a['triggered'] == true,
                      'lang': widget.lang,
                    },
                  )
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  void _addAlert() {
    final ticker = _alertTickerController.text.trim().toUpperCase();
    final target = double.tryParse(_alertPriceController.text.trim());
    if (ticker.isEmpty || target == null || target <= 0) return;

    HapticFeedback.lightImpact();
    setState(() {
      _priceAlerts.insert(0, {
        // מזהה יציב כדי שהשרת יוכל לסמן התראה כ"הופעלה"
        'id': DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        'ticker': ticker,
        'condition': _alertCondition,
        'target': target,
        'triggered': false,
        'lastPrice': null,
      });
      _alertTickerController.clear();
      _alertPriceController.clear();
    });
    _saveAlerts();
  }

  void _removeAlert(int index) {
    HapticFeedback.lightImpact();
    setState(() => _priceAlerts.removeAt(index));
    _saveAlerts();
  }

  Future<void> _checkAlerts() async {
    if (_priceAlerts.isEmpty || _alertsBusy) return;
    _alertsBusy = true;
    try {
      final activeTickers = _priceAlerts
          .where((a) => a['triggered'] != true)
          .map((a) => a['ticker'] as String)
          .toSet();

      final prices = <String, double>{};
      for (final ticker in activeTickers) {
        try {
          final res = await http
              .get(
                Uri.parse('$_apiBase/api/quote/${Uri.encodeComponent(ticker)}'),
              )
              .timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final price = (data['price'] as num?)?.toDouble() ?? 0;
            if (price > 0) prices[ticker] = price;
          }
        } catch (_) {}
      }
      if (prices.isEmpty || !mounted) return;

      String? firstTriggerMessage;
      setState(() {
        for (final alert in _priceAlerts) {
          if (alert['triggered'] == true) continue;
          final price = prices[alert['ticker']];
          if (price == null) continue;
          alert['lastPrice'] = price;
          final target = (alert['target'] as num).toDouble();
          final hit = alert['condition'] == 'above'
              ? price >= target
              : price <= target;
          if (hit) {
            alert['triggered'] = true;
            firstTriggerMessage ??=
                '${alert['ticker']} ${alert['condition'] == 'above' ? tr('crossedAbove') : tr('crossedBelow')} \$${target.toStringAsFixed(2)} — now \$${price.toStringAsFixed(2)}';
          }
        }
      });
      await _saveAlerts();

      if (firstTriggerMessage != null && mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(firstTriggerMessage!),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      _alertsBusy = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchStockData(symbol);
    // עדכון מחיר בזמן אמת כל 15 שניות
    _priceTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      // הבית והחיפוש שניהם מציגים מחיר חי, ולכן שניהם מצדיקים רענון
      final onLiveTab =
          _selectedIndex == _tabHome || _selectedIndex == _tabSearch;
      if (analysisData != null && !isLoading && onLiveTab) {
        _refreshPrice(symbol);
        _fetchPopularChanges();
      }
    });

    // "עודכן לפני X דקות" חייב לזוז בלי שהמשתמש יעשה כלום
    _freshnessTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _analysisFetchedAt != null) setState(() {});
    });

    // ההתראות המקומיות חייבות להיטען לפני שמושכים מהשרת אילו כבר הופעלו
    _loadAlerts().then((_) => _initPush());
    _loadKnownScores();
    _loadWatchlist();
    _fetchPopularChanges();
    _alertsCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _checkAlerts(),
    );
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // אם השפה השתנתה - מנקים מטמון ומושכים מחדש בשפה החדשה
    if (oldWidget.lang != widget.lang) {
      dailyBriefData = null;
      if (analysisData != null) {
        fetchStockData(symbol);
      }
      if (_selectedIndex == _tabMarket) {
        fetchDailyBrief();
      }
    }
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _searchDebounce?.cancel();
    _alertsCheckTimer?.cancel();
    _loadingStageTimer?.cancel();
    _freshnessTimer?.cancel();
    _homeScroll.dispose();
    _oppsPage.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _alertTickerController.dispose();
    _alertPriceController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> fetchStockData(String ticker) async {
    if (ticker.isEmpty) return;
    final upper = ticker.trim().toUpperCase();
    _lastAttemptedTicker = ticker;

    // מזהה ייחודי לבקשה - כדי שתשובה של חיפוש ישן לא תדרוס חיפוש חדש יותר
    final int requestId = ++_activeRequestId;

    setState(() {
      isLoading = true;
      isNotFound = false;
      isUnknownSymbol = false;
      dailyChange = null;
      chartPrices = null;
      hasQuickQuote = false;
      analysisData = null;
      finovaScore = null;
      symbol = upper;
      exchange = '';
      currentPrice = '...';
      _loadingStage = 0;
    });
    _startLoadingStages();

    // שלב 1 - מחיר מהיר (קריאה קלילה, חוזרת תוך פחות משנייה)
    // רץ במקביל לניתוח המלא כדי שהמשתמש יראה מחיר מיד
    unawaited(_fetchQuickQuote(upper, requestId));

    // שלב 2 - הניתוח המלא
    final url = Uri.parse('$_apiBase/api/analyze/$upper?lang=${widget.lang}');

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 120));
      if (!mounted || requestId != _activeRequestId) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          symbol = data['symbol'];
          exchange = (data['exchange'] as String?)?.trim() ?? '';
          if (((data['logo'] as String?) ?? '').isEmpty) {
            _tickersWithoutLogo.add(data['symbol'].toString());
          } else {
            _tickersWithoutLogo.remove(data['symbol'].toString());
          }
          currentPrice = '\$${data['currentPrice']}';
          dailyChange = data['dailyChange'] != null
              ? (data['dailyChange'] as num).toDouble()
              : null;
          if (data['chartData'] != null) {
            chartPrices = (data['chartData'] as List)
                .map((e) => (e as num).toDouble())
                .toList();
          }
          analysisData = data['analysis'] != null
              ? Map<String, dynamic>.from(data['analysis'])
              : null;
          finovaScore = data['finovaScore'] != null
              ? Map<String, dynamic>.from(data['finovaScore'])
              : null;
          hasQuickQuote = true;
          isLoading = false;
          _analysisFetchedAt = DateTime.now();
        });
        final total = (finovaScore?['total'] as num?)?.toInt();
        if (total != null) unawaited(_rememberScore(symbol, total));
      } else {
        setState(() {
          isLoading = false;
          isNotFound = true;
          // 404 = הסימבול באמת לא קיים. כל שאר הכשלים חולפים, ולהם
          // מתאים "נסה שוב" ולא "המנייה לא קיימת".
          isUnknownSymbol = response.statusCode == 404;
          analysisData = null;
          finovaScore = null;
        });
      }
    } catch (e) {
      if (!mounted || requestId != _activeRequestId) return;
      setState(() {
        isLoading = false;
        isNotFound = true;
        isUnknownSymbol = false;
      });
    } finally {
      _loadingStageTimer?.cancel();
    }
  }

  // מחיר בלבד - כדי להציג משהו אמיתי תוך פחות משנייה במקום מסך ריק
  Future<void> _fetchQuickQuote(String upper, int requestId) async {
    try {
      final res = await http
          .get(Uri.parse('$_apiBase/api/quote/$upper'))
          .timeout(const Duration(seconds: 12));
      if (!mounted || requestId != _activeRequestId) return;
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      if (price <= 0) return;
      // אם הניתוח המלא כבר חזר בינתיים - לא דורסים אותו
      if (analysisData != null) return;
      setState(() {
        currentPrice = '\$$price';
        dailyChange = (data['dailyChange'] as num?)?.toDouble();
        hasQuickQuote = true;
      });
    } catch (_) {}
  }

  // מקדם את טקסט הסטטוס בזמן ההמתנה, כדי שלא יהיה ספינר אילם
  void _startLoadingStages() {
    _loadingStageTimer?.cancel();
    const steps = [2, 5, 9]; // שניות עד כל שלב
    var i = 0;
    _loadingStageTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      i++;
      if (!mounted) {
        t.cancel();
        return;
      }
      final stage = steps.where((s) => i >= s).length;
      if (stage != _loadingStage) setState(() => _loadingStage = stage);
      if (stage >= steps.length) t.cancel();
    });
  }

  // עדכון מחיר בלבד בזמן אמת - בלי לטעון מחדש את כל הניתוח
  // חיפוש עם השלמה אוטומטית - עם השהיה כדי לא להציף בקריאות
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => searchSuggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(query.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => isSearching = true);
    final url = Uri.parse(
      'https://finovam.ddns.net/api/search/${Uri.encodeComponent(query)}',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            searchSuggestions = data
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
                .take(8)
                .toList();
            isSearching = false;
          });
        }
      } else {
        if (mounted) setState(() => isSearching = false);
      }
    } catch (e) {
      if (mounted) setState(() => isSearching = false);
    }
  }

  void _selectSuggestion(String ticker) {
    HapticFeedback.selectionClick();
    _searchController.clear();
    setState(() => searchSuggestions = []);
    FocusScope.of(context).unfocus();
    fetchStockData(ticker);
  }

  Future<void> _refreshPrice(String ticker) async {
    // endpoint קליל (קריאה חיצונית אחת) במקום הניתוח המלא -
    // רענון כל 15 שניות דרך /api/analyze שרף 4 קריאות API בכל פעם
    final url = Uri.parse('$_apiBase/api/quote/${ticker.trim().toUpperCase()}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        if (price <= 0) return;
        if (mounted) {
          setState(() {
            currentPrice = '\$$price';
            dailyChange =
                (data['dailyChange'] as num?)?.toDouble() ?? dailyChange;
          });
        }
      }
    } catch (e) {
      // מתעלמים משגיאה בעדכון אוטומטי - לא מפריעים למשתמש
    }
  }

  Future<void> fetchDailyBrief() async {
    if (dailyBriefData != null) return; // כבר נטען
    setState(() {
      isBriefLoading = true;
      briefError = false;
    });

    final url = Uri.parse(
      'https://finovam.ddns.net/api/daily-brief?lang=${widget.lang}',
    );

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 120));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          dailyBriefData = json.decode(response.body);
          isBriefLoading = false;
        });
        // המניות של המשתמש והארכיון נטענים אחרי הסיכום, בלי לעכב אותו
        unawaited(_fetchMyMovers());
        unawaited(_fetchBriefArchive());
      } else {
        setState(() {
          isBriefLoading = false;
          briefError = true;
        });
      }
    } catch (e) {
      setState(() {
        isBriefLoading = false;
        briefError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final scaffold = Scaffold(
      backgroundColor: c.bgApp,
      // extendBody מאפשר לתוכן לגלול מתחת לניווט המרחף
      extendBody: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                // הרקע המטושטש של ההדר מופיע רק אחרי שהתחילה גלילה
                final scrolled = n.metrics.pixels > 4;
                if (scrolled != _headerScrolled) {
                  setState(() => _headerScrolled = scrolled);
                }
                return false;
              },
              child: _buildBody(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );

    // כפתור החזרה של המכשיר סוגר קודם את הדריל-דאון, ורק אחר כך יוצא
    final guarded = PopScope(
      canPop: _tabHistory.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: scaffold,
    );

    // במסך רחב (מחשב): הפריסה תמיד מרונדרת באותן מידות לוגיות (430x860), ואז
    // מוגדלת/מוקטנת כיחידה אחת (FittedBox) כדי למלא את גובה החלון שיש בפועל.
    // ככה זה מתאים את עצמו לכל מסך ורזולוציה - גדול במסך גדול, קטן במסך קטן -
    // אבל הפרופורציות והפריסה הפנימית זהות לחלוטין בכל מחשב.
    return LayoutBuilder(
      builder: (context, constraints) {
        const double breakpoint = 700;
        const double frameWidth = 430;
        const double frameHeight = 860;
        if (constraints.maxWidth <= breakpoint) return guarded;

        return ColoredBox(
          color: widget.isDarkMode
              ? const Color(0xFF0b0b0f)
              : const Color(0xFFE4E7EE),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: frameWidth,
                  height: frameHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: guarded,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case _tabMarket:
        return _buildDailyBriefScreen();
      case _tabSearch:
        return _buildDashboardContent();
      case _tabWatchlist:
        return _buildAlertsScreen();
      case _tabMore:
        return _buildSettingsScreen();
      default:
        return _buildHomeScreen();
    }
  }

  void _goToTab(int index, {bool remember = false}) {
    if (index == _selectedIndex) return;
    setState(() {
      // ניווט מהניווט התחתון מאפס את ההיסטוריה: זה מעבר בין מדורים,
      // לא כניסה פנימה. רק דריל-דאון (כרטיס, "קרא ניתוח מלא") נזכר.
      if (remember) {
        _tabHistory.add(_selectedIndex);
      } else {
        _tabHistory.clear();
      }
      _selectedIndex = index;
      _headerScrolled = false;
    });
    if (index == _tabMarket) fetchDailyBrief(); // טעינת הסיכום בלחיצה
  }

  /// חזרה לטאב שממנו נכנסנו. מחזיר false אם אין לאן לחזור.
  bool _goBack() {
    if (_tabHistory.isEmpty) return false;
    setState(() {
      _selectedIndex = _tabHistory.removeLast();
      _headerScrolled = false;
    });
    return true;
  }

  // ───────────────────────────────────────────
  // הדר עליון קבוע - לוגו, פעמון, אווטאר
  // ───────────────────────────────────────────
  Widget _buildHeader() {
    final c = context.c;
    final topInset = MediaQuery.of(context).viewPadding.top;

    return AnimatedContainer(
      duration: FMotion.respect(context, FMotion.tab),
      padding: EdgeInsets.only(top: topInset),
      decoration: BoxDecoration(
        color: _headerScrolled ? c.bgApp.withValues(alpha: 0.8) : c.bgApp,
        border: Border(
          bottom: BorderSide(
            color: _headerScrolled ? c.hairline : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: _headerScrolled
              ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: SizedBox(
            height: FSpace.headerHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FSpace.screen),
              // הלוגו נשאר בפינה השמאלית העליונה גם ב-RTL, והפעמון והאווטאר
              // מימין - ולכן ההדר כולו LTR, בדיוק כמו בעיצוב
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    // כשנכנסנו פנימה מכרטיס, הלוגו מפנה את מקומו לכפתור
                    // חזרה - זה המקום שהעין כבר מחפשת בו שליטה
                    if (_tabHistory.isNotEmpty)
                      _buildBackButton()
                    else
                      const Logo(markSize: 24),
                    const Spacer(),
                    _buildBellButton(),
                    const SizedBox(width: FSpace.md),
                    _buildAvatar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// חזרה למסך שממנו נכנסנו. יש גם תווית ולא רק חץ - חץ לבדו בפינה
  /// השמאלית של ממשק עברי הוא דו-משמעי.
  Widget _buildBackButton() {
    final c = context.c;
    return Semantics(
      button: true,
      label: tr('back'),
      child: PressScale(
        onTap: _goBack,
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
              Icon(Icons.arrow_back_rounded, size: 18, color: c.textPrimary),
              const SizedBox(width: 6),
              Text(
                tr('back'),
                style: FType.h3.copyWith(fontSize: 14, color: c.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBellButton() {
    final c = context.c;
    // הנקודה אמיתית: היא מופיעה רק אם באמת יש התראה שהופעלה ולא נצפתה
    final hasUnread = _priceAlerts.any((a) => a['triggered'] == true);

    return Semantics(
      button: true,
      label: tr('notificationsAria'),
      child: PressScale(
        onTap: () => _goToTab(_tabWatchlist),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.bgSurface2,
                  shape: BoxShape.circle,
                  border: FBorder.subtle(c),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: c.textPrimary,
                ),
              ),
              if (hasUnread)
                PositionedDirectional(
                  top: 4,
                  end: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.brandVioletBright,
                      shape: BoxShape.circle,
                      // טבעת בצבע הרקע כדי שהנקודה תיקרא גם על האייקון
                      border: Border.all(color: c.bgApp, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = _initialsOf(widget.userName);
    return Semantics(
      button: true,
      label: tr('profileAria'),
      child: PressScale(
        onTap: () => _goToTab(_tabMore),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: FGrad.brand,
            shape: BoxShape.circle,
          ),
          child: Text(initials, style: FType.h3.copyWith(color: Colors.white)),
        ),
      ),
    );
  }

  String _initialsOf(String name) => fmt.initialsOf(name);

  // ───────────────────────────────────────────
  // ניווט תחתון - 5 פריטים
  // ───────────────────────────────────────────
  Widget _buildBottomNav() {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.bgNav,
        border: Border(top: BorderSide(color: c.hairline, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: FSpace.navHeight,
          // הסדר משמאל לימין כמו בעיצוב, ולכן הניווט תמיד LTR
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                _buildNavItem(
                  Icons.home_rounded,
                  Icons.home_outlined,
                  tr('tabHome'),
                  _tabHome,
                ),
                _buildNavItem(
                  Icons.pie_chart_rounded,
                  Icons.pie_chart_outline,
                  tr('tabMarket'),
                  _tabMarket,
                ),
                _buildNavItem(
                  Icons.search_rounded,
                  Icons.search_rounded,
                  tr('tabSearch'),
                  _tabSearch,
                ),
                _buildNavItem(
                  Icons.bookmark_rounded,
                  Icons.bookmark_border_rounded,
                  tr('tabWatchlist'),
                  _tabWatchlist,
                ),
                _buildNavItem(
                  Icons.menu_rounded,
                  Icons.menu_rounded,
                  tr('tabMore'),
                  _tabMore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
  ) {
    final c = context.c;
    final isSelected = _selectedIndex == index;
    final color = isSelected ? c.brandVioletBright : c.textTertiary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: PressScale(
          onTap: () => _goToTab(index),
          focusRadius: FRadius.pill,
          // אזור לחיצה מינימלי 44x44 מובטח ע"י גובה השורה והרוחב השווה
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: FMotion.respect(context, FMotion.tab),
                curve: Curves.easeOut,
                width: 60,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? c.brandViolet.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: FRadius.pillAll,
                ),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: FType.micro.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // מסך הבית
  //
  // הערה על כיוון: העמודה עצמה RTL (ברכה, כותרות סקשן, שורות פעולה), אבל
  // כרטיס ה-Hero והקרוסלה בנויים LTR - זה בדיוק מה שהרפרנס מראה: התג
  // בפינה השמאלית, הלוגו משמאל והטבעת מימין, והקרוסלה נחתכת בקצה הימני.
  // ═══════════════════════════════════════════
  Widget _buildHomeScreen() {
    return RefreshIndicator(
      color: context.c.brandVioletBright,
      backgroundColor: context.c.bgSurface,
      onRefresh: () async {
        await Future.wait([fetchStockData(symbol), _fetchPopularChanges()]);
      },
      child: ListView(
        controller: _homeScroll,
        padding: const EdgeInsets.fromLTRB(
          FSpace.screen,
          0,
          FSpace.screen,
          FSpace.scrollBottom,
        ),
        children: [
          EnterIn(index: 0, child: _buildGreeting()),
          EnterIn(index: 1, child: _buildHomeSearch()),
          if (searchSuggestions.isNotEmpty) _buildSuggestionsList(),
          const SizedBox(height: FSpace.lg),
          EnterIn(index: 2, child: _buildHeroCard()),
          const SizedBox(height: FSpace.xxl),
          EnterIn(index: 3, child: _buildOpportunities()),
        ],
      ),
    );
  }

  String _greetingKey() {
    final h = DateTime.now().hour;
    if (h < 12) return 'greetMorning';
    if (h < 17) return 'greetNoon';
    return 'greetEvening';
  }

  Widget _buildGreeting() {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: FSpace.xxl, bottom: FSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${tr(_greetingKey())}, ${widget.userName} 👋',
            style: FType.h1.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: FSpace.xs),
          Text(
            tr('homeSubtitle'),
            style: FType.body.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeSearch() {
    final c = context.c;
    // זכוכית מגדלת בקצה השמאלי, סליידרים בקצה הימני - בדיוק כמו בעיצוב,
    // ולכן השורה עצמה LTR בזמן שהטקסט בתוכה נשאר בכיוון של השפה
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: FSpace.lg),
        decoration: BoxDecoration(
          color: c.bgInput,
          borderRadius: FRadius.lgAll,
          border: FBorder.card(c),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20, color: c.textTertiary),
            const SizedBox(width: FSpace.md),
            Expanded(
              child: TextField(
                controller: _searchController,
                textDirection: widget.lang == 'he'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                textAlign: widget.lang == 'he'
                    ? TextAlign.right
                    : TextAlign.left,
                style: FType.body.copyWith(color: c.textPrimary),
                cursorColor: c.brandVioletBright,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: tr('homeSearchHint'),
                  hintStyle: FType.body.copyWith(color: c.textTertiary),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    _goToTab(_tabSearch, remember: true);
                    _selectSuggestion(v.trim().toUpperCase());
                  }
                },
              ),
            ),
            const SizedBox(width: FSpace.sm),
            if (isSearching)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.brandVioletBright,
                ),
              )
            else
              Icon(Icons.tune_rounded, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
  }

  /// כמה זמן עבר מאז שהניתוח חזר מהשרת
  String _freshnessLabel() {
    final at = _analysisFetchedAt;
    if (at == null) return '';
    final mins = DateTime.now().difference(at).inMinutes;
    if (mins < 1) return tr('updatedJustNow');
    if (mins < 60) {
      return tr('updatedMinutesAgo').replaceAll('{n}', '$mins');
    }
    return tr('updatedHoursAgo').replaceAll('{n}', '${mins ~/ 60}');
  }

  /// חיובי / שלילי / ניטרלי לפי ההמלצה שחזרה מה-AI
  FTone _recTone() {
    final rec = (analysisData?['finalRecommendation'] ?? '')
        .toString()
        .toLowerCase();
    final verdict = (analysisData?['verdict'] ?? '').toString().toLowerCase();
    if (verdict.contains('bullish') || rec.contains('buy')) return FTone.green;
    if (verdict.contains('bearish') || rec.contains('sell')) return FTone.red;
    return FTone.amber;
  }

  IconData _recIcon(FTone tone) => switch (tone) {
    FTone.green => Icons.arrow_upward_rounded,
    FTone.red => Icons.arrow_downward_rounded,
    _ => Icons.remove_rounded,
  };

  Widget _buildHeroCard() {
    final c = context.c;

    if (isLoading || (analysisData == null && !isNotFound)) {
      return _buildHeroSkeleton();
    }
    if (analysisData == null || finovaScore == null) {
      return FCard(
        border: FBorder.hero(c),
        child: FEmptyState(
          icon: Icons.query_stats_rounded,
          message: tr('homeNoAnalysis'),
          actionLabel: tr('analyseNow'),
          onAction: () => _goToTab(_tabSearch, remember: true),
        ),
      );
    }

    final total = (finovaScore!['total'] ?? 0) as int;
    final rec = (analysisData!['finalRecommendation'] ?? '').toString();
    final confidence = (analysisData!['confidenceLevel'] ?? '').toString();
    final tone = _recTone();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: FCard(
        onTap: () {
          _goToTab(_tabSearch, remember: true);
        },
        padding: const EdgeInsets.all(FSpace.heroPad),
        gradient: FGrad.hero,
        border: FBorder.hero(c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // התג טוען "הזדמנות מובילה" רק כשזו באמת המניה עם הציון הגבוה
            // מבין אלה שניתחנו. אחרת הוא אומר בדיוק מה שהוא: הניתוח האחרון.
            FChip(
              label: _isTopScorer ? tr('topOpportunity') : tr('latestAnalysis'),
              tone: _isTopScorer ? FTone.green : FTone.neutral,
            ),
            const SizedBox(height: FSpace.lg),

            // ── שורת מניה + ציון ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TickerAvatar(ticker: symbol, logoUrl: _logoUrl(symbol)),
                const SizedBox(width: FSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: FType.h2.copyWith(color: c.textPrimary),
                      ),
                      Text(
                        exchange.isNotEmpty ? exchange : currentPrice,
                        style: FType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tr('aiScore'),
                      style: FType.caption.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: FSpace.xs),
                    ScoreRing(
                      score: total,
                      color: c.accentGreen,
                      semanticLabel: '${tr('aiScore')} $total ${_outOf100()}',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: FSpace.lg),

            // ── שורת המלצה ──
            Row(
              children: [
                Flexible(
                  child: FChip(
                    label: '${tr('aiRecShort')}: $rec',
                    tone: tone,
                    icon: _recIcon(tone),
                    large: true,
                    bordered: true,
                    onTap: _showRecommendationReason,
                  ),
                ),
                const SizedBox(width: FSpace.md),
                if (confidence.isNotEmpty && confidence != 'N/A')
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${tr('confidence')} $confidence',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FType.caption.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: FSpace.lg),

            // ── בלוק "למה?" ──
            Text(tr('whyQ'), style: FType.h3.copyWith(color: c.textPrimary)),
            const SizedBox(height: FSpace.sm),
            _buildWhyTiles(),

            FDivider(vertical: FSpace.md),

            // ── פוטר ──
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: c.textTertiary),
                const SizedBox(width: 5),
                Text(
                  _freshnessLabel(),
                  style: FType.caption.copyWith(color: c.textTertiary),
                ),
                const Spacer(),
                Text(
                  tr('readFullAnalysis'),
                  style: FType.h3.copyWith(fontSize: 14, color: c.link),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 15, color: c.link),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _outOf100() => widget.lang == 'he' ? 'מתוך 100' : 'out of 100';

  /// ארבע התיבות שמסבירות את הציון. נבנות מה-factors האמיתיים של הציון,
  /// והחזקים ביותר קודם - זה מה שמצדיק את ההמלצה.
  Widget _buildWhyTiles() {
    final c = context.c;
    final factors = (finovaScore?['factors'] as List?) ?? [];

    final good = factors
        .map((f) => Map<String, dynamic>.from(f as Map))
        .where((f) => (f['tone'] as String?) == 'good')
        .toList();
    // אם אין מספיק חיוביים, ממלאים בשאר כדי שהגריד לא ייראה שבור
    final rest = factors
        .map((f) => Map<String, dynamic>.from(f as Map))
        .where((f) => (f['tone'] as String?) != 'good')
        .toList();
    final picked = [...good, ...rest].take(4).toList();

    if (picked.isEmpty) {
      return Text(
        (analysisData?['recommendationReason'] ?? '').toString(),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: FType.caption.copyWith(color: c.textSecondary),
      );
    }

    // IntrinsicHeight כדי שארבע התיבות יהיו באותו גובה גם כשכותרת אחת
    // נשברת לשתי שורות - אחרת השורה נראית משוננת
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < picked.length; i++) ...[
            if (i > 0) const SizedBox(width: FSpace.sm),
            Expanded(child: _buildWhyTile(picked[i])),
          ],
        ],
      ),
    );
  }

  /// תת-הכותרת בתיבת "למה?" - הכי קצר שיש, כדי שלא ייחתך ברוחב רבע מסך
  String _shortFactorDetail(Map<String, dynamic> f) => fmt.shortFactorDetail(
    value: f['value']?.toString(),
    verdict: f['verdict']?.toString(),
  );

  Widget _buildWhyTile(Map<String, dynamic> f) {
    final c = context.c;
    final tone = (f['tone'] as String?) ?? 'neutral';
    final accent = switch (tone) {
      'good' => c.accentGreen,
      'bad' => c.accentRed,
      _ => c.textSecondary,
    };
    final icon = switch (tone) {
      'good' => Icons.trending_up_rounded,
      'bad' => Icons.trending_down_rounded,
      _ => Icons.remove_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(FSpace.md),
      decoration: BoxDecoration(
        color: c.bgSurface2,
        borderRadius: FRadius.mdAll,
        border: FBorder.subtle(c),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: accent),
          ),
          const SizedBox(height: FSpace.sm),
          Text(
            (f['metric'] ?? '').toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FType.micro.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            // הערך המספרי קצר ונכנס בשורה; ה-verdict המילולי כמעט תמיד
            // נחתך ברוחב של רבע מסך, אז הוא רק גיבוי
            _shortFactorDetail(f),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FType.micro.copyWith(
              color: c.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSkeleton() {
    final c = context.c;
    return FCard(
      padding: const EdgeInsets.all(FSpace.heroPad),
      border: FBorder.hero(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FSkeleton(width: 110, height: 22, radius: FRadius.pill),
          const SizedBox(height: FSpace.lg),
          Row(
            children: [
              const FSkeleton(width: 52, height: 52, radius: FRadius.sm),
              const SizedBox(width: FSpace.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FSkeleton(width: 90, height: 18),
                    SizedBox(height: 6),
                    FSkeleton(width: 60, height: 12),
                  ],
                ),
              ),
              const FSkeleton(width: 84, height: 84, radius: FRadius.pill),
            ],
          ),
          const SizedBox(height: FSpace.lg),
          const FSkeleton(width: 160, height: 34, radius: FRadius.sm),
          const SizedBox(height: FSpace.lg),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: i == 3 ? 0 : 8),
                  child: const FSkeleton(height: 74, radius: FRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── קרוסלת ההזדמנויות ──
  Widget _buildOpportunities() {
    final c = context.c;
    // מדורג לפי השינוי היומי בפועל, כדי ש"הזדמנויות היום" יהיו באמת של היום
    final tickers = [...popularTickers]
      ..sort((a, b) {
        final ca = _popularChanges[a] ?? -999;
        final cb = _popularChanges[b] ?? -999;
        return cb.compareTo(ca);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(text: tr('todayOpportunities'), leading: '🔥'),
        SizedBox(
          height: 78,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.maxScrollExtent > 0) {
                  final page =
                      (n.metrics.pixels /
                              n.metrics.maxScrollExtent *
                              (tickers.length - 1))
                          .round()
                          .clamp(0, tickers.length - 1);
                  if (page != _oppsPageIndex) {
                    setState(() => _oppsPageIndex = page);
                  }
                }
                return false;
              },
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: tickers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _buildOpportunityCard(tickers[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: FSpace.md),
        FDots(
          count: tickers.length,
          active: _oppsPageIndex.clamp(0, tickers.length - 1),
        ),
        if (_popularChanges.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: FSpace.sm),
            child: Text(
              tr('loadingHome'),
              style: FType.caption.copyWith(color: c.textTertiary),
            ),
          ),
      ],
    );
  }

  Widget _buildOpportunityCard(String ticker) {
    final c = context.c;
    final isActive = ticker == symbol;
    final change = _popularChanges[ticker];

    return SizedBox(
      width: 132,
      child: FCard(
        radius: FRadius.md,
        padding: const EdgeInsets.all(FSpace.md),
        border: isActive ? FBorder.active(c) : FBorder.card(c),
        shadow: isActive ? FShadow.violet(c) : null,
        onTap: () {
          _goToTab(_tabSearch, remember: true);
          _searchController.clear();
          fetchStockData(ticker);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                TickerAvatar(
                  ticker: ticker,
                  size: 22,
                  radius: 6,
                  logoUrl: _logoUrl(ticker),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticker,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FType.h3.copyWith(
                      fontSize: 14,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FSpace.sm),
            Row(
              children: [
                // לא "AI Score": ציון דורש ניתוח מלא לכל מניה, ומה שבאמת יש
                // כאן הוא השינוי היומי - שהוא גם מה שמדרג את הקרוסלה
                Text(
                  tr('dailyChangeShort'),
                  style: FType.caption.copyWith(color: c.textSecondary),
                ),
                const Spacer(),
                if (change != null)
                  Text(
                    _pct(change, digits: 1),
                    style: FType.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: change >= 0 ? c.accentGreen : c.accentRed,
                    ),
                  )
                else
                  const FSkeleton(width: 34, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// רשימת ההשלמות - משותפת למסך הבית ולמסך החיפוש
  Widget _buildSuggestionsList() {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgSurface,
          borderRadius: FRadius.mdAll,
          border: FBorder.card(c),
        ),
        child: Column(
          children: searchSuggestions.map((sug) {
            final ticker = sug['symbol']?.toString() ?? '';
            final name = sug['description']?.toString() ?? '';
            return PressScale(
              onTap: () {
                if (_selectedIndex == _tabHome) {
                  _goToTab(_tabSearch, remember: true);
                }
                _selectSuggestion(ticker);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FSpace.cardGap,
                  vertical: FSpace.md,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.brandViolet.withValues(alpha: 0.15),
                        borderRadius: FRadius.mdAll,
                      ),
                      child: Text(
                        ticker,
                        style: FType.ticker.copyWith(
                          fontWeight: FontWeight.w700,
                          color: c.brandVioletBright,
                        ),
                      ),
                    ),
                    const SizedBox(width: FSpace.md),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FType.caption.copyWith(color: c.textPrimary),
                      ),
                    ),
                    Icon(
                      Icons.north_west_rounded,
                      size: 14,
                      color: c.textTertiary,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final c = context.c;

    // ירוק/אדום כאן הם כיוון שוק, וזה השימוש שהם שמורים לו
    Color changeColor = c.accentGreen;
    Color changeBgColor = c.accentGreenDim;
    String changeText = '0.00%';

    if (dailyChange != null) {
      bool isPositive = dailyChange! >= 0;
      changeColor = isPositive ? c.accentGreen : c.accentRed;
      changeBgColor = isPositive ? c.accentGreenDim : c.accentRedDim;
      changeText = _pct(dailyChange!);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FSpace.screen,
            FSpace.lg,
            FSpace.screen,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // מוצג ברגע שיש מחיר (לא ממתין לניתוח ה-AI האיטי)
              if (analysisData != null || hasQuickQuote) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(FSpace.heroPad),
                  decoration: BoxDecoration(
                    color: c.bgSurface,
                    borderRadius: FRadius.lgAll,
                    gradient: FGrad.hero,
                    border: FBorder.hero(c),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TickerAvatar(
                            ticker: symbol,
                            size: 40,
                            logoUrl: _logoUrl(symbol),
                          ),
                          const SizedBox(width: FSpace.md),
                          Text(
                            symbol,
                            style: FType.h2.copyWith(color: c.textPrimary),
                          ),
                          const SizedBox(width: FSpace.sm),
                          // תווית הבורסה האמיתית מהשרת (מוסתרת אם לא ידועה,
                          // עדיף כלום מאשר להציג בורסה שגויה)
                          if (exchange.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: c.hairlineStrong,
                                borderRadius: FRadius.mdAll,
                              ),
                              child: Text(
                                exchange,
                                style: FType.micro.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          const Spacer(),
                          _buildFollowButton(),
                          const SizedBox(width: FSpace.sm),
                          // אינדיקטור LIVE עם נקודה פועמת
                          PulsingLiveDot(),
                        ],
                      ),
                      const SizedBox(height: FSpace.cardGap),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currentPrice,
                            style: FType.display.copyWith(
                              fontSize: 38,
                              color: c.textPrimary,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: FSpace.md),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: changeBgColor,
                                borderRadius: FRadius.mdAll,
                              ),
                              // חץ המגמה נקרא לפי הכיוון שבו הוא מצויר,
                              // ולכן הוא נשאר LTR: ב-RTL חץ עלייה מתהפך
                              // ונראה בדיוק כמו חץ ירידה
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      dailyChange != null && dailyChange! < 0
                                          ? Icons.trending_down_rounded
                                          : Icons.trending_up_rounded,
                                      color: changeColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      changeText,
                                      style: FType.h3.copyWith(
                                        fontSize: 14,
                                        color: changeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: FSpace.lg),
                      _buildMiniChart(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // שדה החיפוש - זהה לזה שבמסך הבית: זכוכית מגדלת בקצה
              // השמאלי, סליידרים בקצה הימני
              _buildHomeSearch(),
              // רשימת הצעות השלמה אוטומטית
              if (searchSuggestions.isNotEmpty) _buildSuggestionsList(),
              const SizedBox(height: FSpace.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: popularTickers.map((ticker) {
                    final isActive = ticker == symbol;
                    final chg = _popularChanges[ticker];
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: FSpace.sm),
                      child: PressScale(
                        onTap: () {
                          _searchController.clear();
                          fetchStockData(ticker);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: FSpace.cardGap,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? c.brandViolet.withValues(alpha: 0.15)
                                : c.bgSurface,
                            borderRadius: FRadius.pillAll,
                            border: isActive
                                ? FBorder.active(c)
                                : FBorder.card(c),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ticker,
                                style: FType.ticker.copyWith(
                                  color: isActive
                                      ? c.brandVioletBright
                                      : c.textSecondary,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              if (chg != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  _pct(chg, digits: 1),
                                  style: FType.micro.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: chg >= 0
                                        ? c.accentGreen
                                        : c.accentRed,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: FSpace.md),
              if (analysisData != null)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: c.bgSurface,
                    borderRadius: FRadius.mdAll,
                    border: FBorder.subtle(c),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: c.brandViolet.withValues(alpha: 0.15),
                      borderRadius: FRadius.mdAll,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: c.brandVioletBright,
                    unselectedLabelColor: c.textTertiary,
                    labelStyle: FType.micro.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: FType.micro,
                    dividerColor: Colors.transparent,
                    splashBorderRadius: FRadius.smAll,
                    tabs: [
                      Tab(text: tr('summary')),
                      Tab(text: tr('fundamentals')),
                      Tab(text: tr('catalysts')),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: FSpace.md),
        Expanded(
          // מעבר רך בין מצבים (טעינה / שגיאה / תוכן) במקום קפיצה חדה
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: isLoading
                ? _buildLoadingState()
                : isNotFound
                ? KeyedSubtree(
                    key: const ValueKey('notfound'),
                    child: _buildNotFound(),
                  )
                : analysisData == null
                ? Center(
                    key: const ValueKey('empty'),
                    child: FEmptyState(
                      icon: Icons.query_stats_rounded,
                      message: tr('searchToStart'),
                    ),
                  )
                : RefreshIndicator(
                    key: ValueKey('content_$symbol'),
                    color: context.c.brandVioletBright,
                    backgroundColor: context.c.bgSurface,
                    onRefresh: () => fetchStockData(symbol),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSummaryTab(),
                        _buildFundamentalsTab(),
                        _buildCatalystsTab(),
                      ],
                    ),
                  ),
          ),
        ),
        // שורת הקרדיט עברה למסך "עוד" - כאן היא נתקעה מתחת לניווט הקבוע
      ],
    );
  }

  Widget _buildFollowButton() {
    final c = context.c;
    final following = _isFollowingCurrent;
    return PressScale(
      semanticLabel: following ? tr('following') : tr('follow'),
      focusRadius: FRadius.pill,
      onTap: () => _toggleFollow(symbol),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: following ? c.brandViolet.withValues(alpha: 0.15) : c.hairline,
          borderRadius: FRadius.pillAll,
          border: following ? FBorder.active(c) : FBorder.subtle(c),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              following
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 14,
              color: following ? c.brandVioletBright : c.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              following ? tr('following') : tr('follow'),
              style: FType.micro.copyWith(
                color: following ? c.brandVioletBright : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart() {
    final hasData = chartPrices != null && chartPrices!.isNotEmpty;
    final up = (dailyChange ?? 0) >= 0;
    final lineColor = up ? context.c.accentGreen : context.c.accentRed;

    return LayoutBuilder(
      builder: (context, constraints) {
        // גרר/הקש כדי לקרוא את המחיר בנקודה מסוימת - הגרף היה תצוגה בלבד
        void updateFromPosition(double dx) {
          if (!hasData) return;
          final n = chartPrices!.length;
          if (n < 2) return;
          final ratio = (dx / constraints.maxWidth).clamp(0.0, 1.0);
          final idx = (ratio * (n - 1)).round().clamp(0, n - 1);
          if (idx != _chartTouchIndex) {
            HapticFeedback.selectionClick();
            setState(() => _chartTouchIndex = idx);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // המחיר בנקודה שנוגעים בה, מעל הגרף כדי שהאצבע לא תסתיר אותו
            SizedBox(
              height: 16,
              child: (_chartTouchIndex != null && hasData)
                  ? Row(
                      children: [
                        Text(
                          '\$${chartPrices![_chartTouchIndex!].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: lineColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${chartPrices!.length - 1 - _chartTouchIndex!}${widget.lang == 'he' ? ' ימים אחורה' : 'd ago'}',
                          style: FType.micro.copyWith(
                            fontWeight: FontWeight.w400,
                            color: context.c.textTertiary,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 4),
            // חלופה מקלדתית לגרירה: הגרף מקבל פוקוס, וחצים מזיזים את נקודת
            // הקריאה. בלי זה אי אפשר לקרוא מחיר בנקודה מסוימת בלי עכבר או
            // אצבע - וזו הייתה מגבלה מוצהרת בהצהרת הנגישות.
            Focus(
              onKeyEvent: (node, event) {
                if (!hasData || event is KeyUpEvent) {
                  return KeyEventResult.ignored;
                }
                final n = chartPrices!.length;
                final key = event.logicalKey;
                int? next;
                if (key == LogicalKeyboardKey.arrowRight) {
                  next = (_chartTouchIndex ?? n) - 1;
                } else if (key == LogicalKeyboardKey.arrowLeft) {
                  next = (_chartTouchIndex ?? -1) + 1;
                } else if (key == LogicalKeyboardKey.home) {
                  next = 0;
                } else if (key == LogicalKeyboardKey.end) {
                  next = n - 1;
                } else if (key == LogicalKeyboardKey.escape) {
                  setState(() => _chartTouchIndex = null);
                  return KeyEventResult.handled;
                }
                if (next == null) return KeyEventResult.ignored;
                setState(() => _chartTouchIndex = next!.clamp(0, n - 1));
                return KeyEventResult.handled;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => updateFromPosition(d.localPosition.dx),
                onHorizontalDragStart: (d) =>
                    updateFromPosition(d.localPosition.dx),
                onHorizontalDragUpdate: (d) =>
                    updateFromPosition(d.localPosition.dx),
                onHorizontalDragEnd: (_) =>
                    setState(() => _chartTouchIndex = null),
                onTapUp: (_) => setState(() => _chartTouchIndex = null),
                onTapCancel: () => setState(() => _chartTouchIndex = null),
                child: Semantics(
                  image: true,
                  label: hasData
                      ? '${tr('priceChartLabel').replaceAll('{n}', '${chartPrices!.length}')}. '
                            '${tr('currentPriceLabel')} $currentPrice'
                      : tr('priceChartLabel').replaceAll('{n}', '0'),
                  child: Container(
                    // הגרף ירד מ-104 ל-72: הוא תפס יותר מקום מהמחיר עצמו
                    // ודחף את הציון וההמלצה אל מתחת לקפל
                    height: 72,
                    decoration: BoxDecoration(
                      color: context.c.textPrimary.withValues(alpha: 0.04),
                      borderRadius: FRadius.mdAll,
                    ),
                    child: ClipRRect(
                      borderRadius: FRadius.mdAll,
                      child: CustomPaint(
                        painter: MiniChartPainter(
                          data: chartPrices,
                          isPositive: up,
                          touchIndex: _chartTouchIndex,
                          upColor: context.c.accentGreen,
                          downColor: context.c.accentRed,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // מסך סיכום יומי (Daily Brief) - בעברית RTL
  // ─────────────────────────────────────────────
  Widget _buildDailyBriefScreen() {
    final subTextColor = context.c.textSecondary;

    // ה-Directionality כבר מוגדר בשורש; המסך הזה לא צריך משלו
    return Builder(
      builder: (context) {
        return isBriefLoading
            ? _buildBriefSkeleton()
            : briefError
            ? Center(
                child: FErrorState(
                  message: tr('briefError'),
                  retryLabel: tr('retry'),
                  onRetry: () {
                    setState(() => dailyBriefData = null);
                    fetchDailyBrief();
                  },
                ),
              )
            : dailyBriefData == null
            ? Center(
                child: Text(
                  tr('loadingBrief'),
                  style: TextStyle(color: subTextColor),
                ),
              )
            : _buildBriefContent();
      },
    );
  }

  /// שלד טעינה בצורת המסך האמיתי, במקום ספינר במרכז
  Widget _buildBriefSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FSpace.screen,
        FSpace.lg,
        FSpace.screen,
        FSpace.scrollBottom,
      ),
      children: const [
        FSkeleton(width: 180, height: 26),
        SizedBox(height: FSpace.sm),
        FSkeleton(width: 120, height: 14),
        SizedBox(height: FSpace.xl),
        FSkeletonCard(height: 120, lines: 3),
        SizedBox(height: FSpace.cardGap),
        FSkeletonCard(height: 80),
        SizedBox(height: FSpace.cardGap),
        FSkeletonCard(height: 80),
        SizedBox(height: FSpace.cardGap),
        FSkeletonCard(height: 80),
      ],
    );
  }

  Widget _buildBriefContent() {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;

    final date = dailyBriefData!['date'] ?? '';
    final markets = dailyBriefData!['markets'] as Map<String, dynamic>? ?? {};
    final aiBrief = dailyBriefData!['aiBrief'] as Map<String, dynamic>? ?? {};
    final headline = aiBrief['headline'] ?? '';
    final newsItems = (aiBrief['newsItems'] as List?) ?? [];
    final insight = aiBrief['insight']?.toString() ?? '';
    final companies = (aiBrief['dramaticCompanies'] as List?) ?? [];
    // תאימות לאחור: אם אין newsItems אבל יש keyEvents ישנים
    final keyEvents = (aiBrief['keyEvents'] as List?) ?? [];

    // 3 מדדים מובילים לתצוגה בכרטיס הכותרת
    final topMarketKeys = markets.keys.take(3).toList();

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () async {
        setState(() => dailyBriefData = null);
        await fetchDailyBrief();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FSpace.screen,
          FSpace.lg,
          FSpace.screen,
          FSpace.scrollBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // כותרת היום
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                    Text(
                      tr('dailyBriefTitle'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    // איזו מהדורה ומתי נכתבה - חשוב כדי שלא יתבלבלו בין
                    // תחזית בוקר לסיכום אחרי נעילה
                    Builder(
                      builder: (_) {
                        final ed = dailyBriefData?['edition']?.toString() ?? '';
                        final at =
                            dailyBriefData?['generatedAt']?.toString() ?? '';
                        if (ed.isEmpty) return const SizedBox.shrink();
                        final label = switch (ed) {
                          'close' => tr('editionClose'),
                          'intraday' => tr('editionIntraday'),
                          _ => tr('editionMorning'),
                        };
                        return Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                switch (ed) {
                                  'close' => Icons.nightlight_round,
                                  'intraday' => Icons.show_chart_rounded,
                                  _ => Icons.wb_twilight,
                                },
                                size: 12,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                at.isEmpty
                                    ? label
                                    : '$label · ${tr('updatedAt')} $at',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: FRadius.mdAll,
                  ),
                  child: const Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // כרטיס הכותרת הגדולה + מדדים בפנים
            if (headline.toString().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.28),
                      Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: FRadius.lgAll,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.c.accentRed.withValues(alpha: 0.18),
                        borderRadius: FRadius.mdAll,
                      ),
                      child: Text(
                        tr('bigHeadline'),
                        style: TextStyle(
                          color: Color(0xFFfca5a5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      headline.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.45,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (topMarketKeys.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: topMarketKeys.map((k) {
                          final data = markets[k] as Map<String, dynamic>;
                          final change =
                              (data['change'] as num?)?.toDouble() ?? 0;
                          final price =
                              (data['price'] as num?)?.toDouble() ?? 0;
                          final isPos = change >= 0;
                          final c = isPos
                              ? context.c.accentGreen
                              : context.c.accentRed;
                          // פורמט מחיר: מספרים גדולים עם פסיקים, קטנים עם 2 ספרות
                          final priceStr = price >= 1000
                              ? price
                                    .toStringAsFixed(0)
                                    .replaceAllMapped(
                                      RegExp(r'(\d)(?=(\d{3})+$)'),
                                      (m) => '${m[1]},',
                                    )
                              : price.toStringAsFixed(2);
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsetsDirectional.only(
                                start: 8,
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _overlay(0.06),
                                borderRadius: FRadius.mdAll,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    k,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: subTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    priceStr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium!.color,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _pct(change),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // כל המדדים - 6 הנכסים עם מחיר ואחוז
            if (markets.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    tr('keyMarkets'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: markets.entries.map((entry) {
                  final data = entry.value as Map<String, dynamic>;
                  final change = (data['change'] as num?)?.toDouble() ?? 0;
                  final price = (data['price'] as num?)?.toDouble() ?? 0;
                  final isPos = change >= 0;
                  final c = isPos ? context.c.accentGreen : context.c.accentRed;
                  final priceStr = price >= 1000
                      ? price
                            .toStringAsFixed(0)
                            .replaceAllMapped(
                              RegExp(r'(\d)(?=(\d{3})+$)'),
                              (m) => '${m[1]},',
                            )
                      : price.toStringAsFixed(2);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: FRadius.lgAll,
                      border: Border.all(
                        color: c.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: subTextColor),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              priceStr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  isPos
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: c,
                                  size: 18,
                                ),
                                Text(
                                  _pct(change),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // מה מזיז את העולם - חדשות מקוטלגות
            if (newsItems.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.public,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    tr('whatMovesWorld'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...newsItems.map((n) {
                final item = n as Map<String, dynamic>;
                return _buildNewsCard(
                  item['category']?.toString() ?? '',
                  item['title']?.toString() ?? '',
                  item['detail']?.toString() ?? '',
                );
              }),
              const SizedBox(height: 8),
            ] else if (keyEvents.isNotEmpty) ...[
              // תאימות לאחור למבנה הישן
              Text(
                'אירועים מרכזיים',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              ...keyEvents.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: FRadius.mdAll,
                      border: BorderDirectional(
                        start: BorderSide(
                          color: context.c.brandVioletBright.withValues(
                            alpha: 0.7,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      event.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // התובנה של Finova
            if (insight.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: FRadius.mdAll,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFFfbbf24),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: tr('finovaInsight'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: insight),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // חברות בכותרות
            if (companies.isNotEmpty) ...[
              Text(
                tr('companiesInHeadlines'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              ...companies.map((c) {
                final company = c as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: FRadius.mdAll,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.18),
                                borderRadius: FRadius.mdAll,
                              ),
                              child: Text(
                                company['ticker']?.toString() ?? '',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              company['name']?.toString() ?? '',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          company['event']?.toString() ?? '',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 22),
            _buildMyStocksSection(textColor, subTextColor),
            _buildSourcesSection(textColor, subTextColor),
            _buildArchiveSection(textColor, subTextColor),

            const SizedBox(height: 20),
            Center(
              child: Text(
                '© 2026 Idan Amrani. All rights reserved.',
                style: TextStyle(
                  color: subTextColor.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── "המניות שלי": מחבר את הסיכום הכללי למה שהמשתמש באמת עוקב אחריו ──
  Widget _buildMyStocksSection(Color textColor, Color subTextColor) {
    final cardColor = Theme.of(context).cardColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_rounded,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 7),
            Text(
              tr('myStocks'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_myMovers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: FRadius.mdAll,
            ),
            child: Text(
              tr('myStocksEmpty'),
              style: TextStyle(
                color: subTextColor,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _myMovers.map((m) {
              final change = (m['change'] as num?)?.toDouble() ?? 0;
              final up = change >= 0;
              final c = up ? context.c.accentGreen : context.c.accentRed;
              return PressScale(
                focusRadius: FRadius.md,
                onTap: () {
                  _goToTab(_tabSearch, remember: true);
                  fetchStockData(m['ticker']?.toString() ?? '');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: FRadius.mdAll,
                    border: Border.all(
                      color: c.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m['ticker']?.toString() ?? '',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '\$${m['price']}',
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pct(change),
                        style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 22),
      ],
    );
  }

  // ── מקורות: הכותרות המקוריות, ניתנות ללחיצה ──
  Widget _buildSourcesSection(Color textColor, Color subTextColor) {
    final sources = (dailyBriefData?['sources'] as List?) ?? [];
    if (sources.isEmpty) return const SizedBox.shrink();
    final cardColor = Theme.of(context).cardColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.link_rounded,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 7),
            Text(
              tr('sourcesTitle'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...sources.take(6).map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          final url = item['url']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: FRadius.mdAll,
              onTap: url.isEmpty ? null : () => _openUrl(url),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: FRadius.mdAll,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['headline']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          if ((item['source']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item['source'].toString(),
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: subTextColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 22),
      ],
    );
  }

  // ── ארכיון: מה נכתב בימים קודמים ──
  Widget _buildArchiveSection(Color textColor, Color subTextColor) {
    // הסיכום של היום כבר מוצג למעלה, אין טעם לחזור עליו ברשימה
    final past = _briefArchive
        .where(
          (b) =>
              b['date']?.toString() !=
              (dailyBriefData?['date']?.toString() ?? ''),
        )
        .toList();
    if (past.isEmpty) return const SizedBox.shrink();
    final cardColor = Theme.of(context).cardColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 7),
            Text(
              tr('archiveTitle'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...past.take(7).map((b) {
          final ed = b['edition']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: FRadius.mdAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        b['date']?.toString() ?? '',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ed == 'close'
                            ? tr('editionClose')
                            : tr('editionMorning'),
                        style: TextStyle(
                          color: subTextColor.withValues(alpha: 0.8),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    b['headline']?.toString() ?? '',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  // צבע לפי קטגוריית חדשות
  Color _categoryColor(String cat) {
    final c = cat.toLowerCase();
    if (cat.contains('גיאופוליטיק') ||
        cat.contains('אנרגיה') ||
        c.contains('geopolit') ||
        c.contains('energy'))
      return context.c.accentRed;
    if (cat.contains('טכנולוגיה') || c.contains('tech'))
      return context.c.accentGreen;
    if (cat.contains('מאקרו') || c.contains('macro'))
      return const Color(0xFF7C7FF2);
    return context.c.accentAmber; // שווקים / markets / default
  }

  Widget _buildNewsCard(String category, String title, String detail) {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;
    final c = _categoryColor(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: FRadius.lgAll,
          border: Border(right: BorderSide(color: c, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                borderRadius: FRadius.mdAll,
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: c,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.4,
              ),
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: subTextColor,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FSpace.screen,
        FSpace.xs,
        FSpace.screen,
        FSpace.scrollBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (finovaScore != null) ...[
            EnterIn(index: 0, child: _buildFinovaScoreCard()),
            const SizedBox(height: FSpace.lg),
          ],
          EnterIn(index: 1, child: _buildRecommendationCard()),
          const SizedBox(height: FSpace.lg),
          EnterIn(index: 2, child: _buildSectionTitle(tr('keyStatistics'))),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _buildStatCardNew(
                Icons.show_chart,
                '1-Year Return',
                analysisData!['oneYearReturn'] ?? 'N/A',
              ),
              _buildStatCardNew(
                Icons.calculate_outlined,
                'P/E Ratio',
                analysisData!['peRatio'] ?? 'N/A',
              ),
              _buildStatCardNew(
                Icons.account_balance_outlined,
                'Market Cap',
                analysisData!['marketCap'] ?? 'N/A',
              ),
              _buildStatCardNew(
                Icons.swap_vert,
                '52W Range',
                analysisData!['fiftyTwoWeekRange'] ?? 'N/A',
              ),
              _buildStatCardNew(
                Icons.timeline,
                'Beta',
                analysisData!['beta'] ?? 'N/A',
              ),
              _buildStatCardNew(
                Icons.percent,
                'Div Yield',
                analysisData!['dividendYield'] ?? 'N/A',
              ),
              _buildStatCardNew(
                Icons.trending_up,
                'ROE',
                analysisData!['roe'] ?? 'N/A',
              ),
              _buildStatCardNew(
                Icons.pie_chart_outline,
                'Net Margin',
                analysisData!['netMargin'] ?? 'N/A',
              ),
              _buildStatCardNew(
                Icons.balance,
                'Debt/Equity',
                analysisData!['debtToEquity'] ?? 'N/A',
              ),
              _buildStatCardNew(
                Icons.rocket_launch_outlined,
                'Revenue Growth',
                analysisData!['revenueGrowthReal'] ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFundamentalsTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FSpace.screen,
        FSpace.xs,
        FSpace.screen,
        FSpace.scrollBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(tr('fundamentalAnalysis')),
          _buildTextCardNew(
            tr('revenueGrowthT'),
            analysisData!['revenueGrowth'] ?? 'N/A',
            const Color(0xFF4F6AF5),
          ),
          const SizedBox(height: 10),
          _buildTextCardNew(
            tr('marginsTrendT'),
            analysisData!['marginsTrend'] ?? 'N/A',
            context.c.accentGreen,
          ),
          const SizedBox(height: 10),
          _buildTextCardNew(
            tr('valuationT'),
            analysisData!['valuationVsPeers'] ?? 'N/A',
            context.c.accentAmber,
          ),
          const SizedBox(height: 10),
          _buildTextCardNew(
            tr('freeCashFlowT'),
            analysisData!['freeCashFlow'] ?? 'N/A',
            Colors.purpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildCatalystsTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FSpace.screen,
        FSpace.xs,
        FSpace.screen,
        FSpace.scrollBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(tr('upcomingEvents')),
          _buildListCardNew(
            tr('upcomingEvents'),
            analysisData!['upcomingEvents'],
            Icons.event_outlined,
            Colors.blueAccent,
          ),
          const SizedBox(height: 10),
          _buildSectionTitle(tr('investmentThesis')),
          _buildListCardNew(
            tr('investmentSummary'),
            analysisData!['thesisSummary'],
            Icons.lightbulb_outline,
            context.c.accentAmber,
          ),
          const SizedBox(height: 10),
          _buildSectionTitle(tr('catalystsTitle')),
          _buildTextCardNew(
            tr('keyCatalyst'),
            analysisData!['catalysts'] ?? 'N/A',
            Colors.tealAccent,
          ),
        ],
      ),
    );
  }

  void _showRecommendationReason() {
    final rec = analysisData!['finalRecommendation'] ?? 'N/A';
    final reason =
        analysisData!['recommendationReason'] ??
        'No detailed reason available.';
    final isBullish = rec.toLowerCase().contains('buy');
    final color = isBullish
        ? context.c.accentGreen
        : (rec.toLowerCase().contains('sell')
              ? context.c.accentRed
              : context.c.accentAmber);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: FRadius.lgAll),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_outlined, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "${tr('whyRec')} $rec?",
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                reason.toString(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    tr('close'),
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── צבע לפי ציון ──
  // שכבת-על עדינה (רקעים/מפרידים) שנשארת נראית גם במצב בהיר וגם כהה.
  // שימוש בלבן קבוע נעלם לגמרי על רקע בהיר.
  /// שכבה שקופה מעל הרקע - לגבולות ולרקעים עדינים בתוך כרטיסים
  Color _overlay(double opacity) =>
      context.c.textPrimary.withValues(alpha: opacity);

  // סקאלה נפרדת לאיכות. בכוונה לא ירוק/אדום של השוק: אלה שמורים לכיוון
  // המחיר, ושימוש באותו ירוק גם ל"ציון טוב" הפך צבע אחד לשתי משמעויות
  // באותו כרטיס. כאן: טורקיז=חזק, אינדיגו=בינוני, סגול-ורוד=חלש.
  Color _scoreColor(int v) {
    final c = context.c;
    return switch (fmt.scoreBand(v)) {
      fmt.ScoreBand.high => c.scoreHigh,
      fmt.ScoreBand.mid => c.scoreMid,
      fmt.ScoreBand.low => c.scoreLow,
    };
  }

  // ── כרטיס ציון Finova ──
  Widget _buildFinovaScoreCard() {
    final s = finovaScore!;
    final int total = (s['total'] ?? 0) as int;
    final String label = s['label'] ?? '';
    final String quickTake = s['quickTake'] ?? '';
    final Color color = _scoreColor(total);

    // מסודר מהחלש לחזק: הדבר שמושך את הציון למטה הוא מה שמעניין,
    // ובסדר קבוע היה צריך לקרוא את כל הארבעה כדי למצוא אותו
    final subs = [
      {'name': tr('quality'), 'val': (s['quality'] ?? 0) as int},
      {'name': tr('value'), 'val': (s['value'] ?? 0) as int},
      {'name': tr('growth'), 'val': (s['growth'] ?? 0) as int},
      {'name': tr('risk'), 'val': (s['risk'] ?? 0) as int},
    ]..sort((a, b) => (a['val'] as int).compareTo(b['val'] as int));

    // מסמנים את החלש ביותר רק אם יש באמת פער - אם כולם שווים אין "נקודה חלשה"
    final int lowestVal = subs.first['val'] as int;
    final bool hasClearWeakest =
        subs.length > 1 && lowestVal < (subs[1]['val'] as int);

    final c = context.c;
    return FCard(
      onTap: _showScoreBreakdown,
      // כרטיס שטוח בכוונה: המחיר למעלה וההמלצה למטה נושאים גרדיאנט,
      // וכששלושתם צועקים אין לעין לאן ללכת. הטבעת הצבעונית מספיקה כדי
      // לתת לציון נוכחות בלי להתחרות עליהם.
      border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      child: Builder(
        builder: (context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // טבעת הציון
                  ScoreRing(
                    score: total,
                    color: color,
                    size: 78,
                    strokeWidth: 7,
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: FType.h1.copyWith(color: c.textPrimary),
                        ),
                        Text(
                          '/100',
                          style: FType.micro.copyWith(color: c.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('finovaScore'),
                          style: FType.micro.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(label, style: FType.h3.copyWith(color: color)),
                        const SizedBox(height: 5),
                        Text(
                          quickTake,
                          style: FType.caption.copyWith(
                            height: 1.5,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.4,
                children: subs.asMap().entries.map((entry) {
                  final sub = entry.value;
                  final v = sub['val'] as int;
                  final sc = _scoreColor(v);
                  // הכרטיסייה הראשונה היא הנמוכה ביותר אחרי המיון
                  final isWeakest = entry.key == 0 && hasClearWeakest;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FSpace.md,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.c.bgSurface2,
                      borderRadius: FRadius.mdAll,
                      border: isWeakest
                          ? Border.all(
                              color: sc.withValues(alpha: 0.55),
                              width: 1,
                            )
                          : FBorder.subtle(context.c),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sub['name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FType.micro.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: context.c.textSecondary,
                                ),
                              ),
                            ),
                            if (isWeakest) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '· ${tr('weakest')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FType.micro.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: sc,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '$v',
                              style: FType.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: sc,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: FRadius.pillAll,
                          child: LinearProgressIndicator(
                            value: v / 100,
                            minHeight: 5,
                            backgroundColor: _overlay(0.12),
                            valueColor: AlwaysStoppedAnimation(sc),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 13,
                    color: c.textTertiary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tr('tapForBreakdown'),
                    style: FType.micro.copyWith(color: c.textTertiary),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── דיאלוג: ממה הורכב הציון ולמה ──
  void _showScoreBreakdown() {
    final s = finovaScore!;
    final factors = (s['factors'] as List?) ?? [];
    final int total = (s['total'] ?? 0) as int;

    // קיבוץ לפי קטגוריה
    final Map<String, List<Map>> byCat = {};
    for (final f in factors) {
      final cat = f['category'] as String? ?? '';
      byCat.putIfAbsent(cat, () => []).add(f as Map);
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: widget.lang == 'he'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: FRadius.lgAll),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _scoreColor(total).withValues(alpha: 0.15),
                          borderRadius: FRadius.mdAll,
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          color: _scoreColor(total),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('scoreBreakdownTitle'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.color,
                              ),
                            ),
                            Text(
                              tr('scoreBreakdownSub'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall!.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...byCat.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 6),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        ...entry.value.map((f) {
                          final tone = f['tone'] as String? ?? 'neutral';
                          // אותה סקאלת איכות כמו הציון עצמו, לא ירוק/אדום של השוק
                          final Color tc = tone == 'good'
                              ? const Color(0xFF2DD4BF)
                              : tone == 'bad'
                              ? const Color(0xFFC084FC)
                              : const Color(0xFF818CF8);
                          final IconData ic = tone == 'good'
                              ? Icons.check_circle_outline
                              : tone == 'bad'
                              ? Icons.warning_amber_rounded
                              : Icons.remove_circle_outline;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: FRadius.mdAll,
                              border: Border.all(
                                color: tc.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(ic, color: tc, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            f['metric'] as String? ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium!.color,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            f['value'] as String? ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: tc,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        f['verdict'] as String? ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall!.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: FRadius.mdAll,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr('scoreWeights'),
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.5,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .color!
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: FRadius.mdAll,
                        ),
                      ),
                      child: Text(
                        tr('gotIt'),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final rec = analysisData!['finalRecommendation'] ?? 'N/A';
    final verdict = analysisData!['verdict'] ?? 'N/A';
    final confidence = analysisData!['confidenceLevel'] ?? 'N/A';

    // שלושה מצבים: חיובי / שלילי / ניטרלי
    final lowerRec = rec.toLowerCase();
    final lowerVerdict = verdict.toLowerCase();
    final isBullish =
        lowerVerdict.contains('bullish') || lowerRec.contains('buy');
    final isBearish =
        lowerVerdict.contains('bearish') || lowerRec.contains('sell');

    final c = context.c;
    final Color accent;
    final IconData verdictIcon;
    if (isBullish) {
      accent = c.accentGreen;
      verdictIcon = Icons.trending_up_rounded;
    } else if (isBearish) {
      accent = c.accentRed;
      verdictIcon = Icons.trending_down_rounded;
    } else {
      accent = c.accentAmber;
      verdictIcon = Icons.remove_rounded;
    }

    return FCard(
      onTap: _showRecommendationReason,
      padding: const EdgeInsets.all(FSpace.heroPad),
      // רקע הכרטיס נשאר משטח רגיל, והצבע נכנס דרך הגוון העדין והמסגרת
      // בלבד - שלושה כרטיסי גרדיאנט זה אחרי זה הפכו את המסך לרועש
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: 0.10), Colors.transparent],
        stops: const [0.0, 0.6],
      ),
      border: Border.all(color: accent.withValues(alpha: 0.30), width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: FRadius.mdAll,
                ),
                child: Icon(verdictIcon, color: accent, size: 26),
              ),
              const SizedBox(width: FSpace.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tr('aiRecommendation'),
                          style: FType.micro.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: accent.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec,
                      style: FType.display.copyWith(
                        fontSize: 28,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: c.hairline),
          const SizedBox(height: FSpace.cardGap),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('verdict'),
                      style: FType.micro.copyWith(
                        color: c.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      verdict,
                      style: FType.h3.copyWith(fontSize: 14, color: accent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('confidence'),
                      style: FType.micro.copyWith(
                        color: c.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      confidence,
                      style: FType.h3.copyWith(
                        fontSize: 14,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    tr('tapForDetails'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // הבהרה: זו לא המלצת השקעה
          Row(
            children: [
              Icon(Icons.info_outline, size: 11, color: c.textQuiet),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  tr('disclaimerShort'),
                  style: FType.micro.copyWith(
                    color: c.textQuiet,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // מילון הסברים בעברית פשוטה לכל מושג
  static const Map<String, String> _termExplanations = {
    'P/E Ratio':
        'כמה משלמים על כל דולר רווח של החברה. נמוך = זול יחסית, גבוה = יקר או שיש ציפייה לצמיחה גדולה.',
    'Market Cap': 'השווי הכולל של החברה בבורסה - מחיר המניה כפול מספר המניות.',
    'Beta':
        'כמה המניה תנודתית ביחס לשוק. מעל 1 = יותר תנודתית מהשוק, מתחת ל-1 = יציבה יותר.',
    'Div Yield': 'אחוז הדיבידנד שהחברה משלמת בשנה ביחס למחיר המניה.',
    '52W Range':
        'המחיר הנמוך והגבוה ביותר של המניה ב-52 השבועות (שנה) האחרונים.',
    '1-Year Return': 'כמה המניה עלתה או ירדה באחוזים בשנה האחרונה.',
    'ROE':
        'תשואה על ההון - כמה רווח החברה מייצרת מכל שקל של הון עצמי. גבוה = החברה יעילה ברווחיות. מעל 15% נחשב טוב.',
    'Net Margin':
        'מרווח נקי - כמה אחוז מכל ההכנסות נשאר כרווח נקי אחרי כל ההוצאות. גבוה = החברה רווחית מאוד.',
    'Debt/Equity':
        'יחס חוב להון - כמה חוב יש לחברה ביחס להון העצמי. נמוך = פחות סיכון. מעל 2 נחשב חוב גבוה.',
    'Revenue Growth':
        'צמיחת הכנסות - כמה ההכנסות גדלו בשנה האחרונה. חיובי וגבוה = החברה מתרחבת.',
  };

  void _showTermExplanation(String term) {
    final explanation = _termExplanations[term] ?? 'אין הסבר זמין כרגע.';
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: widget.lang == 'he'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: FRadius.lgAll),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      term,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  explanation,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      tr('gotIt'),
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCardNew(IconData icon, String label, String value) {
    Color valueColor = Theme.of(context).textTheme.bodyMedium!.color!;
    if (value.toLowerCase().contains('buy') ||
        value.toLowerCase().contains('bullish') ||
        value.startsWith('+')) {
      valueColor = context.c.accentGreen;
    }
    if (value.toLowerCase().contains('sell') ||
        value.toLowerCase().contains('bearish') ||
        value.startsWith('-')) {
      valueColor = context.c.accentRed;
    }

    final hasExplanation = _termExplanations.containsKey(label);
    final primary = context.c.brandVioletBright;

    return FCard(
      onTap: hasExplanation ? () => _showTermExplanation(label) : null,
      padding: const EdgeInsets.all(FSpace.cardGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: FRadius.mdAll,
                ),
                child: Icon(icon, size: 15, color: primary),
              ),
              if (hasExplanation) ...[
                const Spacer(),
                Icon(
                  Icons.help_outline,
                  size: 13,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall!.color!.withValues(alpha: 0.4),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: FType.micro.copyWith(
              color: context.c.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          // ערכים כמו "$164.07 - $236.54" ארוכים, ובהגדלת טקסט הם נחתכו.
          // מכווצים לרוחב הכרטיס במקום לאבד את סוף המספר.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: FType.h3.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCardNew(String title, String text, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: FRadius.mdAll,
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCardNew(
    String title,
    dynamic listData,
    IconData icon,
    Color accentColor,
  ) {
    // הגנה: מקבלים רק רשימה תקינה של מחרוזות נקיות
    List<String> items = [];
    if (listData is List) {
      for (final e in listData) {
        final s = e.toString().trim();
        // מסננים פריטים שבורים שמכילים שברי JSON או שמות שדות
        if (s.isEmpty) continue;
        if (s.contains('finalRecommendation') ||
            s.contains('confidenceLevel') ||
            s.contains('recommendationReason') ||
            s.contains('thesisSummary') ||
            s.startsWith('{') ||
            s.startsWith('[') ||
            s.startsWith('"') ||
            s.length <= 2 || // פריטי זבל קצרים כמו "n" "," ":"
            s == 'n' ||
            s == ':' ||
            s == ',') {
          continue;
        }
        items.add(s);
      }
    } else if (listData is String && listData.trim().isNotEmpty) {
      items.add(listData.trim());
    }

    if (items.isEmpty) {
      items = [widget.lang == 'he' ? 'אין מידע זמין' : 'No data available'];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: FRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: FSpace.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: FSpace.xs),
      child: SectionTitle(text: title),
    );
  }

  // מסך טעינה: נרות יפניים + טקסט סטטוס שמתקדם, במקום ספינר אילם
  Widget _buildLoadingState() {
    final c = context.c;
    const stageKeys = [
      'stageFetching',
      'stageAnalyzing',
      'stageScoring',
      'stageAlmost',
    ];
    final stageKey = stageKeys[_loadingStage.clamp(0, stageKeys.length - 1)];

    // שלד בצורת המסך האמיתי במקום ספינר, ומעליו הטקסט שמסביר באיזה שלב
    // הניתוח נמצא - הוא לוקח עד דקה, וספינר אילם כל הזמן הזה נראה תקוע
    return ListView(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.fromLTRB(
        FSpace.screen,
        FSpace.xs,
        FSpace.screen,
        FSpace.scrollBottom,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.brandVioletBright,
              ),
            ),
            const SizedBox(width: FSpace.sm),
            AnimatedSwitcher(
              duration: FMotion.respect(context, FMotion.screenEnter),
              child: Text(
                tr(stageKey),
                key: ValueKey(stageKey),
                style: FType.caption.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: FSpace.lg),
        const FSkeletonCard(height: 110, lines: 3),
        const SizedBox(height: FSpace.cardGap),
        const FSkeletonCard(height: 90, lines: 2),
        const SizedBox(height: FSpace.cardGap),
        Row(
          children: [
            Expanded(child: FSkeletonCard(height: 60, lines: 2)),
            const SizedBox(width: FSpace.md),
            Expanded(child: FSkeletonCard(height: 60, lines: 2)),
          ],
        ),
        const SizedBox(height: FSpace.cardGap),
        Row(
          children: [
            Expanded(child: FSkeletonCard(height: 60, lines: 2)),
            const SizedBox(width: FSpace.md),
            Expanded(child: FSkeletonCard(height: 60, lines: 2)),
          ],
        ),
      ],
    );
  }

  Widget _buildNotFound() {
    // סימבול שלא קיים זו לא תקלה חולפת - "נסה שוב" רק יחזור על אותה תוצאה,
    // אז מציגים הודעה אחרת בלי כפתור ניסיון חוזר
    final ticker = _lastAttemptedTicker.trim().toUpperCase();
    return Center(
      child: FErrorState(
        message: isUnknownSymbol
            ? '${tr('notFound')}${ticker.isEmpty ? '' : ' · $ticker'}'
            : tr('analysisError'),
        hint: isUnknownSymbol ? tr('notFoundHint') : tr('analysisErrorHint'),
        retryLabel: tr('retry'),
        onRetry: (isUnknownSymbol || isLoading)
            ? null
            : () => fetchStockData(_lastAttemptedTicker),
      ),
    );
  }

  Widget _buildAlertsScreen() {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final subTextColor = context.c.textSecondary;
    final cardColor = context.c.bgSurface;

    final c = context.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FSpace.screen,
        FSpace.lg,
        FSpace.screen,
        FSpace.scrollBottom,
      ),
      children: [
        EnterIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('tabWatchlist'),
                style: FType.h1.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: FSpace.xs),
              Text(
                tr('alertsSubtitle'),
                style: FType.body.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: FSpace.xl),
        EnterIn(index: 1, child: _buildWatchlistSection()),
        const SizedBox(height: FSpace.xxl),
        EnterIn(index: 2, child: SectionTitle(text: tr('priceAlerts'))),
        EnterIn(
          index: 2,
          child: _buildPushCard(textColor, subTextColor, cardColor),
        ),
        const SizedBox(height: FSpace.cardGap),
        EnterIn(
          index: 3,
          child: _buildAlertForm(textColor, subTextColor, cardColor),
        ),
        const SizedBox(height: FSpace.xl),
        if (_priceAlerts.isEmpty)
          FEmptyState(
            icon: Icons.notifications_none_rounded,
            message: '${tr('noAlerts')}\n${tr('addAlertHint')}',
          )
        else
          ...List.generate(
            _priceAlerts.length,
            (i) => _buildAlertRow(i, textColor, subTextColor, cardColor),
          ),
      ],
    );
  }

  Widget _buildWatchlistSection() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          text: tr('watchlist'),
          trailing: _watchlist.isEmpty
              ? null
              : Text(
                  '${_watchlist.length}',
                  style: FType.caption.copyWith(color: c.textTertiary),
                ),
        ),
        if (_watchlist.isEmpty)
          FCard(
            child: FEmptyState(
              icon: Icons.bookmark_border_rounded,
              message: '${tr('watchlistEmpty')}\n${tr('watchlistEmptyHint')}',
              actionLabel: tr('analyseNow'),
              onAction: () => _goToTab(_tabSearch, remember: true),
            ),
          )
        else
          for (final ticker in _watchlist) ...[
            _buildWatchlistRow(ticker),
            const SizedBox(height: FSpace.sm),
          ],
      ],
    );
  }

  Widget _buildWatchlistRow(String ticker) {
    final c = context.c;
    final change = _watchlistChanges[ticker];
    final score = _knownScores[ticker];

    return FCard(
      padding: const EdgeInsets.all(FSpace.md),
      radius: FRadius.md,
      onTap: () {
        _goToTab(_tabSearch, remember: true);
        fetchStockData(ticker);
      },
      child: Row(
        children: [
          TickerAvatar(
            ticker: ticker,
            size: 36,
            radius: FRadius.sm,
            logoUrl: _logoUrl(ticker),
          ),
          const SizedBox(width: FSpace.md),
          Expanded(
            child: Text(
              ticker,
              style: FType.h3.copyWith(fontSize: 15, color: c.textPrimary),
            ),
          ),
          if (score != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _scoreColor(score).withValues(alpha: 0.14),
                borderRadius: FRadius.pillAll,
              ),
              child: Text(
                '$score',
                style: FType.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _scoreColor(score),
                ),
              ),
            ),
            const SizedBox(width: FSpace.sm),
          ],
          if (change != null)
            Text(
              _pct(change, digits: 1),
              style: FType.h3.copyWith(
                fontSize: 14,
                color: change >= 0 ? c.accentGreen : c.accentRed,
              ),
            )
          else
            const FSkeleton(width: 44, height: 14),
          const SizedBox(width: FSpace.sm),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: c.textTertiary),
            tooltip: tr('follow'),
            onPressed: () => _toggleFollow(ticker),
          ),
        ],
      ),
    );
  }

  // כרטיס הפעלת התראות דחיפה - זה מה שהופך התראות לשימושיות באמת
  Widget _buildPushCard(Color textColor, Color subTextColor, Color cardColor) {
    final primary = Theme.of(context).primaryColor;
    final active = _pushEnabled;

    return FCard(
      background: cardColor,
      border: Border.all(
        color: active
            ? context.c.accentGreen.withValues(alpha: 0.4)
            : context.c.hairlineStrong,
        width: 1,
      ),
      child: Row(
        children: [
          Icon(
            active
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_outlined,
            color: active ? context.c.accentGreen : subTextColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('pushTitle'),
                  style: FType.h3.copyWith(fontSize: 14, color: textColor),
                ),
                const SizedBox(height: 3),
                Text(
                  !_pushSupported
                      ? tr('pushUnsupported')
                      : (active ? tr('pushOnHint') : tr('pushOffHint')),
                  style: FType.micro.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (_pushSupported) ...[
            const SizedBox(width: 10),
            _pushBusy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  )
                : TextButton(
                    onPressed: active ? _disablePush : _enablePush,
                    child: Text(active ? tr('pushDisable') : tr('pushEnable')),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertForm(Color textColor, Color subTextColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: FRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _alertTickerController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    labelText: tr('alertTicker'),
                    hintText: 'NVDA',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _alertPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    labelText: tr('alertPrice'),
                    hintText: '200',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PressScale(
                  semanticLabel: tr('alertAbove'),
                  focusRadius: FRadius.md,
                  onTap: () => setState(() => _alertCondition = 'above'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _alertCondition == 'above'
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: FRadius.mdAll,
                    ),
                    child: Center(
                      child: Text(
                        tr('alertAbove'),
                        style: TextStyle(
                          color: _alertCondition == 'above'
                              ? Colors.white
                              : textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PressScale(
                  semanticLabel: tr('alertBelow'),
                  focusRadius: FRadius.md,
                  onTap: () => setState(() => _alertCondition = 'below'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _alertCondition == 'below'
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: FRadius.mdAll,
                    ),
                    child: Center(
                      child: Text(
                        tr('alertBelow'),
                        style: TextStyle(
                          color: _alertCondition == 'below'
                              ? Colors.white
                              : textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addAlert,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(tr('addAlert')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow(
    int index,
    Color textColor,
    Color subTextColor,
    Color cardColor,
  ) {
    final alert = _priceAlerts[index];
    final bool triggered = alert['triggered'] == true;
    final bool above = alert['condition'] == 'above';
    final double target = (alert['target'] as num).toDouble();
    final double? lastPrice = (alert['lastPrice'] as num?)?.toDouble();
    final Color statusColor = triggered
        ? context.c.accentGreen
        : Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: FRadius.mdAll,
        border: triggered
            ? Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.2)
            : null,
      ),
      child: Row(
        children: [
          TrendIcon(
            above ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: statusColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      alert['ticker'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: FRadius.mdAll,
                      ),
                      child: Text(
                        triggered ? tr('alertTriggered') : tr('alertActive'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${above ? tr('alertAbove') : tr('alertBelow')} \$${target.toStringAsFixed(2)}'
                  '${lastPrice != null ? '  ·  ${tr('currentPriceLabel')} \$${lastPrice.toStringAsFixed(2)}' : ''}',
                  style: TextStyle(fontSize: 12.5, color: subTextColor),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: subTextColor),
            tooltip: tr('removeAlert'),
            onPressed: () => _removeAlert(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    final c = context.c;
    final textColor = c.textPrimary;
    final cardColor = c.bgSurface;
    final subTextColor = c.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        FSpace.screen,
        FSpace.lg,
        FSpace.screen,
        FSpace.scrollBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('settings'), style: FType.h1.copyWith(color: textColor)),
          const SizedBox(height: FSpace.xxl),

          // שם התצוגה - מה שמופיע בברכה במסך הבית
          _buildNameCard(),
          const SizedBox(height: FSpace.xl),

          // Language selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: FRadius.mdAll,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tr('language'),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PressScale(
                        semanticLabel: 'עברית',
                        focusRadius: FRadius.md,
                        onTap: () => widget.onLangChanged('he'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.lang == 'he'
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: FRadius.mdAll,
                          ),
                          child: Center(
                            child: Text(
                              'עברית',
                              style: TextStyle(
                                color: widget.lang == 'he'
                                    ? Colors.white
                                    : textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PressScale(
                        semanticLabel: 'English',
                        focusRadius: FRadius.md,
                        onTap: () => widget.onLangChanged('en'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.lang == 'en'
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: FRadius.mdAll,
                          ),
                          child: Center(
                            child: Text(
                              'English',
                              style: TextStyle(
                                color: widget.lang == 'en'
                                    ? Colors.white
                                    : textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dark mode
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: FRadius.mdAll,
            ),
            child: SwitchListTile(
              title: Text(
                tr('darkMode'),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
              value: widget.isDarkMode,
              activeColor: Theme.of(context).primaryColor,
              onChanged: widget.onThemeChanged,
              secondary: Icon(
                widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Accessibility section
          Row(
            children: [
              Icon(
                Icons.accessibility_new_rounded,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tr('textSize'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Text size
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: FRadius.mdAll,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_size, color: textColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      tr('textSize'),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(widget.textScale * 100).toInt()}%',
                      style: TextStyle(color: subTextColor, fontSize: 13),
                    ),
                  ],
                ),
                Slider(
                  value: widget.textScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: widget.onTextScaleChanged,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'A',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    Text(
                      'A',
                      style: TextStyle(color: subTextColor, fontSize: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick text size presets
          Row(
            children: [
              _buildTextPreset(tr('small'), 0.9, textColor, cardColor),
              const SizedBox(width: 10),
              _buildTextPreset(tr('normal'), 1.0, textColor, cardColor),
              const SizedBox(width: 10),
              _buildTextPreset(tr('large'), 1.2, textColor, cardColor),
            ],
          ),

          // מפתחות ה-API אינם יושבים יותר במסך הזה. הם מאחורי התחברות,
          // בעמוד ניהול נפרד, וכאן נשארת רק הדלת אליו.
          const SizedBox(height: FSpace.xl),
          ActionRow(
            icon: Icons.admin_panel_settings_rounded,
            title: tr('adminPanel'),
            subtitle: tr('adminPanelSub'),
            onTap: _openAdminPanel,
          ),

          // תקנה 35 מחייבת שהצהרת הנגישות תופיע במקום בולט - שורה משלה,
          // לא סעיף קטן בתוך ההבהרה המשפטית
          const SizedBox(height: FSpace.xl),
          ActionRow(
            icon: Icons.accessibility_new_rounded,
            title: tr('accessibilityStatement'),
            subtitle: tr('accessibilityStatementSub'),
            onTap: _showAccessibilityStatement,
          ),

          const SizedBox(height: FSpace.cardGap),
          ActionRow(
            icon: Icons.privacy_tip_outlined,
            title: tr('privacyPolicy'),
            subtitle: tr('privacyPolicySub'),
            onTap: _showPrivacyPolicy,
          ),

          const SizedBox(height: FSpace.cardGap),
          ActionRow(
            icon: Icons.gavel_rounded,
            title: tr('termsOfUse'),
            subtitle: tr('termsOfUseSub'),
            onTap: _showTermsOfUse,
          ),

          const SizedBox(height: 20),
          // הבהרה משפטית מלאה
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: FRadius.mdAll,
              border: Border.all(color: _overlay(0.08), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel_rounded, size: 17, color: subTextColor),
                    const SizedBox(width: 8),
                    Text(
                      tr('disclaimerTitle'),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  tr('disclaimerFull'),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: FSpace.xxxl),
          Center(
            child: Column(
              children: [
                Logo(
                  variant: LogoVariant.mono,
                  markSize: 18,
                  color: c.textQuiet,
                ),
                const SizedBox(height: FSpace.sm),
                Text(
                  '© 2026 Idan Amrani. All rights reserved.',
                  style: FType.micro.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textQuiet,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────
  // הצהרת נגישות
  //
  // תקנה 35 מחייבת שההצהרה תופיע "במקום בולט" באתר ובאפליקציה, ולכן היא
  // שורה משלה במסך "עוד" ולא שורה בתוך ההבהרה המשפטית.
  // ───────────────────────────────────────────
  void _openAdminPanel() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminPage(
          apiBase: _apiBase,
          tr: tr,
          scheme: context.c,
          isRtl: widget.lang == 'he',
        ),
      ),
    );
  }

  void _showAccessibilityStatement() => _showLegalDocument(
    title: tr('accessibilityStatement'),
    icon: Icons.accessibility_new_rounded,
    sections: AccessibilityStatement.forLang(widget.lang),
  );

  void _showPrivacyPolicy() => _showLegalDocument(
    title: tr('privacyPolicy'),
    icon: Icons.privacy_tip_outlined,
    sections: PrivacyPolicy.forLang(widget.lang),
  );

  void _showTermsOfUse() => _showLegalDocument(
    title: tr('termsOfUse'),
    icon: Icons.gavel_rounded,
    sections: TermsOfUse.forLang(widget.lang),
  );

  void _showLegalDocument({
    required String title,
    required IconData icon,
    required List<LegalSection> sections,
  }) {
    final c = context.c;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.bgElevated,
      isScrollControlled: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FRadius.lg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            FSpace.xl,
            0,
            FSpace.xl,
            FSpace.xxxl,
          ),
          children: [
            Row(
              children: [
                Icon(icon, color: c.brandVioletBright, size: 22),
                const SizedBox(width: FSpace.sm),
                Expanded(
                  child: Text(
                    title,
                    style: FType.h1.copyWith(
                      fontSize: 20,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FSpace.xl),
            for (final section in sections) ...[
              Text(
                section.heading,
                style: FType.h3.copyWith(color: c.brandVioletBright),
              ),
              const SizedBox(height: FSpace.sm),
              for (final p in section.paragraphs) ...[
                Text(
                  p,
                  style: FType.body.copyWith(
                    color: c.textSecondary,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: FSpace.sm),
              ],
              for (final b in section.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: FSpace.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: c.brandVioletBright.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: FSpace.sm),
                      Expanded(
                        child: Text(
                          b,
                          style: FType.body.copyWith(
                            color: c.textSecondary,
                            height: 1.65,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: FSpace.xl),
            ],
            FPrimaryButton(
              label: tr('close'),
              expand: true,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  /// שם התצוגה - נשמר מקומית ומופיע בברכה במסך הבית
  Widget _buildNameCard() {
    final c = context.c;
    return FCard(
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            color: c.brandVioletBright,
            size: 20,
          ),
          const SizedBox(width: FSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('yourName'),
                  style: FType.h3.copyWith(fontSize: 14, color: c.textPrimary),
                ),
                Text(
                  tr('yourNameHint'),
                  style: FType.micro.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FSpace.md),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: FType.body.copyWith(color: c.textPrimary),
              cursorColor: c.brandVioletBright,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                filled: true,
                fillColor: c.bgSurface2,
                border: OutlineInputBorder(
                  borderRadius: FRadius.mdAll,
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: widget.onUserNameChanged,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
                widget.onUserNameChanged(_nameController.text);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPreset(
    String label,
    double scale,
    Color textColor,
    Color cardColor,
  ) {
    final isActive = (widget.textScale - scale).abs() < 0.05;
    return Expanded(
      child: PressScale(
        semanticLabel: label,
        focusRadius: FRadius.md,
        onTap: () => widget.onTextScaleChanged(scale),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                : cardColor,
            borderRadius: FRadius.mdAll,
            border: Border.all(
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Theme.of(context).primaryColor : textColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
