import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// ───────────────────────────────────────────
// מערכת תרגום - כל הטקסטים בממשק
// ───────────────────────────────────────────
class T {
  static const Map<String, Map<String, String>> _s = {
    'research': {'he': 'Research', 'en': 'Research'},
    'dailyBrief': {'he': 'סיכום יומי', 'en': 'Daily Brief'},
    'alerts': {'he': 'התראות', 'en': 'Alerts'},
    'settings': {'he': 'הגדרות', 'en': 'Settings'},
    'searchHint': {'he': 'חפש מניה (שם או סימול)', 'en': 'Search stock (name or ticker)'},
    'researchSubtitle': {'he': 'מנוע ניתוח פונדמנטלי', 'en': '20-Point Fundamental Engine'},
    'summary': {'he': 'סיכום', 'en': 'Summary'},
    'fundamentals': {'he': 'פונדמנטלי', 'en': 'Fundamentals'},
    'catalysts': {'he': 'קטליזטורים', 'en': 'Catalysts'},
    'finovaScore': {'he': 'ציון FINOVA', 'en': 'FINOVA SCORE'},
    'quality': {'he': 'איכות', 'en': 'Quality'},
    'value': {'he': 'מחיר', 'en': 'Value'},
    'growth': {'he': 'צמיחה', 'en': 'Growth'},
    'risk': {'he': 'סיכון', 'en': 'Risk'},
    'tapForBreakdown': {'he': 'הקש לפירוט מלא של הציון', 'en': 'Tap for full score breakdown'},
    'scoreBreakdownTitle': {'he': 'ממה מורכב הציון', 'en': 'How the score is built'},
    'scoreBreakdownSub': {'he': 'כל מדד מבוסס על נתון אמיתי', 'en': 'Each metric is based on real data'},
    'scoreWeights': {
      'he': 'הציון הכולל הוא ממוצע משוקלל: איכות 35%, צמיחה 25%, מחיר 20%, סיכון 20%. איכות מקבלת משקל גבוה כי חברה מעולה ביוקר עדיפה על חברה חלשה בזול.',
      'en': 'The total is a weighted average: Quality 35%, Growth 25%, Value 20%, Risk 20%. Quality is weighted higher because a great company at a high price beats a weak one at a low price.'
    },
    'gotIt': {'he': 'הבנתי', 'en': 'Got it'},
    'keyStatistics': {'he': 'נתונים מרכזיים', 'en': 'Key Statistics'},
    'aiRecommendation': {'he': 'המלצת AI', 'en': 'AI RECOMMENDATION'},
    'verdict': {'he': 'הערכה', 'en': 'VERDICT'},
    'confidence': {'he': 'ביטחון', 'en': 'CONFIDENCE'},
    'tapForDetails': {'he': 'הקש לפרטים', 'en': 'Tap for details'},
    'dailyBriefTitle': {'he': 'הסיכום היומי', 'en': 'Daily Brief'},
    'bigHeadline': {'he': 'הכותרת הגדולה היום', 'en': "TODAY'S BIG STORY"},
    'keyMarkets': {'he': 'מדדים מרכזיים', 'en': 'Key Markets'},
    'whatMovesWorld': {'he': 'מה מזיז את העולם', 'en': 'What Moves the World'},
    'finovaInsight': {'he': 'התובנה של Finova: ', 'en': 'Finova Insight: '},
    'companiesInHeadlines': {'he': 'חברות בכותרות', 'en': 'Companies in the Headlines'},
    'loadingBrief': {'he': 'טוען את הסיכום היומי...', 'en': 'Loading daily brief...'},
    'briefError': {'he': 'שגיאה בטעינת הסיכום', 'en': 'Error loading brief'},
    'retry': {'he': 'נסה שוב', 'en': 'Retry'},
    'darkMode': {'he': 'מצב כהה', 'en': 'Dark Mode'},
    'language': {'he': 'שפה', 'en': 'Language'},
    'textSize': {'he': 'גודל טקסט', 'en': 'Text Size'},
    'small': {'he': 'קטן', 'en': 'Small'},
    'normal': {'he': 'רגיל', 'en': 'Normal'},
    'large': {'he': 'גדול', 'en': 'Large'},
    'notFound': {'he': 'לא נמצאה מניה כזו', 'en': 'No such stock found'},
    'analysisError': {'he': 'לא הצלחנו לטעון את הניתוח כרגע', 'en': "Couldn't load the analysis right now"},
    'analysisErrorHint': {'he': 'זה בדרך כלל זמני - נסה שוב בעוד רגע', 'en': 'This is usually temporary - try again in a moment'},
    'analyzing': {'he': 'מנתח...', 'en': 'Analyzing...'},
    'searchToStart': {'he': 'חפש מניה כדי להתחיל', 'en': 'Search a stock to start'},
    'noAlerts': {'he': 'אין התראות עדיין', 'en': 'No alerts yet'},
    'addAlertHint': {'he': 'הוסף התראה ראשונה למעלה', 'en': 'Add your first alert above'},
    'alertTicker': {'he': 'טיקר', 'en': 'Ticker'},
    'alertPrice': {'he': 'מחיר יעד', 'en': 'Target price'},
    'alertAbove': {'he': 'מעל', 'en': 'Above'},
    'alertBelow': {'he': 'מתחת', 'en': 'Below'},
    'addAlert': {'he': 'הוסף התראה', 'en': 'Add Alert'},
    'alertActive': {'he': 'פעיל', 'en': 'Active'},
    'alertTriggered': {'he': 'הופעל', 'en': 'Triggered'},
    'crossedAbove': {'he': 'עבר מעל', 'en': 'crossed above'},
    'crossedBelow': {'he': 'ירד מתחת ל', 'en': 'dropped below'},
    'currentPriceLabel': {'he': 'מחיר נוכחי', 'en': 'Current'},
    'upcomingEvents': {'he': 'אירועים צפויים', 'en': 'Upcoming Events'},
    'investmentThesis': {'he': 'תזת השקעה', 'en': 'Investment Thesis'},
    'catalystsTitle': {'he': 'קטליזטורים', 'en': 'Catalysts'},
    'fundamentalAnalysis': {'he': 'ניתוח פונדמנטלי', 'en': 'Fundamental Analysis'},
    'revenueGrowthT': {'he': 'צמיחת הכנסות', 'en': 'Revenue Growth'},
    'marginsTrendT': {'he': 'מגמת מרווחים', 'en': 'Margins Trend'},
    'valuationT': {'he': 'תמחור מול מתחרים', 'en': 'Valuation vs Peers'},
    'freeCashFlowT': {'he': 'תזרים מזומנים חופשי', 'en': 'Free Cash Flow'},
    'investmentSummary': {'he': 'סיכום השקעה', 'en': 'Investment Summary'},
    'keyCatalyst': {'he': 'קטליזטור מרכזי', 'en': 'Key Catalyst'},
  };

