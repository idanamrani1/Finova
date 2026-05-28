import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  void toggleTheme(bool isDark) {
    setState(() {
      isDarkMode = isDark;
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
      home: DashboardScreen(onThemeChanged: toggleTheme, isDarkMode: isDarkMode),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const DashboardScreen({super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  int _selectedIndex = 0;
  String symbol = "NVDA";
  String currentPrice = "...";
  bool isLoading = false;
  bool isNotFound = false;
  Map<String, dynamic>? analysisData;

  final List<String> popularTickers = ['NVDA', 'AAPL', 'MSFT', 'PLTR', 'UBER', 'TSLA'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchStockData(symbol);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchStockData(String ticker) async {
    if (ticker.isEmpty) return;
    setState(() {
      isLoading = true;
      isNotFound = false;
    });

    final url = Uri.parse(
      'https://equity-research-backend.onrender.com/api/analyze/${ticker.trim().toUpperCase()}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          symbol = data['symbol'];
          currentPrice = '\$${data['currentPrice']}';
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
        return _buildVaultScreen();
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
              _buildNavItem(Icons.lock_outline_rounded, 'Vault', 1, primary, subColor),
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
        onTap: () => setState(() => _selectedIndex = index),
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
                      Text(symbol,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
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
                      Text(currentPrice,
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a3a2a),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('+2.4%', style: TextStyle(color: Color(0xFF4ade80), fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMiniChart(),
                  const SizedBox(height: 14),
                ] else ...[
                  Text('Research Dashboard',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
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
          // Copyright footer
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _MiniChartPainter(),
          child: const SizedBox.expand(),
        ),
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

  Widget _buildRecommendationCard() {
    final rec = analysisData!['finalRecommendation'] ?? 'N/A';
    final verdict = analysisData!['verdict'] ?? 'N/A';
    final confidence = analysisData!['confidenceLevel'] ?? 'N/A';
    final isBullish = verdict.toLowerCase().contains('bullish') || rec.toLowerCase().contains('buy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBullish ? const Color(0xFF1a3a2a) : const Color(0xFF3a1a1a),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBullish ? const Color(0xFF2a5a3a) : const Color(0xFF5a2a2a),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBullish ? Icons.trending_up : Icons.trending_down,
            color: isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171),
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Recommendation',
                    style: TextStyle(
                        color: isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171),
                        fontSize: 11)),
                Text(rec,
                    style: TextStyle(
                        color: isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171),
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
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
                    style: TextStyle(
                        color: isBullish ? const Color(0xFF4ade80) : const Color(0xFFf87171),
                        fontSize: 11)),
              ),
              const SizedBox(height: 4),
              Text('$confidence confidence',
                  style: const TextStyle(color: Color(0xFF888899), fontSize: 10)),
            ],
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.bold)),
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
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.toString(),
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                          fontSize: 13,
                          height: 1.4)),
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

  Widget _buildVaultScreen() {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    final subTextColor = Theme.of(context).textTheme.bodySmall!.color!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Encrypted Vault', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text('AES-256 Local Encryption Storage', style: TextStyle(fontSize: 13, color: subTextColor)),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(Icons.enhanced_encryption_outlined, size: 80, color: subTextColor.withOpacity(0.4)),
                  const SizedBox(height: 20),
                  Text('Vault is locked.', style: TextStyle(fontSize: 18, color: textColor)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.lock_open_outlined, size: 18),
                    label: const Text('Unlock with Master Key'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                '© 2025 Idan Amrani. All rights reserved.',
                style: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 10),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
              child: Text(
                '© 2025 Idan Amrani. All rights reserved.',
                style: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 10),
              ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 24),
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
            const Spacer(),
            Center(
              child: Text(
                '© 2025 Idan Amrani. All rights reserved.',
                style: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 10),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [0.75, 0.68, 0.72, 0.5, 0.47, 0.33, 0.37, 0.25, 0.17, 0.13];
    final paint = Paint()
      ..color = const Color(0xFF4ade80)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4ade80).withOpacity(0.3),
          const Color(0xFF4ade80).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = points[i] * size.height;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
