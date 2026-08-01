import 'accessibility.dart' show AccessibilityInfo, LegalSection;

/// ───────────────────────────────────────────────────────────────────────────
/// מדיניות פרטיות
///
/// נדרשת לפי חוק הגנת הפרטיות, התשמ"א-1981, ובפרט לפי תיקון 13 שנכנס
/// לאכיפה באוגוסט 2025. הדרישות: אילו סוגי מידע נאספים ולאיזו מטרה, הבסיס
/// החוקי לאיסוף, צדדים שלישיים שהמידע מועבר אליהם, משך השמירה, וזכויות
/// העיון, התיקון והמחיקה של המשתמש.
///
/// כל סעיף כאן נגזר ממה שהקוד באמת עושה, ואומת מול:
///   • AlertService.cs   — מה נשמר בשרת ואיפה (/var/lib/finova/push_alerts.json)
///   • Program.cs        — כתובות IP בהגבלת קצב על התחברות מנהל
///   • main.dart         — מה נשמר מקומית ב-SharedPreferences
///   • תצורת nginx       — access.log ו-error.log, סבב של 14 יום
/// אין להצהיר כאן על מה שלא נבדק בקוד.
///
/// ⚠️ זה אינו ייעוץ משפטי. מומלץ שעורך/ת דין יעברו על הנוסח לפני פרסום.
/// ───────────────────────────────────────────────────────────────────────────
class PrivacyPolicy {
  const PrivacyPolicy._();

  static const String lastUpdated = '1 באוגוסט 2026';
  static const String lastUpdatedEn = '1 August 2026';

  static List<LegalSection> forLang(String lang) => lang == 'he' ? _he : _en;