  static String get(String key, String lang) {
    return _s[key]?[lang] ?? _s[key]?['en'] ?? key;
  }
}

void main() {
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

  @override
  void initState() {
    super.initState();
    // מסך הפתיחה מוצג 2.5 שניות ואז עובר לאפליקציה
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showSplash = false);
    });
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finova',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFEBEEF6),
        cardColor: Colors.white,
        primaryColor: const Color(0xFF6366F1),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF1A1A2E)),
          bodySmall: TextStyle(color: Color(0xFF6B6B85)),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B14),
        cardColor: const Color(0xFF16161F),
        primaryColor: const Color(0xFF7C7FF2),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFF5F5FA)),
          bodySmall: TextStyle(color: Color(0xFF7A7A92)),
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: _showSplash
          ? const SplashScreen()
          : DashboardScreen(
        onThemeChanged: toggleTheme,
        isDarkMode: isDarkMode,
        onTextScaleChanged: setTextScale,
        textScale: textScale,
        lang: lang,
        onLangChanged: setLang,
      ),
    );
  }
}

// ───────────────────────────────────────────
// מסך פתיחה (Splash Screen)
// ───────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _dotsController;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // אנימציית כניסה - הלוגו והשם מופיעים בהדרגה
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack));
    _fadeController.forward();

    // אנימציית הנקודות הפועמות
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Stack(
        children: [
          // זוהר עדין במרכז
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C7FF2).withOpacity(0.18),
                    const Color(0xFF7C7FF2).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // תוכן מרכזי
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // לוגו
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C7FF2), Color(0xFF5B5FD6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C7FF2).withOpacity(0.35),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.candlestick_chart_rounded,
                          color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: 26),
                    // שם
                    const Text('Finova',
                        style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1)),
                    const SizedBox(height: 8),
                    // טאגליין
                    const Text('ניתוח מניות חכם, בשנייה',
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8EA8),
                            letterSpacing: 0.3)),
                    const SizedBox(height: 30),
                    // נקודות פועמות
                    _buildPulsingDots(),
                  ],
                ),
              ),
            ),
          ),
          // קרדיט בתחתית
          Positioned(
            bottom: 34,
            left: 0,
            right: 0,
            child: Text('© 2026 Idan Amrani',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25))),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // כל נקודה פועמת בעיכוב שונה
            final t = (_dotsController.value - i * 0.2) % 1.0;
            final opacity = 0.25 + 0.65 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C7FF2).withOpacity(opacity),
                ),
              ),
            );
          }),
        );
      },
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

  const DashboardScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
    required this.onTextScaleChanged,
    required this.textScale,
    required this.lang,
    required this.onLangChanged,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // קיצור לתרגום
  String tr(String key) => T.get(key, widget.lang);

  int _selectedIndex = 0;
  String symbol = "NVDA";
  String currentPrice = "...";
  Timer? _priceTimer;

  double? dailyChange;
  List<double>? chartPrices;

  bool isLoading = false;
  bool isNotFound = false;
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

  final List<String> popularTickers = ['NVDA', 'AAPL', 'MSFT', 'PLTR', 'UBER', 'TSLA'];

  // ── Admin API-keys section state ──
  bool _adminSectionOpen = false;
  bool _adminStatusLoaded = false;
  bool _adminConfigured = false;
  String? _adminToken;
  bool _adminBusy = false;
  String? _adminError;
  String? _adminMessage;
  final TextEditingController _adminPasswordController = TextEditingController();
  final TextEditingController _finnhubController = TextEditingController();
  final TextEditingController _groqController = TextEditingController();
  final TextEditingController _geminiController = TextEditingController();
  String _finnhubMasked = '';
  String _groqMasked = '';
  String _geminiMasked = '';

  static const String _apiBase = 'https://finovam.ddns.net';

  // ── Price alerts state ──
  List<Map<String, dynamic>> _priceAlerts = [];
  Timer? _alertsCheckTimer;
  final TextEditingController _alertTickerController = TextEditingController();
  final TextEditingController _alertPriceController = TextEditingController();
  String _alertCondition = 'above';
  bool _alertsBusy = false;

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('finova_price_alerts');
    if (raw == null) return;
    try {
      final decoded = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() => _priceAlerts = decoded);
    } catch (_) {}
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('finova_price_alerts', jsonEncode(_priceAlerts));
  }

  void _addAlert() {
    final ticker = _alertTickerController.text.trim().toUpperCase();
    final target = double.tryParse(_alertPriceController.text.trim());
    if (ticker.isEmpty || target == null || target <= 0) return;

    setState(() {
      _priceAlerts.insert(0, {
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
              .get(Uri.parse('$_apiBase/api/quote/${Uri.encodeComponent(ticker)}'))
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
          final hit = alert['condition'] == 'above' ? price >= target : price <= target;
          if (hit) {
            alert['triggered'] = true;
            firstTriggerMessage ??=
                '${alert['ticker']} ${alert['condition'] == 'above' ? tr('crossedAbove') : tr('crossedBelow')} \$${target.toStringAsFixed(2)} — now \$${price.toStringAsFixed(2)}';
          }
        }
      });
      await _saveAlerts();

      if (firstTriggerMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(firstTriggerMessage!), duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      _alertsBusy = false;
    }
  }

  Future<void> _toggleAdminSection() async {
    setState(() {
      _adminSectionOpen = !_adminSectionOpen;
      _adminError = null;
      _adminMessage = null;
    });
    if (_adminSectionOpen && !_adminStatusLoaded) {
      try {
        final res = await http.get(Uri.parse('$_apiBase/api/admin/status'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _adminConfigured = data['configured'] == true;
            _adminStatusLoaded = true;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _submitAdminPassword() async {
    final password = _adminPasswordController.text;
    if (password.isEmpty) return;
    setState(() {
      _adminBusy = true;
      _adminError = null;
    });
    try {
      final endpoint = _adminConfigured ? 'login' : 'setup';
      final res = await http.post(
        Uri.parse('$_apiBase/api/admin/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _adminToken = data['token'];
          _adminConfigured = true;
          _adminPasswordController.clear();
        });
        await _loadAdminKeys();
      } else if (res.statusCode == 429) {
        setState(() => _adminError = 'יותר מדי ניסיונות, נסה שוב בעוד כמה דקות');
      } else {
        setState(() => _adminError = 'סיסמה שגויה');
      }
    } catch (_) {
      setState(() => _adminError = 'שגיאת חיבור לשרת');
    } finally {
      setState(() => _adminBusy = false);
    }
  }

  Future<void> _loadAdminKeys() async {
    if (_adminToken == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/api/admin/keys'),
        headers: {'Authorization': 'Bearer $_adminToken'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _finnhubMasked = data['finnhubKey'] ?? '';
          _groqMasked = data['groqKey'] ?? '';
          _geminiMasked = data['geminiKey'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveAdminKeys() async {
    if (_adminToken == null) return;
    setState(() {
      _adminBusy = true;
      _adminError = null;
      _adminMessage = null;
    });
    try {
      final body = <String, String>{};
      if (_finnhubController.text.trim().isNotEmpty) body['finnhubKey'] = _finnhubController.text.trim();
      if (_groqController.text.trim().isNotEmpty) body['groqKey'] = _groqController.text.trim();
      if (_geminiController.text.trim().isNotEmpty) body['geminiKey'] = _geminiController.text.trim();

      final res = await http.post(
        Uri.parse('$_apiBase/api/admin/keys'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_adminToken'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        _finnhubController.clear();
        _groqController.clear();
        _geminiController.clear();
        setState(() => _adminMessage = 'נשמר בהצלחה');
        await _loadAdminKeys();
      } else if (res.statusCode == 401) {
        setState(() {
          _adminToken = null;
          _adminError = 'ההתחברות פגה, יש להתחבר שוב';
        });
      } else {
        setState(() => _adminError = 'שמירה נכשלה');
      }
    } catch (_) {
      setState(() => _adminError = 'שגיאת חיבור לשרת');
    } finally {
      setState(() => _adminBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchStockData(symbol);
    // עדכון מחיר בזמן אמת כל 15 שניות
    _priceTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (analysisData != null && !isLoading && _selectedIndex == 0) {
        _refreshPrice(symbol);
      }
    });

    _loadAlerts();
    _alertsCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) => _checkAlerts());
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
      if (_selectedIndex == 1) {
        fetchDailyBrief();
      }
    }
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _searchDebounce?.cancel();
    _alertsCheckTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _adminPasswordController.dispose();
    _finnhubController.dispose();
    _groqController.dispose();
    _geminiController.dispose();
    _alertTickerController.dispose();
    _alertPriceController.dispose();
    super.dispose();
  }

  Future<void> fetchStockData(String ticker) async {
    if (ticker.isEmpty) return;
    _lastAttemptedTicker = ticker;
    setState(() {
      isLoading = true;
      isNotFound = false;
      dailyChange = null;
      chartPrices = null;
    });

    final url = Uri.parse(
      'https://finovam.ddns.net/api/analyze/${ticker.trim().toUpperCase()}?lang=${widget.lang}',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // ─── דיבאג זמני - לראות מה מגיע ───
        print('DEBUG lang=${widget.lang}');
        print('DEBUG analysis type: ${data['analysis'].runtimeType}');
        print('DEBUG finalRecommendation: "${data['analysis']?['finalRecommendation']}"');
        print('DEBUG confidenceLevel: "${data['analysis']?['confidenceLevel']}"');
        setState(() {
          symbol = data['symbol'];
          currentPrice = '\$${data['currentPrice']}';
          dailyChange = data['dailyChange'] != null ? (data['dailyChange'] as num).toDouble() : null;
          if (data['chartData'] != null) {
            chartPrices = (data['chartData'] as List).map((e) => (e as num).toDouble()).toList();
          }
          analysisData = data['analysis'] != null
              ? Map<String, dynamic>.from(data['analysis'])
              : null;
          finovaScore = data['finovaScore'] != null
              ? Map<String, dynamic>.from(data['finovaScore'])
              : null;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isNotFound = true;
          analysisData = null;
          finovaScore = null;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isNotFound = true;
      });
    }
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
    _searchController.clear();
    setState(() => searchSuggestions = []);
    FocusScope.of(context).unfocus();
    fetchStockData(ticker);
  }

  Future<void> _refreshPrice(String ticker) async {
    final url = Uri.parse(
      'https://finovam.ddns.net/api/analyze/${ticker.trim().toUpperCase()}?lang=${widget.lang}',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            currentPrice = '\$${data['currentPrice']}';
            dailyChange = data['dailyChange'] != null ? (data['dailyChange'] as num).toDouble() : dailyChange;
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

    final url = Uri.parse('https://finovam.ddns.net/api/daily-brief?lang=${widget.lang}');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        setState(() {
          dailyBriefData = json.decode(response.body);
          isBriefLoading = false;
        });
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
    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );

    // במסך רחב (מחשב) - אותו עיצוב בדיוק, ממורכז במסגרת בפרופורציית טלפון
    // (הגודל משתנה יחסית לגודל המסך במקום קבוע, כדי שלא ייראה זעיר במסך גדול
    // או צפוף במסך קטן - אבל תמיד שומר על אותה צורת טלפון)
    return LayoutBuilder(
      builder: (context, constraints) {
        const double breakpoint = 700;
        const double aspect = 430 / 860; // width / height
        const double minWidth = 360;
        const double maxWidth = 480;
        const double vPad = 64;
        const double hPad = 48;
        if (constraints.maxWidth <= breakpoint) return scaffold;

        final availH = constraints.maxHeight - vPad;
        final availW = constraints.maxWidth - hPad;
        double frameWidth = (availH * aspect).clamp(minWidth, maxWidth);
        if (frameWidth > availW) frameWidth = availW.clamp(minWidth, maxWidth);
        final frameHeight = frameWidth / aspect;

        return ColoredBox(
          color: widget.isDarkMode ? const Color(0xFF0b0b0f) : const Color(0xFFe4e7ee),
          child: Center(
            child: SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 40, spreadRadius: 2),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: scaffold,
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
      case 1:
        return _buildDailyBriefScreen();
      case 2:
        return _buildAlertsScreen();
      case 3:
        return _buildSettingsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildBottomNav() {
    final cardColor = Theme.of(context).cardColor;
    final primary = Theme.of(context).primaryColor;
    final subColor = Theme.of(context).textTheme.bodySmall!.color!;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07), width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavItem(Icons.bar_chart_rounded, tr('research'), 0, primary, subColor),
              _buildNavItem(Icons.wb_sunny_outlined, tr('dailyBrief'), 1, primary, subColor),
              _buildNavItem(Icons.notifications_outlined, tr('alerts'), 2, primary, subColor),
              _buildNavItem(Icons.settings_outlined, tr('settings'), 3, primary, subColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color active, Color inactive) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (index == 1) fetchDailyBrief(); // טעינת הסיכום בלחיצה
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? active.withOpacity(0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: isSelected ? active : inactive),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? active : inactive)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;
    final cardColor = Theme.of(context).cardColor;

    Color changeColor = const Color(0xFF4ade80);
    Color changeBgColor = const Color(0xFF1a3a2a);
    String changeText = '0.00%';

    if (dailyChange != null) {
      bool isPositive = dailyChange! >= 0;
      changeColor = isPositive ? const Color(0xFF4ade80) : const Color(0xFFf87171);
      changeBgColor = isPositive ? const Color(0xFF1a3a2a) : const Color(0xFF3a1a1a);
      changeText = '${isPositive ? '+' : ''}${dailyChange!.toStringAsFixed(2)}%';
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (analysisData != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dailyChange != null && dailyChange! < 0
                            ? [const Color(0xFF2A1620), const Color(0xFF16161F)]
                            : [const Color(0xFF1A2333), const Color(0xFF16161F)],
                      ),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(symbol,
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Text('NASDAQ',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFB8B8D0),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                            ),
                            const Spacer(),
                            // אינדיקטור LIVE עם נקודה פועמת
                            _PulsingLiveDot(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currentPrice,
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1.5,
                                    height: 1.0)),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: changeBgColor,
                                    borderRadius: BorderRadius.circular(9)),
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
                                    Text(changeText,
                                        style: TextStyle(
                                            color: changeColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMiniChart(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.6),
                          ]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('research'),
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.5)),
                          Text(tr('researchSubtitle'),
                              style: TextStyle(fontSize: 12, color: subTextColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.08), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: tr('searchHint'),
                      hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                      suffixIcon: isSearching
                          ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Theme.of(context).primaryColor),
                        ),
                      )
                          : (_searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.close, color: subTextColor, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchSuggestions = []);
                        },
                      )
                          : null),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) _selectSuggestion(value.trim().toUpperCase());
                    },
                  ),
                ),
                // רשימת הצעות השלמה אוטומטית
                if (searchSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.1), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: searchSuggestions.map((sug) {
                        final ticker = sug['symbol']?.toString() ?? '';
                        final name = sug['description']?.toString() ?? '';
                        return InkWell(
                          onTap: () => _selectSuggestion(ticker),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(ticker,
                                      style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: textColor, fontSize: 13)),
                                ),
                                Icon(Icons.north_west, size: 14, color: subTextColor),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: popularTickers.map((ticker) {
                      final isActive = ticker == symbol;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            fetchStockData(ticker);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive ? Theme.of(context).primaryColor.withOpacity(0.2) : cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              ticker,
                              style: TextStyle(
                                color: isActive ? Theme.of(context).primaryColor : subTextColor,
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (analysisData != null)
                  Container(
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(3),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: subTextColor,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
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
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : isNotFound
                ? _buildNotFound()
                : analysisData == null
                ? Center(child: Text(tr('searchToStart'), style: TextStyle(color: subTextColor)))
                : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildFundamentalsTab(),
                _buildCatalystsTab(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              '© 2026 Idan Amrani. All rights reserved.',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.5), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _MiniChartPainter(data: chartPrices, isPositive: (dailyChange ?? 0) >= 0),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // מסך סיכום יומי (Daily Brief) - בעברית RTL
  // ─────────────────────────────────────────────
  Widget _buildDailyBriefScreen() {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;

    return SafeArea(
      child: Directionality(
        textDirection: widget.lang == 'he' ? TextDirection.rtl : TextDirection.ltr,
        child: isBriefLoading
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
            : briefError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 60, color: subTextColor),
              const SizedBox(height: 16),
              Text(tr('briefError'), style: TextStyle(fontSize: 18, color: textColor)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => dailyBriefData = null);
                  fetchDailyBrief();
                },
                child: Text(tr('retry')),
              ),
            ],
          ),
        )
            : dailyBriefData == null
            ? Center(child: Text('טוען סיכום...', style: TextStyle(color: subTextColor)))
            : _buildBriefContent(),
      ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // כותרת היום
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: TextStyle(fontSize: 12, color: subTextColor)),
                  Text(tr('dailyBriefTitle'),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.3)),
                ],
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // כרטיס הכותרת הגדולה + מדדים בפנים
          if (headline.toString().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.28),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf87171).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(tr('bigHeadline'),
                        style: TextStyle(
                            color: Color(0xFFfca5a5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 10),
                  Text(headline.toString(),
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.45,
                          letterSpacing: -0.3)),
                  if (topMarketKeys.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: topMarketKeys.map((k) {
                        final data = markets[k] as Map<String, dynamic>;
                        final change = (data['change'] as num?)?.toDouble() ?? 0;
                        final price = (data['price'] as num?)?.toDouble() ?? 0;
                        final isPos = change >= 0;
                        final c = isPos ? const Color(0xFF4ade80) : const Color(0xFFf87171);
                        // פורמט מחיר: מספרים גדולים עם פסיקים, קטנים עם 2 ספרות
                        final priceStr = price >= 1000
                            ? price.toStringAsFixed(0).replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
                            : price.toStringAsFixed(2);
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(k,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10, color: subTextColor)),
                                const SizedBox(height: 3),
                                Text(priceStr,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).textTheme.bodyMedium!.color)),
                                const SizedBox(height: 1),
                                Text('${isPos ? '+' : ''}${change.toStringAsFixed(2)}%',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
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
                Icon(Icons.bar_chart_rounded, color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 7),
                Text(tr('keyMarkets'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
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
                final c = isPos ? const Color(0xFF4ade80) : const Color(0xFFf87171);
                final priceStr = price >= 1000
                    ? price.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
                    : price.toStringAsFixed(2);
                return Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: c.withOpacity(0.18), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: subTextColor)),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(priceStr,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.3)),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                  isPos ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                  color: c,
                                  size: 18),
                              Text('${isPos ? '+' : ''}${change.toStringAsFixed(2)}%',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
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
                Icon(Icons.public, color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 7),
                Text(tr('whatMovesWorld'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
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
            Text('אירועים מרכזיים', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 10),
            ...keyEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(right: BorderSide(color: Theme.of(context).primaryColor, width: 3)),
                ),
                child: Text(event.toString(), style: TextStyle(fontSize: 13, color: textColor, height: 1.4)),
              ),
            )),
            const SizedBox(height: 12),
          ],

          // התובנה של Finova
          if (insight.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFFfbbf24), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
                        children: [
                          TextSpan(
                              text: tr('finovaInsight'),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
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
            Text(tr('companiesInHeadlines'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
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
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.06), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(company['ticker']?.toString() ?? '',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          Text(company['name']?.toString() ?? '',
                              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(company['event']?.toString() ?? '',
                          style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 20),
          Center(
            child: Text('© 2026 Idan Amrani. All rights reserved.',
                style: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // צבע לפי קטגוריית חדשות
  Color _categoryColor(String cat) {
    final c = cat.toLowerCase();
    if (cat.contains('גיאופוליטיק') || cat.contains('אנרגיה') ||
        c.contains('geopolit') || c.contains('energy')) return const Color(0xFFf87171);
    if (cat.contains('טכנולוגיה') || c.contains('tech')) return const Color(0xFF4ade80);
    if (cat.contains('מאקרו') || c.contains('macro')) return const Color(0xFF7C7FF2);
    return const Color(0xFFfbbf24); // שווקים / markets / default
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
          borderRadius: BorderRadius.circular(15),
          border: Border(right: BorderSide(color: c, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(category,
                  style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 7),
            Text(title,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: textColor, height: 1.4)),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(detail,
                  style: TextStyle(fontSize: 12, color: subTextColor, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketCard(String name, dynamic price, double change) {
    final isPositive = change >= 0;
    final color = isPositive ? const Color(0xFF4ade80) : const Color(0xFFf87171);
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: TextStyle(color: subTextColor, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(price.toString(), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (finovaScore != null) ...[
            _buildFinovaScoreCard(),
            const SizedBox(height: 16),
          ],
          _buildRecommendationCard(),
          const SizedBox(height: 16),
          _buildSectionTitle(tr('keyStatistics')),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _buildStatCardNew(Icons.show_chart, '1-Year Return', analysisData!['oneYearReturn'] ?? 'N/A'),
              _buildStatCardNew(Icons.calculate_outlined, 'P/E Ratio', analysisData!['peRatio'] ?? 'N/A'),
              _buildStatCardNew(Icons.account_balance_outlined, 'Market Cap', analysisData!['marketCap'] ?? 'N/A'),
              _buildStatCardNew(Icons.swap_vert, '52W Range', analysisData!['fiftyTwoWeekRange'] ?? 'N/A'),
              _buildStatCardNew(Icons.timeline, 'Beta', analysisData!['beta'] ?? 'N/A'),
              _buildStatCardNew(Icons.percent, 'Div Yield', analysisData!['dividendYield'] ?? 'N/A'),
              _buildStatCardNew(Icons.trending_up, 'ROE', analysisData!['roe'] ?? 'N/A'),
              _buildStatCardNew(Icons.pie_chart_outline, 'Net Margin', analysisData!['netMargin'] ?? 'N/A'),
              _buildStatCardNew(Icons.balance, 'Debt/Equity', analysisData!['debtToEquity'] ?? 'N/A'),
              _buildStatCardNew(Icons.rocket_launch_outlined, 'Revenue Growth', analysisData!['revenueGrowthReal'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFundamentalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(tr('fundamentalAnalysis')),
          _buildTextCardNew(tr('revenueGrowthT'), analysisData!['revenueGrowth'] ?? 'N/A', const Color(0xFF4F6AF5)),
          const SizedBox(height: 10),
          _buildTextCardNew(tr('marginsTrendT'), analysisData!['marginsTrend'] ?? 'N/A', const Color(0xFF4ade80)),
          const SizedBox(height: 10),
          _buildTextCardNew(tr('valuationT'), analysisData!['valuationVsPeers'] ?? 'N/A', Colors.orangeAccent),
          const SizedBox(height: 10),
          _buildTextCardNew(tr('freeCashFlowT'), analysisData!['freeCashFlow'] ?? 'N/A', Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildCatalystsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(tr('upcomingEvents')),
          _buildListCardNew(tr('upcomingEvents'), analysisData!['upcomingEvents'], Icons.event_outlined, Colors.blueAccent),
          const SizedBox(height: 10),
          _buildSectionTitle(tr('investmentThesis')),
          _buildListCardNew(tr('investmentSummary'), analysisData!['thesisSummary'], Icons.lightbulb_outline, Colors.orangeAccent),
          const SizedBox(height: 10),
          _buildSectionTitle(tr('catalystsTitle')),
          _buildTextCardNew(tr('keyCatalyst'), analysisData!['catalysts'] ?? 'N/A', Colors.tealAccent),
        ],
      ),
    );
  }

  void _showRecommendationReason() {
    final rec = analysisData!['finalRecommendation'] ?? 'N/A';
    final reason = analysisData!['recommendationReason'] ?? 'No detailed reason available.';
    final isBullish = rec.toLowerCase().contains('buy');
    final color = isBullish ? const Color(0xFF4ade80) : (rec.toLowerCase().contains('sell') ? const Color(0xFFf87171) : Colors.orangeAccent);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  Text('Why $rec?',
                      style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              Text(reason.toString(),
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                      fontSize: 14, height: 1.5)),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── צבע לפי ציון ──
  Color _scoreColor(int v) {
    if (v >= 68) return const Color(0xFF4ade80);
    if (v >= 50) return const Color(0xFFfbbf24);
    return const Color(0xFFf87171);
  }

  // ── כרטיס ציון Finova ──
  Widget _buildFinovaScoreCard() {
    final s = finovaScore!;
    final int total = (s['total'] ?? 0) as int;
    final String label = s['label'] ?? '';
    final String quickTake = s['quickTake'] ?? '';
    final Color color = _scoreColor(total);

    final subs = [
      {'name': tr('quality'), 'val': (s['quality'] ?? 0) as int},
      {'name': tr('value'), 'val': (s['value'] ?? 0) as int},
      {'name': tr('growth'), 'val': (s['growth'] ?? 0) as int},
      {'name': tr('risk'), 'val': (s['risk'] ?? 0) as int},
    ];

    return GestureDetector(
      onTap: _showScoreBreakdown,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [color.withOpacity(0.16), const Color(0xFF14241A).withOpacity(0.0)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.28), width: 1),
        ),
        child: Directionality(
          textDirection: widget.lang == 'he' ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // טבעת הציון
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 78,
                          height: 78,
                          child: CustomPaint(
                            painter: _ScoreRingPainter(score: total, color: color),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$total',
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).textTheme.bodyMedium!.color,
                                    height: 1.0)),
                            Text('/100',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Theme.of(context).textTheme.bodySmall!.color)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('finovaScore'),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: color.withOpacity(0.9))),
                        const SizedBox(height: 3),
                        Text(label,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: color)),
                        const SizedBox(height: 5),
                        Text(quickTake,
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.85))),
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
                children: subs.map((sub) {
                  final v = sub['val'] as int;
                  final c = _scoreColor(v);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(sub['name'] as String,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).textTheme.bodySmall!.color)),
                            const Spacer(),
                            Text('$v',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: v / 100,
                            minHeight: 4,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation(c),
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
                  Icon(Icons.touch_app_outlined,
                      size: 13,
                      color: Theme.of(context).textTheme.bodySmall!.color),
                  const SizedBox(width: 5),
                  Text(tr('tapForBreakdown'),
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall!.color)),
                ],
              ),
            ],
          ),
        ),
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
        textDirection: widget.lang == 'he' ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                          color: _scoreColor(total).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.analytics_outlined,
                            color: _scoreColor(total), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('scoreBreakdownTitle'),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).textTheme.bodyMedium!.color)),
                            Text(tr('scoreBreakdownSub'),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall!.color)),
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
                          child: Text(entry.key,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).primaryColor)),
                        ),
                        ...entry.value.map((f) {
                          final tone = f['tone'] as String? ?? 'neutral';
                          final Color tc = tone == 'good'
                              ? const Color(0xFF4ade80)
                              : tone == 'bad'
                              ? const Color(0xFFf87171)
                              : const Color(0xFFfbbf24);
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
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: tc.withOpacity(0.25), width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(ic, color: tc, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(f['metric'] as String? ?? '',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Theme.of(context).textTheme.bodyMedium!.color)),
                                          const Spacer(),
                                          Text(f['value'] as String? ?? '',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: tc)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(f['verdict'] as String? ?? '',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).textTheme.bodySmall!.color)),
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
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 18, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              tr('scoreWeights'),
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.8))),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(tr('gotIt'),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
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
    final isBullish = lowerVerdict.contains('bullish') || lowerRec.contains('buy');
    final isBearish = lowerVerdict.contains('bearish') || lowerRec.contains('sell');

    Color accent;
    List<Color> gradientColors;
    IconData verdictIcon;
    if (isBullish) {
      accent = const Color(0xFF4ade80);
      gradientColors = [const Color(0xFF14301F), const Color(0xFF0F2418)];
      verdictIcon = Icons.trending_up_rounded;
    } else if (isBearish) {
      accent = const Color(0xFFf87171);
      gradientColors = [const Color(0xFF301414), const Color(0xFF240F0F)];
      verdictIcon = Icons.trending_down_rounded;
    } else {
      accent = const Color(0xFFfbbf24);
      gradientColors = [const Color(0xFF302814), const Color(0xFF24200F)];
      verdictIcon = Icons.remove_rounded;
    }

    return GestureDetector(
      onTap: _showRecommendationReason,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(verdictIcon, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(tr('aiRecommendation'),
                              style: TextStyle(
                                  color: accent.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2)),
                          const SizedBox(width: 5),
                          Icon(Icons.info_outline, size: 12, color: accent.withOpacity(0.6)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(rec,
                          style: TextStyle(
                              color: accent,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.1)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('verdict'),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                      const SizedBox(height: 3),
                      Text(verdict,
                          style: TextStyle(
                              color: accent, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('confidence'),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                      const SizedBox(height: 3),
                      Text(confidence,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(tr('tapForDetails'),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 10, color: Colors.white.withOpacity(0.5)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // מילון הסברים בעברית פשוטה לכל מושג
  static const Map<String, String> _termExplanations = {
    'P/E Ratio': 'כמה משלמים על כל דולר רווח של החברה. נמוך = זול יחסית, גבוה = יקר או שיש ציפייה לצמיחה גדולה.',
    'Market Cap': 'השווי הכולל של החברה בבורסה - מחיר המניה כפול מספר המניות.',
    'Beta': 'כמה המניה תנודתית ביחס לשוק. מעל 1 = יותר תנודתית מהשוק, מתחת ל-1 = יציבה יותר.',
    'Div Yield': 'אחוז הדיבידנד שהחברה משלמת בשנה ביחס למחיר המניה.',
    '52W Range': 'המחיר הנמוך והגבוה ביותר של המניה ב-52 השבועות (שנה) האחרונים.',
    '1-Year Return': 'כמה המניה עלתה או ירדה באחוזים בשנה האחרונה.',
    'ROE': 'תשואה על ההון - כמה רווח החברה מייצרת מכל שקל של הון עצמי. גבוה = החברה יעילה ברווחיות. מעל 15% נחשב טוב.',
    'Net Margin': 'מרווח נקי - כמה אחוז מכל ההכנסות נשאר כרווח נקי אחרי כל ההוצאות. גבוה = החברה רווחית מאוד.',
    'Debt/Equity': 'יחס חוב להון - כמה חוב יש לחברה ביחס להון העצמי. נמוך = פחות סיכון. מעל 2 נחשב חוב גבוה.',
    'Revenue Growth': 'צמיחת הכנסות - כמה ההכנסות גדלו בשנה האחרונה. חיובי וגבוה = החברה מתרחבת.',
  };

  void _showTermExplanation(String term) {
    final explanation = _termExplanations[term] ?? 'אין הסבר זמין כרגע.';
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: widget.lang == 'he' ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Theme.of(context).primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text(term,
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(explanation,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color, fontSize: 14, height: 1.6)),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr('gotIt'), style: TextStyle(color: Theme.of(context).primaryColor)),
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
    if (value.toLowerCase().contains('buy') || value.toLowerCase().contains('bullish') || value.startsWith('+')) {
      valueColor = const Color(0xFF4ade80);
    }
    if (value.toLowerCase().contains('sell') || value.toLowerCase().contains('bearish') || value.startsWith('-')) {
      valueColor = const Color(0xFFf87171);
    }

    final hasExplanation = _termExplanations.containsKey(label);
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: hasExplanation ? () => _showTermExplanation(label) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withOpacity(0.06), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: primary),
                ),
                if (hasExplanation) ...[
                  const Spacer(),
                  Icon(Icons.help_outline,
                      size: 13,
                      color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.4)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall!.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3)),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextCardNew(String title, String text, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildListCardNew(String title, dynamic listData, IconData icon, Color accentColor) {
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
            s.length <= 2 ||   // פריטי זבל קצרים כמו "n" "," ":"
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
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 5, height: 5,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Theme.of(context).textTheme.bodyMedium!.color)),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: subTextColor),
          const SizedBox(height: 16),
          Text(tr('analysisError'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(tr('analysisErrorHint'), style: TextStyle(color: subTextColor, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : () => fetchStockData(_lastAttemptedTicker),
            child: Text(tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsScreen() {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;
    final cardColor = Theme.of(context).cardColor;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('alerts'), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text('Price & news notifications', style: TextStyle(fontSize: 13, color: subTextColor)),
            const SizedBox(height: 20),
            _buildAlertForm(textColor, subTextColor, cardColor),
            const SizedBox(height: 20),
            if (_priceAlerts.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Icon(Icons.notifications_none_rounded, size: 72, color: subTextColor.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(tr('noAlerts'), style: TextStyle(fontSize: 18, color: textColor)),
                    const SizedBox(height: 4),
                    Text(tr('addAlertHint'), style: TextStyle(color: subTextColor)),
                  ],
                ),
              )
            else
              ...List.generate(
                _priceAlerts.length,
                (i) => _buildAlertRow(i, textColor, subTextColor, cardColor),
              ),
            const SizedBox(height: 30),
            Center(
              child: Text('© 2026 Idan Amrani. All rights reserved.',
                  style: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 10)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertForm(Color textColor, Color subTextColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                child: GestureDetector(
                  onTap: () => setState(() => _alertCondition = 'above'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _alertCondition == 'above'
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(tr('alertAbove'),
                          style: TextStyle(
                              color: _alertCondition == 'above' ? Colors.white : textColor,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _alertCondition = 'below'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _alertCondition == 'below'
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(tr('alertBelow'),
                          style: TextStyle(
                              color: _alertCondition == 'below' ? Colors.white : textColor,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addAlert,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                child: Text(tr('addAlert')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow(int index, Color textColor, Color subTextColor, Color cardColor) {
    final alert = _priceAlerts[index];
    final bool triggered = alert['triggered'] == true;
    final bool above = alert['condition'] == 'above';
    final double target = (alert['target'] as num).toDouble();
    final double? lastPrice = (alert['lastPrice'] as num?)?.toDouble();
    final Color statusColor = triggered ? const Color(0xFF4ade80) : Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: triggered ? Border.all(color: statusColor.withOpacity(0.5), width: 1.2) : null,
      ),
      child: Row(
        children: [
          Icon(above ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(alert['ticker'] as String,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(triggered ? tr('alertTriggered') : tr('alertActive'),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
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
            onPressed: () => _removeAlert(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final cardColor = Theme.of(context).cardColor;
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('settings'), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 24),

            // Language selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: Theme.of(context).primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Text(tr('language'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onLangChanged('he'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: widget.lang == 'he'
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text('עברית',
                                  style: TextStyle(
                                      color: widget.lang == 'he' ? Colors.white : textColor,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onLangChanged('en'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: widget.lang == 'en'
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text('English',
                                  style: TextStyle(
                                      color: widget.lang == 'en' ? Colors.white : textColor,
                                      fontWeight: FontWeight.w700)),
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
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
              child: SwitchListTile(
                title: Text(tr('darkMode'), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                value: widget.isDarkMode,
                activeColor: Theme.of(context).primaryColor,
                onChanged: widget.onThemeChanged,
                secondary: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: textColor),
              ),
            ),
            const SizedBox(height: 20),

            // Accessibility section
            Row(
              children: [
                Icon(Icons.accessibility_new_rounded, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(tr('textSize'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const SizedBox(height: 12),

            // Text size
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_size, color: textColor, size: 20),
                      const SizedBox(width: 10),
                      Text(tr('textSize'), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('${(widget.textScale * 100).toInt()}%', style: TextStyle(color: subTextColor, fontSize: 13)),
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
                      Text('A', style: TextStyle(color: subTextColor, fontSize: 12)),
                      Text('A', style: TextStyle(color: subTextColor, fontSize: 20)),
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

            const SizedBox(height: 20),
            _buildAdminSection(textColor, cardColor, subTextColor),

            const SizedBox(height: 40),
            Center(
              child: Text('© 2026 Idan Amrani. All rights reserved.',
                  style: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 10)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection(Color textColor, Color cardColor, Color subTextColor) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _toggleAdminSection,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: Theme.of(context).primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Text('מפתחות API (פרטי)', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                  const Spacer(),
                  Icon(_adminSectionOpen ? Icons.expand_less : Icons.expand_more, color: subTextColor),
                ],
              ),
            ),
          ),
          if (_adminSectionOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _adminToken == null
                  ? _buildAdminLoginForm(textColor, subTextColor)
                  : _buildAdminKeysForm(textColor, subTextColor),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminLoginForm(Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _adminStatusLoaded && !_adminConfigured
              ? 'הגדר סיסמת ניהול (לפחות 8 תווים) - תישאר רק אצלך'
              : 'הכנס את סיסמת הניהול כדי לערוך את מפתחות ה-API',
          style: TextStyle(color: subTextColor, fontSize: 12),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _adminPasswordController,
          obscureText: true,
          style: TextStyle(color: textColor),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            hintText: 'סיסמה',
          ),
          onSubmitted: (_) => _submitAdminPassword(),
        ),
        const SizedBox(height: 10),
        if (_adminError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_adminError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _adminBusy ? null : _submitAdminPassword,
            child: Text(_adminBusy
                ? '...'
                : (_adminStatusLoaded && !_adminConfigured ? 'הגדר סיסמה' : 'התחבר')),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminKeysForm(Color textColor, Color subTextColor) {
    Widget field(TextEditingController controller, String label, String masked) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            labelText: label,
            hintText: masked.isNotEmpty ? 'נוכחי: $masked' : 'לא הוגדר',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('הזן ערך חדש רק בשדה שברצונך לעדכן', style: TextStyle(color: subTextColor, fontSize: 12)),
        const SizedBox(height: 10),
        field(_finnhubController, 'FINNHUB_KEY', _finnhubMasked),
        field(_groqController, 'GROQ_KEY', _groqMasked),
        field(_geminiController, 'GEMINI_KEY', _geminiMasked),
        if (_adminError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_adminError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        if (_adminMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_adminMessage!, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _adminBusy ? null : _saveAdminKeys,
                child: Text(_adminBusy ? '...' : 'שמור'),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => setState(() => _adminToken = null),
              child: const Text('נעל'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextPreset(String label, double scale, Color textColor, Color cardColor) {
    final isActive = (widget.textScale - scale).abs() < 0.05;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTextScaleChanged(scale),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).primaryColor.withOpacity(0.2) : cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isActive ? Theme.of(context).primaryColor : textColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<double>? data;
  final bool isPositive;

  _MiniChartPainter({this.data, this.isPositive = true});

  @override
  void paint(Canvas canvas, Size size) {
    List<double> points = data != null && data!.isNotEmpty
        ? data!
        : [0.75, 0.68, 0.72, 0.5, 0.47, 0.33, 0.37, 0.25, 0.17, 0.13];

    double maxVal = points.reduce((a, b) => a > b ? a : b);
    double minVal = points.reduce((a, b) => a < b ? a : b);
    double range = maxVal - minVal;
    if (range == 0) range = 1;

    List<double> normalizedPoints = data != null
        ? points.map((p) => 1.0 - ((p - minVal) / range)).toList()
        : points;

    final color = isPositive ? const Color(0xFF4ade80) : const Color(0xFFf87171);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < normalizedPoints.length; i++) {
      final x = (i / (normalizedPoints.length - 1)) * size.width;
      final y = normalizedPoints[i] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// נקודת LIVE פועמת - אנימציה עדינה
class _PulsingLiveDot extends StatefulWidget {
  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
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

    final Color color = isOpen ? const Color(0xFF4ade80) : const Color(0xFFf87171);
    final String label = isOpen ? 'LIVE' : 'CLOSED';

    Widget dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

// צייר טבעת הציון של Finova
class _ScoreRingPainter extends CustomPainter {
  final int score;
  final Color color;
  _ScoreRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    // רקע מלא
    canvas.drawCircle(center, radius, bgPaint);
    // קשת לפי הציון (מתחיל מלמעלה, -90 מעלות)
    final sweep = (score / 100.0) * 2 * 3.1415926535;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}