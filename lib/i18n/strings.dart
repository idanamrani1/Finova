/// ───────────────────────────────────────────────────────────────────────────
/// מערכת תרגום - כל הטקסטים בממשק
///
/// טבלה שטוחה he/en, לא ARB/gen-l10n: האפליקציה עברה בין השפות האלה בלבד
/// ולא הייתה סיבה להביא tooling נפרד בשביל שתיים. הועבר לכאן מ-main.dart
/// כשהקובץ עבר את ה-6,700 שורות, כדי שתרגום חדש לא ידרוש לגלול דרך כל
/// הלוגיקה של המסכים כדי למצוא את טבלת המחרוזות.
/// ───────────────────────────────────────────────────────────────────────────

class T {
  static const Map<String, Map<String, String>> _s = {
    'research': {'he': 'Research', 'en': 'Research'},
    'dailyBrief': {'he': 'סיכום יומי', 'en': 'Daily Brief'},
    'alerts': {'he': 'התראות', 'en': 'Alerts'},
    'settings': {'he': 'הגדרות', 'en': 'Settings'},
    'searchHint': {
      'he': 'חפש מניה (שם או סימול)',
      'en': 'Search stock (name or ticker)',
    },
    'researchSubtitle': {
      'he': 'מנוע ניתוח פונדמנטלי',
      'en': '20-Point Fundamental Engine',
    },
    'summary': {'he': 'סיכום', 'en': 'Summary'},
    'fundamentals': {'he': 'פונדמנטלי', 'en': 'Fundamentals'},
    'catalysts': {'he': 'קטליזטורים', 'en': 'Catalysts'},
    'finovaScore': {'he': 'ציון FINOVA', 'en': 'FINOVA SCORE'},
    'quality': {'he': 'איכות', 'en': 'Quality'},
    'weakest': {'he': 'הנקודה החלשה', 'en': 'Weakest'},
    'value': {'he': 'מחיר', 'en': 'Value'},
    'growth': {'he': 'צמיחה', 'en': 'Growth'},
    'risk': {'he': 'סיכון', 'en': 'Risk'},
    'tapForBreakdown': {
      'he': 'הקש לפירוט מלא של הציון',
      'en': 'Tap for full score breakdown',
    },
    'scoreBreakdownTitle': {
      'he': 'ממה מורכב הציון',
      'en': 'How the score is built',
    },
    'scoreBreakdownSub': {
      'he': 'כל מדד מבוסס על נתון אמיתי',
      'en': 'Each metric is based on real data',
    },
    'scoreWeights': {
      'he':
          'הציון הכולל הוא ממוצע משוקלל: איכות 35%, צמיחה 25%, מחיר 20%, סיכון 20%. איכות מקבלת משקל גבוה כי חברה מעולה ביוקר עדיפה על חברה חלשה בזול.',
      'en':
          'The total is a weighted average: Quality 35%, Growth 25%, Value 20%, Risk 20%. Quality is weighted higher because a great company at a high price beats a weak one at a low price.',
    },
    'gotIt': {'he': 'הבנתי', 'en': 'Got it'},
    'keyStatistics': {'he': 'נתונים מרכזיים', 'en': 'Key Statistics'},
    'aiRecommendation': {'he': 'המלצת AI', 'en': 'AI RECOMMENDATION'},
    'disclaimerShort': {
      'he': 'לא ייעוץ השקעות. למידע בלבד.',
      'en': 'Not investment advice. For information only.',
    },
    'disclaimerFull': {
      'he':
          'התוכן באפליקציה נוצר אוטומטית על ידי בינה מלאכותית ומבוסס על נתוני שוק ממקורות חיצוניים. הוא אינו מהווה ייעוץ השקעות, שיווק השקעות או המלצה לביצוע פעולה בניירות ערך, ואינו מתחשב בנתונים או בצרכים האישיים שלך. ייתכנו טעויות, אי-דיוקים ועיכובים בנתונים. כל החלטת השקעה היא באחריותך בלבד.',
      'en':
          'Content in this app is generated automatically by AI from third-party market data. It is not investment advice, a solicitation, or a recommendation to buy or sell any security, and does not account for your personal circumstances. Data may be inaccurate, incomplete, or delayed. Any investment decision is solely your own responsibility.',
    },
    'disclaimerTitle': {'he': 'הבהרה משפטית', 'en': 'Disclaimer'},
    'verdict': {'he': 'הערכה', 'en': 'VERDICT'},
    'confidence': {'he': 'ביטחון', 'en': 'CONFIDENCE'},
    'tapForDetails': {'he': 'הקש לפרטים', 'en': 'Tap for details'},
    'dailyBriefTitle': {'he': 'הסיכום היומי', 'en': 'Daily Brief'},
    'editionMorning': {'he': 'מהדורת בוקר', 'en': 'Morning edition'},
    'editionClose': {'he': 'מהדורת נעילה', 'en': 'Closing edition'},
    'editionIntraday': {'he': 'מהדורת מסחר', 'en': 'Intraday edition'},
    'updatedAt': {'he': 'עודכן', 'en': 'Updated'},
    'myStocks': {'he': 'המניות שלי', 'en': 'My stocks'},
    'myStocksEmpty': {
      'he': 'הוסף התראות מחיר ותראה כאן איך המניות שלך זזות',
      'en': 'Add price alerts and your stocks will show up here',
    },
    'sourcesTitle': {'he': 'מקורות', 'en': 'Sources'},
    'archiveTitle': {'he': 'סיכומים קודמים', 'en': 'Previous briefs'},
    'archiveEmpty': {
      'he': 'אין עדיין סיכומים קודמים',
      'en': 'No previous briefs yet',
    },
    'bigHeadline': {'he': 'הכותרת הגדולה היום', 'en': "TODAY'S BIG STORY"},
    'keyMarkets': {'he': 'מדדים מרכזיים', 'en': 'Key Markets'},
    'whatMovesWorld': {'he': 'מה מזיז את העולם', 'en': 'What Moves the World'},
    'finovaInsight': {'he': 'התובנה של Finova: ', 'en': 'Finova Insight: '},
    'companiesInHeadlines': {
      'he': 'חברות בכותרות',
      'en': 'Companies in the Headlines',
    },
    'loadingBrief': {
      'he': 'טוען את הסיכום היומי...',
      'en': 'Loading daily brief...',
    },
    'briefError': {'he': 'שגיאה בטעינת הסיכום', 'en': 'Error loading brief'},
    'retry': {'he': 'נסה שוב', 'en': 'Retry'},
    'darkMode': {'he': 'מצב כהה', 'en': 'Dark Mode'},
    'language': {'he': 'שפה', 'en': 'Language'},
    'textSize': {'he': 'גודל טקסט', 'en': 'Text Size'},
    'small': {'he': 'קטן', 'en': 'Small'},
    'normal': {'he': 'רגיל', 'en': 'Normal'},
    'large': {'he': 'גדול', 'en': 'Large'},
    'notFound': {'he': 'לא נמצאה מניה כזו', 'en': 'No such stock found'},
    'notFoundHint': {
      'he': 'בדוק את הסימבול ונסה שוב, או חפש לפי שם החברה',
      'en': 'Check the symbol, or search by company name instead',
    },
    'analysisError': {
      'he': 'לא הצלחנו לטעון את הניתוח כרגע',
      'en': "Couldn't load the analysis right now",
    },
    'analysisErrorHint': {
      'he': 'זה בדרך כלל זמני - נסה שוב בעוד רגע',
      'en': 'This is usually temporary - try again in a moment',
    },
    'analyzing': {'he': 'מנתח...', 'en': 'Analyzing...'},
    'stageFetching': {
      'he': 'מושך נתוני שוק...',
      'en': 'Fetching market data...',
    },
    'stageAnalyzing': {
      'he': 'מנתח עם בינה מלאכותית...',
      'en': 'Analyzing with AI...',
    },
    'stageScoring': {
      'he': 'מחשב את ציון Finova...',
      'en': 'Calculating Finova score...',
    },
    'stageAlmost': {'he': 'עוד רגע...', 'en': 'Almost there...'},
    'searchToStart': {
      'he': 'חפש מניה כדי להתחיל',
      'en': 'Search a stock to start',
    },
    'noAlerts': {'he': 'אין התראות עדיין', 'en': 'No alerts yet'},
    'addAlertHint': {
      'he': 'הוסף התראה ראשונה למעלה',
      'en': 'Add your first alert above',
    },
    'alertTicker': {'he': 'טיקר', 'en': 'Ticker'},
    'alertPrice': {'he': 'מחיר יעד', 'en': 'Target price'},
    'alertAbove': {'he': 'מעל', 'en': 'Above'},
    'alertBelow': {'he': 'מתחת', 'en': 'Below'},
    'addAlert': {'he': 'הוסף התראה', 'en': 'Add Alert'},
    'alertActive': {'he': 'פעיל', 'en': 'Active'},
    'alertTriggered': {'he': 'הופעל', 'en': 'Triggered'},
    'crossedAbove': {'he': 'עבר מעל', 'en': 'crossed above'},
    'crossedBelow': {'he': 'ירד מתחת ל', 'en': 'dropped below'},
    'pushTitle': {'he': 'התראות לנייד', 'en': 'Push notifications'},
    'pushOnHint': {
      'he': 'פעיל - תקבל התראה גם כשהאפליקציה סגורה',
      'en': "On - you'll be notified even when the app is closed",
    },
    'pushOffHint': {
      'he': 'כרגע ההתראות עובדות רק כשהאפליקציה פתוחה',
      'en': 'Right now alerts only work while the app is open',
    },
    'pushEnable': {'he': 'הפעל התראות', 'en': 'Enable'},
    'pushDisable': {'he': 'כבה', 'en': 'Turn off'},
    'pushEnabled': {'he': 'התראות הופעלו', 'en': 'Notifications enabled'},
    'pushDenied': {
      'he': 'ההרשאה נדחתה - יש לאפשר התראות בהגדרות הדפדפן',
      'en': 'Permission denied - allow notifications in your browser settings',
    },
    'pushFailed': {
      'he': 'הפעלת ההתראות נכשלה',
      'en': 'Could not enable notifications',
    },
    'pushUnsupported': {
      'he':
          'הדפדפן הזה לא תומך בהתראות. באייפון: הוסף את האתר למסך הבית ופתח אותו משם.',
      'en':
          'This browser does not support notifications. On iPhone: add the site to your Home Screen and open it from there.',
    },
    'currentPriceLabel': {'he': 'מחיר נוכחי', 'en': 'Current'},
    'close': {'he': 'סגור', 'en': 'Close'},
    'whyRec': {'he': 'למה', 'en': 'Why'},
    'alertsSubtitle': {
      'he': 'התראות מחיר וחדשות',
      'en': 'Price & news notifications',
    },
    'apiKeysPrivate': {'he': 'מפתחות API (פרטי)', 'en': 'API Keys (private)'},
    'password': {'he': 'סיסמה', 'en': 'Password'},
    'setPassword': {'he': 'הגדר סיסמה', 'en': 'Set password'},
    'login': {'he': 'התחבר', 'en': 'Log in'},
    'save': {'he': 'שמור', 'en': 'Save'},
    'lock': {'he': 'נעל', 'en': 'Lock'},
    'savedOk': {'he': 'נשמר בהצלחה', 'en': 'Saved'},
    'saveFailed': {'he': 'שמירה נכשלה', 'en': 'Save failed'},
    'wrongPassword': {'he': 'סיסמה שגויה', 'en': 'Wrong password'},
    'tooManyAttempts': {
      'he': 'יותר מדי ניסיונות, נסה שוב בעוד כמה דקות',
      'en': 'Too many attempts, try again in a few minutes',
    },
    'connectionError': {'he': 'שגיאת חיבור לשרת', 'en': 'Connection error'},
    'sessionExpired': {
      'he': 'ההתחברות פגה, יש להתחבר שוב',
      'en': 'Session expired, please log in again',
    },
    'setPasswordHint': {
      'he': 'הגדר סיסמת ניהול (לפחות 8 תווים) - תישאר רק אצלך',
      'en': 'Set an admin password (min 8 characters) - stays only with you',
    },
    'enterPasswordHint': {
      'he': 'הכנס את סיסמת הניהול כדי לערוך את מפתחות ה-API',
      'en': 'Enter the admin password to edit the API keys',
    },
    'onlyFillToChange': {
      'he': 'הזן ערך חדש רק בשדה שברצונך לעדכן',
      'en': 'Only fill in a field you want to change',
    },
    'notSet': {'he': 'לא הוגדר', 'en': 'Not set'},
    'currentMasked': {'he': 'נוכחי', 'en': 'Current'},
    'upcomingEvents': {'he': 'אירועים צפויים', 'en': 'Upcoming Events'},
    'investmentThesis': {'he': 'תזת השקעה', 'en': 'Investment Thesis'},
    'catalystsTitle': {'he': 'קטליזטורים', 'en': 'Catalysts'},
    'fundamentalAnalysis': {
      'he': 'ניתוח פונדמנטלי',
      'en': 'Fundamental Analysis',
    },
    'revenueGrowthT': {'he': 'צמיחת הכנסות', 'en': 'Revenue Growth'},
    'marginsTrendT': {'he': 'מגמת מרווחים', 'en': 'Margins Trend'},
    'valuationT': {'he': 'תמחור מול מתחרים', 'en': 'Valuation vs Peers'},
    'freeCashFlowT': {'he': 'תזרים מזומנים חופשי', 'en': 'Free Cash Flow'},
    'investmentSummary': {'he': 'סיכום השקעה', 'en': 'Investment Summary'},
    'keyCatalyst': {'he': 'קטליזטור מרכזי', 'en': 'Key Catalyst'},

    // ── מסך הבית והניווט החדש ──
    'back': {'he': 'חזרה', 'en': 'Back'},
    'removeAlert': {'he': 'מחק התראה', 'en': 'Delete alert'},
    'adminPanel': {'he': 'פאנל ניהול', 'en': 'Admin panel'},
    'adminPanelSub': {
      'he': 'מפתחות API והגדרות שרת - למנהל בלבד',
      'en': 'API keys and server settings - admin only',
    },
    'logout': {'he': 'יציאה', 'en': 'Log out'},
    'adminSecurityNote': {
      'he': 'ניסיונות התחברות חוזרים נחסמים אוטומטית',
      'en': 'Repeated failed attempts are blocked automatically',
    },
    'discordAlerts': {'he': 'התראות בדיסקורד', 'en': 'Discord alerts'},
    'discordAlertsSub': {
      'he':
          'כתובת Webhook לערוץ בדיסקורד - נשלחת אליה הודעה כשיש תקלה אמיתית '
          'בשרת, ועוד הודעה כשהיא מפסיקה לחזור',
      'en':
          "A Discord channel's webhook URL - gets a message when a real "
          'server issue happens, and another when it stops recurring',
    },
    'sendTestAlert': {'he': 'שלח הודעת בדיקה', 'en': 'Send test alert'},
    'discordTestSent': {
      'he': 'נשלח! תבדוק בערוץ הדיסקורד',
      'en': 'Sent! Check the Discord channel',
    },
    'discordTestFailed': {
      'he': 'השליחה נכשלה - ודא שכתובת ה-Webhook נכונה',
      'en': 'Send failed - check that the webhook URL is correct',
    },
    'discordNotConfigured': {
      'he': 'שמור כתובת Webhook קודם',
      'en': 'Save a webhook URL first',
    },
    'privacyPolicy': {'he': 'מדיניות פרטיות', 'en': 'Privacy policy'},
    'privacyPolicySub': {
      'he': 'איזה מידע נשמר, למה, ואיך למחוק אותו',
      'en': 'What is stored, why, and how to delete it',
    },
    'termsOfUse': {'he': 'תנאי שימוש', 'en': 'Terms of use'},
    'termsOfUseSub': {
      'he': 'האתר אינו ייעוץ השקעות - קרא לפני שאתה מסתמך על ניתוח',
      'en': 'Not investment advice - read before relying on any analysis',
    },
    'accessibilityStatement': {
      'he': 'הצהרת נגישות',
      'en': 'Accessibility statement',
    },
    'accessibilityStatementSub': {
      'he': 'רמת הנגישות של האתר ואיך לדווח על תקלה',
      'en': "The site's accessibility level and how to report a problem",
    },
    'priceChartLabel': {
      'he': 'גרף מחיר, {n} ימי מסחר אחרונים',
      'en': 'Price chart, last {n} trading days',
    },
    'clearSearch': {'he': 'נקה חיפוש', 'en': 'Clear search'},
    'tabHome': {'he': 'בית', 'en': 'Home'},
    'tabMarket': {'he': 'שוק', 'en': 'Market'},
    'tabSearch': {'he': 'חיפוש', 'en': 'Search'},
    'tabWatchlist': {'he': 'מעקב', 'en': 'Watchlist'},
    'tabMore': {'he': 'עוד', 'en': 'More'},
    'greetMorning': {'he': 'בוקר טוב', 'en': 'Good morning'},
    'greetNoon': {'he': 'צהריים טובים', 'en': 'Good afternoon'},
    'greetEvening': {'he': 'ערב טוב', 'en': 'Good evening'},
    'homeSubtitle': {
      'he': 'הנה מה שה-AI חושב שחשוב לך היום',
      'en': "Here's what the AI thinks matters to you today",
    },
    'homeSearchHint': {
      'he': 'חפש מניה, נושא או שאלה...',
      'en': 'Search a stock, topic or question...',
    },
    'topOpportunity': {'he': 'הזדמנות מובילה', 'en': 'Top opportunity'},
    'latestAnalysis': {'he': 'הניתוח האחרון שלך', 'en': 'Your latest analysis'},
    'watchlist': {'he': 'רשימת מעקב', 'en': 'Watchlist'},
    'follow': {'he': 'עקוב', 'en': 'Follow'},
    'following': {'he': 'במעקב', 'en': 'Following'},
    'watchlistEmpty': {
      'he': 'עוד לא סימנת מניות למעקב',
      'en': 'You are not following any stocks yet',
    },
    'watchlistEmptyHint': {
      'he': 'פתח מניה בחיפוש והקש על "עקוב"',
      'en': 'Open a stock in Search and tap "Follow"',
    },
    'priceAlerts': {'he': 'התראות מחיר', 'en': 'Price alerts'},
    'aiScore': {'he': 'AI Score', 'en': 'AI Score'},
    'dailyChangeShort': {'he': 'שינוי היום', 'en': 'Today'},
    'aiRecShort': {'he': 'המלצת AI', 'en': 'AI call'},
    'whyQ': {'he': 'למה?', 'en': 'Why?'},
    'readFullAnalysis': {'he': 'קרא ניתוח מלא', 'en': 'Read full analysis'},
    'todayOpportunities': {'he': 'הזדמנויות היום', 'en': "Today's picks"},
    'updatedJustNow': {'he': 'עודכן עכשיו', 'en': 'Updated just now'},
    'updatedMinutesAgo': {
      'he': 'עודכן לפני {n} דקות',
      'en': 'Updated {n} min ago',
    },
    'updatedHoursAgo': {'he': 'עודכן לפני {n} שעות', 'en': 'Updated {n}h ago'},
    'homeNoAnalysis': {
      'he': 'עוד לא ניתחנו מניה',
      'en': 'No stock analysed yet',
    },
    'homeNoAnalysisHint': {
      'he': 'חפש מניה והניתוח יופיע כאן',
      'en': 'Search a stock and the analysis will show up here',
    },
    'analyseNow': {'he': 'נתח מניה', 'en': 'Analyse a stock'},
    'loadingHome': {'he': 'טוען...', 'en': 'Loading...'},
    'notificationsAria': {'he': 'התראות', 'en': 'Notifications'},
    'profileAria': {'he': 'פרופיל', 'en': 'Profile'},
    'yourName': {'he': 'השם שלך', 'en': 'Your name'},
    'yourNameHint': {
      'he': 'מופיע בברכה במסך הבית',
      'en': 'Shown in the greeting on the home screen',
    },
  };

  static String get(String key, String lang) {
    return _s[key]?[lang] ?? _s[key]?['en'] ?? key;
  }
}