  static const List<LegalSection> _he = [
    LegalSection('כללי', [
      'מדיניות זו מסבירה איזה מידע נאסף בעת השימוש באתר '
          '${AccessibilityInfo.siteName} (${AccessibilityInfo.siteUrl}), '
          'למה הוא נאסף, מה נעשה בו וכיצד ניתן להסירו. היא נכתבה בהתאם '
          'לחוק הגנת הפרטיות, התשמ"א-1981, לרבות תיקון 13 לחוק.',
      'עודכן לאחרונה: $lastUpdated.',
    ]),
    LegalSection(
      'מה האתר לא עושה',
      [],
      bullets: [
        'אין באתר הרשמה, חשבונות משתמש או סיסמאות למשתמשי קצה.',
        'איננו מבקשים ואיננו שומרים שם, כתובת דואר אלקטרוני או מספר טלפון.',
        'אין באתר קוקיז פרסומיים, פיקסלים של רשתות חברתיות או כלי '
            'אנליטיקה מסחריים, ואיננו מבצעים פרופיילינג.',
        'איננו מוכרים מידע ואיננו מעבירים אותו לצדדים שלישיים למטרות '
            'שיווק.',
        'איננו גובים תשלום ואיננו מקבלים פרטי אמצעי תשלום.',
      ],
    ),
    LegalSection(
      'המידע הנשמר במכשיר שלך בלבד',
      ['הפרטים הבאים נשמרים באחסון המקומי של הדפדפן ואינם נשלחים לשרת:'],
      bullets: [
        'שם התצוגה שהזנת במסך "עוד", שמשמש רק לברכה במסך הבית.',
        'העדפות התצוגה שלך: שפה, מצב כהה וגודל טקסט.',
        'עותק מקומי של רשימת התראות המחיר שהגדרת.',
        'ניקוי נתוני האתר בדפדפן מוחק את כל אלה לחלוטין.',
      ],
    ),
    LegalSection(
      'המידע הנשמר בשרת',
      [
        'מידע נשמר בשרת רק אם הפעלת התראות דחיפה. אם לא הפעלת אותן, '
            'לא נשמר עליך דבר בשרת מלבד רישומי השרת המפורטים בהמשך.',
        'כאשר מופעלות התראות דחיפה נשמרים:',
      ],
      bullets: [
        'כתובת ה-Endpoint של המנוי לדחיפה — כתובת ייחודית שמייצר '
            'הדפדפן שלך ומאפשרת לשלוח אליו התראה. היא מזהה את הדפדפן, '
            'לא אותך בשמך.',
        'שני מפתחות הצפנה (P256dh ו-Auth) שהדפדפן מייצר, שבלעדיהם לא '
            'ניתן להצפין את תוכן ההתראה עבורו.',
        'רשימת התראות המחיר: סימול המניה, מעל או מתחת, מחיר היעד, האם '
            'ההתראה כבר הופעלה, המחיר האחרון שנבדק ומועד היצירה.',
        'העדפת השפה, כדי שההתראה תישלח בשפה הנכונה.',
        'מונה כשלי שליחה, לצורך ניקוי מנויים מתים.',
      ],
    ),
    LegalSection('היכן וכיצד המידע מאוחסן', [
      'המידע נשמר בקובץ יחיד בשרת שלנו '
          '(/var/lib/finova/push_alerts.json), בהרשאות קריאה וכתיבה '
          'למשתמש המערכת של השירות בלבד. השרת ממוקם באירופה. כל התעבורה '
          'לאתר מוצפנת ב-HTTPS באמצעות תעודת Let\'s Encrypt.',
    ]),
    LegalSection('רישומי שרת', [
      'כמו בכל שרת אינטרנט, נשמרים רישומי גישה טכניים הכוללים כתובת IP, '
          'מועד הפנייה, הכתובת שנתבקשה וסוג הדפדפן. הם משמשים לאבחון '
          'תקלות ולהגנה מפני שימוש לרעה, ונמחקים אוטומטית לאחר 14 יום.',
      'בנוסף, בעת ניסיון התחברות לפאנל הניהול נשמרת כתובת ה-IP בזיכרון '
          'לזמן קצר, לצורך חסימת ניסיונות חוזרים בלבד.',
    ]),
    LegalSection(
      'מטרות השימוש והבסיס החוקי',
      [],
      bullets: [
        'משלוח התראת מחיר שביקשת — הבסיס הוא הסכמתך המפורשת, שניתנה '
            'כשאישרת לדפדפן לשלוח התראות והגדרת התראה.',
        'הצגת השירות והתאמתו לשפה ולהעדפות התצוגה שלך — ביצוע השירות '
            'שביקשת.',
        'אבטחת המערכת, מניעת שימוש לרעה ואבחון תקלות — אינטרס לגיטימי.',
      ],
    ),
    LegalSection(
      'צדדים שלישיים',
      [
        'איננו מעבירים את פרטיך לגורמים מסחריים. עם זאת, לצורך הפעלת '
            'השירות מעורבים הגורמים הבאים:',
      ],
      bullets: [
        'שירות הדחיפה של הדפדפן שלך (Google, Mozilla או Apple, לפי '
            'הדפדפן) — מקבל את ההתראה כדי להעביר אותה למכשירך. תוכן '
            'ההתראה מוצפן.',
        'Finnhub — ספק נתוני שוק ולוגואים של חברות. מקבל את סימול המניה '
            'המבוקש בלבד, בפנייה מהשרת שלנו. כתובת ה-IP שלך אינה מועברת.',
        'Yahoo Finance — היסטוריית מחירים. גם כאן הפנייה יוצאת מהשרת '
            'שלנו ולא ממכשירך.',
        'Google Gemini ו-Groq — מנועי הבינה המלאכותית שמפיקים את הניתוח. '
            'הם מקבלים את סימול המניה ואת נתוני השוק שלה בלבד, ולא מידע '
            'מזהה עליך.',
      ],
    ),
    LegalSection(
      'משך השמירה',
      [],
      bullets: [
        'מנוי הדחיפה וההתראות נשמרים כל עוד ההתראות פעילות אצלך.',
        'כיבוי ההתראות במסך "מעקב" מוחק את המנוי ואת ההתראות מהשרת '
            'באופן מיידי ומלא.',
        'מנוי שנכשל בשליחה חמש פעמים ברציפות (למשל דפדפן שנמחק) נמחק '
            'אוטומטית.',
        'רישומי השרת נמחקים אוטומטית לאחר 14 יום.',
      ],
    ),
    LegalSection(
      'זכויותיך',
      ['על פי חוק הגנת הפרטיות עומדות לך הזכויות הבאות:'],
      bullets: [
        'זכות עיון — לדעת איזה מידע מוחזק עליך.',
        'זכות תיקון — לבקש לתקן מידע שאינו נכון.',
        'זכות מחיקה — לבקש למחוק את המידע.',
        'את המחיקה ניתן לבצע בעצמך ומיידית: כיבוי ההתראות במסך "מעקב", '
            'וניקוי נתוני האתר בדפדפן. לכל בקשה אחרת פנה אלינו בכתובת '
            'שלהלן.',
      ],
    ),
    LegalSection(
      'אבטחת מידע',
      [],
      bullets: [
        'כל התעבורה מוצפנת ב-HTTPS.',
        'קובץ המנויים מוגבל בהרשאות למשתמש המערכת של השירות בלבד.',
        'הגישה לפאנל הניהול מוגנת בסיסמה שנשמרת כגיבוב PBKDF2 עם מלח, '
            'ולא כטקסט גלוי.',
        'ניסיונות התחברות חוזרים לפאנל הניהול נחסמים אוטומטית.',
        'מפתחות ה-API של השירות נשמרים בקובץ סביבה מוגן מחוץ לקוד.',
      ],
    ),
    LegalSection('שינויים במדיניות', [
      'ככל שהמדיניות תתעדכן, הנוסח המעודכן יפורסם כאן ותאריך העדכון '
          'שבראש המסמך ישתנה בהתאם.',
    ]),
    LegalSection('יצירת קשר', [
      'לשאלות או בקשות בנושא פרטיות: '
          '${AccessibilityInfo.contactEmail}',
      'אם פנייתך לא נענתה לשביעות רצונך, ניתן לפנות לרשות להגנת הפרטיות '
          'במשרד המשפטים.',
    ]),
  ];

