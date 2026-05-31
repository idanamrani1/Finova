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
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        cardColor: Colors.white,
        primaryColor: const Color(0xFF4F6AF5),
        iconTheme: const IconThemeData(color: Colors.black87),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black45),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A24),
        cardColor: const Color(0xFF23232F),
        primaryColor: const Color(0xFF4F6AF5),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Color(0xFF888899)),
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
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isNotFound = true;
          analysisData = null;
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
          height: 60,
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
            Icon(icon, size: 24, color: isSelected ? active : inactive),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, color: isSelected ? active : inactive)),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(symbol, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(6)),
                        child: Text('NASDAQ', style: TextStyle(fontSize: 11, color: subTextColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(currentPrice, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: changeBgColor, borderRadius: BorderRadius.circular(8)),
                        child: Text(changeText, style: TextStyle(color: changeColor, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      // אינדיקטור LIVE
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: Color(0xFF4ade80), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text('LIVE', style: const TextStyle(color: Color(0xFF4ade80), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMiniChart(),
                  const SizedBox(height: 14),
                ] else ...[
                  Text('Research Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text('20-Point Fundamental Engine', style: TextStyle(fontSize: 12, color: subTextColor)),
                  const SizedBox(height: 14),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search ticker (e.g. TSLA)',
                      hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: subTextColor),
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
      height: 60,
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
    final keyEvents = (aiBrief['keyEvents'] as List?) ?? [];
    final companies = (aiBrief['dramaticCompanies'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // כותרת היום
          Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: Theme.of(context).primaryColor, size: 26),
              const SizedBox(width: 8),
              Text('חדשות הבוקר', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          Text(date, style: TextStyle(fontSize: 13, color: subTextColor)),
          const SizedBox(height: 16),

          // כותרת דרמטית
          if (headline.toString().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor.withOpacity(0.3), Theme.of(context).primaryColor.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(headline.toString(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, height: 1.4)),
            ),
          const SizedBox(height: 20),

          // מדדים
          Text('מדדים מרכזיים', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: markets.entries.map((entry) {
              final data = entry.value as Map<String, dynamic>;
              final price = data['price'] ?? 0;
              final change = (data['change'] as num?)?.toDouble() ?? 0;
              return _buildMarketCard(entry.key, price, change);
            }).toList(),
          ),
          const SizedBox(height: 20),

          // אירועים מרכזיים
          if (keyEvents.isNotEmpty) ...[
            Text('אירועים מרכזיים השבוע', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
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
            const SizedBox(height: 20),
          ],

          // חברות עם שינוי דרמטי
          if (companies.isNotEmpty) ...[
            Text('חברות בכותרות', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            ...companies.map((c) {
              final company = c as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(company['ticker']?.toString() ?? '',
                                style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text(company['name']?.toString() ?? '',
                              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
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
          _buildRecommendationCard(),
          const SizedBox(height: 16),
          _buildSectionTitle('Key Statistics'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _buildStatCardNew(Icons.show_chart, '1-Year Return', analysisData!['oneYearReturn'] ?? 'N/A'),
              _buildStatCardNew(Icons.calculate_outlined, 'P/E Ratio', analysisData!['peRatio'] ?? 'N/A'),
              _buildStatCardNew(Icons.account_balance_outlined, 'Market Cap', analysisData!['marketCap'] ?? 'N/A'),
              _buildStatCardNew(Icons.swap_vert, '52W Range', analysisData!['fiftyTwoWeekRange'] ?? 'N/A'),
              _buildStatCardNew(Icons.timeline, 'Beta', analysisData!['beta'] ?? 'N/A'),
              _buildStatCardNew(Icons.percent, 'Div Yield', analysisData!['dividendYield'] ?? 'N/A'),
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

  Widget _buildRecommendationCard() {
    final rec = analysisData!['finalRecommendation'] ?? 'N/A';
    final verdict = analysisData!['verdict'] ?? 'N/A';
    final confidence = analysisData!['confidenceLevel'] ?? 'N/A';
    final isBullish = verdict.toLowerCase().contains('bullish') || rec.toLowerCase().contains('buy');

    return GestureDetector(
      onTap: _showRecommendationReason,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isBullish ? const Color(0xFF1a3a2a) : const Color(0xFF3a1a1a),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isBullish ? const Color(0xFF2a5a3a) : const Color(0xFF5a2a2a), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(isBullish ? Icons.trending_up : Icons.trending_down,
                color: isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171), size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('AI Recommendation',
                          style: TextStyle(color: isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171), fontSize: 11)),
                      const SizedBox(width: 4),
                      Icon(Icons.info_outline, size: 12, color: (isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171)).withOpacity(0.7)),
                    ],
                  ),
                  Text(rec,
                      style: TextStyle(
                          color: isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171),
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Tap for details',
                      style: TextStyle(color: (isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171)).withOpacity(0.6), fontSize: 9)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBullish ? const Color(0xFF2a5a3a) : const Color(0xFF5a2a2a),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(verdict,
                      style: TextStyle(color: isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171), fontSize: 11)),
                ),
                const SizedBox(height: 4),
                Text('$confidence confidence', style: const TextStyle(color: Color(0xFF888899), fontSize: 10)),
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

    return GestureDetector(
      onTap: hasExplanation ? () => _showTermExplanation(label) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Theme.of(context).primaryColor),
                if (hasExplanation) ...[
                  const Spacer(),
                  Icon(Icons.help_outline, size: 13, color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.5)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium!.color)),
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