import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finova',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F6FB),
        cardColor: Colors.white,
        primaryColor: const Color(0xFF6366F1),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF1A1A2E)),
          bodySmall: TextStyle(color: Color(0xFF8E8EA8)),
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
      home: DashboardScreen(
        onThemeChanged: toggleTheme,
        isDarkMode: isDarkMode,
        onTextScaleChanged: setTextScale,
        textScale: textScale,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;
  final Function(double) onTextScaleChanged;
  final double textScale;

  const DashboardScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
    required this.onTextScaleChanged,
    required this.textScale,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  int _selectedIndex = 0;
  String symbol = "NVDA";
  String currentPrice = "...";
  Timer? _priceTimer;

  double? dailyChange;
  List<double>? chartPrices;

  bool isLoading = false;
  bool isNotFound = false;
  Map<String, dynamic>? analysisData;
  Map<String, dynamic>? finovaScore;

  // Daily Brief state
  Map<String, dynamic>? dailyBriefData;
  bool isBriefLoading = false;
  bool briefError = false;

  final List<String> popularTickers = ['NVDA', 'AAPL', 'MSFT', 'PLTR', 'UBER', 'TSLA'];

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
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchStockData(String ticker) async {
    if (ticker.isEmpty) return;
    setState(() {
      isLoading = true;
      isNotFound = false;
      dailyChange = null;
      chartPrices = null;
    });

    final url = Uri.parse(
      'https://equity-research-backend.onrender.com/api/analyze/${ticker.trim().toUpperCase()}',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          symbol = data['symbol'];
          currentPrice = '\$${data['currentPrice']}';
          dailyChange = data['dailyChange'] != null ? (data['dailyChange'] as num).toDouble() : null;
          if (data['chartData'] != null) {
            chartPrices = (data['chartData'] as List).map((e) => (e as num).toDouble()).toList();
          }
          analysisData = data['analysis'];
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
  Future<void> _refreshPrice(String ticker) async {
    final url = Uri.parse(
      'https://equity-research-backend.onrender.com/api/analyze/${ticker.trim().toUpperCase()}',
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

    final url = Uri.parse('https://equity-research-backend.onrender.com/api/daily-brief');

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
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
              _buildNavItem(Icons.bar_chart_rounded, 'Research', 0, primary, subColor),
              _buildNavItem(Icons.wb_sunny_outlined, 'סיכום יומי', 1, primary, subColor),
              _buildNavItem(Icons.notifications_outlined, 'Alerts', 2, primary, subColor),
              _buildNavItem(Icons.settings_outlined, 'Settings', 3, primary, subColor),
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
                          Text('Research',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.5)),
                          Text('20-Point Fundamental Engine',
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
                      hintText: 'Search ticker (e.g. TSLA)',
                      hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                    ),
                    onSubmitted: (value) {
                      _searchController.clear();
                      fetchStockData(value);
                    },
                  ),
                ),
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
                      tabs: const [
                        Tab(text: 'Summary'),
                        Tab(text: 'Fundamentals'),
                        Tab(text: 'Catalysts'),
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
                ? Center(child: Text('Search for an asset to begin.', style: TextStyle(color: subTextColor)))
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
              '© 2025 Idan Amrani. All rights reserved.',
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
        textDirection: TextDirection.rtl,
        child: isBriefLoading
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
            : briefError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 60, color: subTextColor),
              const SizedBox(height: 16),
              Text('הסיכום לא זמין כרגע', style: TextStyle(fontSize: 18, color: textColor)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => dailyBriefData = null);
                  fetchDailyBrief();
                },
                child: const Text('נסה שוב'),
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
                  Text('הסיכום היומי',
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
                    child: const Text('הכותרת הגדולה היום',
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
                        final isPos = change >= 0;
                        final c = isPos ? const Color(0xFF4ade80) : const Color(0xFFf87171);
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
                                Text(k, style: TextStyle(fontSize: 10, color: subTextColor)),
                                const SizedBox(height: 3),
                                Text('${isPos ? '+' : ''}${change.toStringAsFixed(2)}%',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
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

          // מה מזיז את העולם - חדשות מקוטלגות
          if (newsItems.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.public, color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 7),
                Text('מה מזיז את העולם',
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
                          const TextSpan(
                              text: 'התובנה של Finova: ',
                              style: TextStyle(fontWeight: FontWeight.w800)),
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
            Text('חברות בכותרות', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
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
            child: Text('© 2025 Idan Amrani. All rights reserved.',
                style: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // צבע לפי קטגוריית חדשות
  Color _categoryColor(String cat) {
    if (cat.contains('גיאופוליטיק') || cat.contains('אנרגיה')) return const Color(0xFFf87171);
    if (cat.contains('טכנולוגיה')) return const Color(0xFF4ade80);
    if (cat.contains('מאקרו')) return const Color(0xFF7C7FF2);
    return const Color(0xFFfbbf24); // שווקים / ברירת מחדל
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
          _buildSectionTitle('Key Statistics'),
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
          _buildSectionTitle('Fundamental Analysis'),
          _buildTextCardNew('Revenue Growth', analysisData!['revenueGrowth'] ?? 'N/A', const Color(0xFF4F6AF5)),
          const SizedBox(height: 10),
          _buildTextCardNew('Margins Trend', analysisData!['marginsTrend'] ?? 'N/A', const Color(0xFF4ade80)),
          const SizedBox(height: 10),
          _buildTextCardNew('Valuation vs Peers', analysisData!['valuationVsPeers'] ?? 'N/A', Colors.orangeAccent),
          const SizedBox(height: 10),
          _buildTextCardNew('Free Cash Flow', analysisData!['freeCashFlow'] ?? 'N/A', Colors.purpleAccent),
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
          _buildSectionTitle('Upcoming Events'),
          _buildListCardNew('Upcoming Events', analysisData!['upcomingEvents'], Icons.event_outlined, Colors.blueAccent),
          const SizedBox(height: 10),
          _buildSectionTitle('Investment Thesis'),
          _buildListCardNew('Investment Summary', analysisData!['thesisSummary'], Icons.lightbulb_outline, Colors.orangeAccent),
          const SizedBox(height: 10),
          _buildSectionTitle('Catalysts'),
          _buildTextCardNew('Key Catalyst', analysisData!['catalysts'] ?? 'N/A', Colors.tealAccent),
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
      {'name': 'איכות', 'val': (s['quality'] ?? 0) as int},
      {'name': 'מחיר', 'val': (s['value'] ?? 0) as int},
      {'name': 'צמיחה', 'val': (s['growth'] ?? 0) as int},
      {'name': 'סיכון', 'val': (s['risk'] ?? 0) as int},
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
          textDirection: TextDirection.rtl,
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
                        Text('ציון FINOVA',
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
                  Text('הקש לפירוט מלא של הציון',
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
        textDirection: TextDirection.rtl,
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
                            Text('ממה מורכב הציון',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).textTheme.bodyMedium!.color)),
                            Text('כל מדד מבוסס על נתון אמיתי',
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
                              'הציון הכולל הוא ממוצע משוקלל: איכות 35%, צמיחה 25%, מחיר 20%, סיכון 20%. איכות מקבלת משקל גבוה כי חברה מעולה ביוקר עדיפה על חברה חלשה בזול.',
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
                      child: const Text('הבנתי',
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
                          Text('AI RECOMMENDATION',
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
                      Text('VERDICT',
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
                      Text('CONFIDENCE',
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
                    Text('Tap for details',
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
        textDirection: TextDirection.rtl,
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
                    child: Text('הבנתי', style: TextStyle(color: Theme.of(context).primaryColor)),
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
    List<dynamic> items = listData != null ? List.from(listData) : ['No data available'];

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
                  child: Text(item.toString(),
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
          Icon(Icons.search_off_rounded, size: 64, color: subTextColor),
          const SizedBox(height: 16),
          Text('Ticker not found.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text('Please check the symbol and try again.', style: TextStyle(color: subTextColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAlertsScreen() {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alerts', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text('Price & news notifications', style: TextStyle(fontSize: 13, color: subTextColor)),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: subTextColor.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No alerts set yet.', style: TextStyle(fontSize: 18, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Coming soon.', style: TextStyle(color: subTextColor)),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Text('© 2025 Idan Amrani. All rights reserved.',
                  style: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 10)),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
            Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 24),

            // Dark mode
            Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
              child: SwitchListTile(
                title: Text('Dark Mode', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                subtitle: Text('Toggle visual appearance', style: TextStyle(color: subTextColor, fontSize: 12)),
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
                Text('Accessibility', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
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
                      Text('Text Size', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
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
                _buildTextPreset('קטן', 0.9, textColor, cardColor),
                const SizedBox(width: 10),
                _buildTextPreset('רגיל', 1.0, textColor, cardColor),
                const SizedBox(width: 10),
                _buildTextPreset('גדול', 1.2, textColor, cardColor),
              ],
            ),

            const SizedBox(height: 40),
            Center(
              child: Text('© 2025 Idan Amrani. All rights reserved.',
                  style: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 10)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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