  // ── English — courtesy translation; the Hebrew text governs ──
  static const List<LegalSection> _en = [
    LegalSection('General', [
      'This policy explains what data is collected when you use '
          '${AccessibilityInfo.siteName} (${AccessibilityInfo.siteUrl}), why, '
          'what is done with it and how to remove it. It follows the Israeli '
          'Protection of Privacy Law, 1981, including Amendment 13.',
      'Last updated: $lastUpdatedEn. This is a courtesy translation; the '
          'Hebrew version is the governing text.',
    ]),
    LegalSection(
      'What this site does not do',
      [],
      bullets: [
        'There is no registration, no user account and no end-user password.',
        'We never ask for or store your name, email address or phone number.',
        'There are no advertising cookies, social pixels or commercial '
            'analytics, and we do not profile users.',
        'We do not sell data or pass it to third parties for marketing.',
        'We take no payment and never receive payment details.',
      ],
    ),
    LegalSection(
      'Stored on your device only',
      ['The following stay in your browser and are never sent to us:'],
      bullets: [
        'The display name you entered, used only for the home greeting.',
        'Your display preferences: language, dark mode and text size.',
        'A local copy of the price alerts you created.',
        'Clearing the site data in your browser deletes all of it.',
      ],
    ),
    LegalSection(
      'Stored on the server',
      [
        'Data reaches the server only if you enabled push notifications. If '
            'you did not, nothing about you is stored beyond the server logs '
            'described below.',
        'With push enabled we store:',
      ],
      bullets: [
        'The push subscription endpoint — a unique address your browser '
            'generates so a notification can be delivered to it. It '
            'identifies the browser, not you by name.',
        'The two encryption keys (P256dh and Auth) your browser generates, '
            'without which the notification cannot be encrypted for it.',
        'Your price alerts: ticker, above or below, target price, whether '
            'it already fired, the last checked price and creation time.',
        'Your language preference, so the notification is sent in it.',
        'A delivery-failure counter, used to clean up dead subscriptions.',
      ],
    ),
    LegalSection('Where and how it is stored', [
      'In a single file on our server (/var/lib/finova/push_alerts.json), '
          'readable and writable only by the service account. The server is '
          'located in Europe. All traffic is encrypted over HTTPS with a '
          "Let's Encrypt certificate.",
    ]),
    LegalSection('Server logs', [
      'Like any web server, technical access logs are kept: IP address, '
          'timestamp, requested path and browser type. They are used for '
          'diagnostics and abuse prevention and are deleted automatically '
          'after 14 days.',
      'Additionally, an IP address is held briefly in memory during admin '
          'login attempts, solely to block repeated attempts.',
    ]),
    LegalSection(
      'Purposes and legal basis',
      [],
      bullets: [
        'Sending the price alert you asked for — your explicit consent, given '
            'when you allowed notifications and created an alert.',
        'Serving the app in your language and display preferences — '
            'performance of the service you requested.',
        'Security, abuse prevention and diagnostics — legitimate interest.',
      ],
    ),
    LegalSection(
      'Third parties',
      [
        'We pass nothing to commercial parties. Operating the service does '
            'involve:',
      ],
      bullets: [
        "Your browser's push service (Google, Mozilla or Apple) — receives "
            'the notification in order to deliver it. Its content is '
            'encrypted.',
        'Finnhub — market data and company logos. Receives only the ticker, '
            'requested from our server. Your IP is not forwarded.',
        'Yahoo Finance — price history, also requested from our server.',
        'Google Gemini and Groq — the AI engines producing the analysis. '
            'They receive only the ticker and its market data, never '
            'anything identifying you.',
      ],
    ),
    LegalSection(
      'Retention',
      [],
      bullets: [
        'The push subscription and alerts are kept while your alerts are '
            'active.',
        'Turning notifications off in the Watchlist screen deletes the '
            'subscription and the alerts from the server immediately and '
            'completely.',
        'A subscription that fails delivery five times in a row is removed '
            'automatically.',
        'Server logs are deleted automatically after 14 days.',
      ],
    ),
    LegalSection('Your rights', [
      'Under the Protection of Privacy Law you have the right to access, '
          'correct and delete your data.',
      'Deletion is available to you immediately: turn notifications off in '
          'the Watchlist screen and clear the site data in your browser. For '
          'anything else, contact us below.',
    ]),
    LegalSection(
      'Security',
      [],
      bullets: [
        'All traffic is encrypted over HTTPS.',
        'The subscriptions file is restricted to the service account.',
        'Admin access is protected by a password stored as a salted PBKDF2 '
            'hash, never in clear text.',
        'Repeated admin login attempts are blocked automatically.',
        'Service API keys live in a protected environment file outside the '
            'source code.',
      ],
    ),
    LegalSection('Changes', [
      'If this policy is updated, the new text will be published here and '
          'the date at the top will change.',
    ]),
    LegalSection('Contact', [
      'Privacy questions or requests: ${AccessibilityInfo.contactEmail}',
      'If your request is not resolved to your satisfaction, you may '
          'contact the Israeli Privacy Protection Authority.',
    ]),
  ];
}
