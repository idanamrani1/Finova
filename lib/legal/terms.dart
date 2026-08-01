import 'accessibility.dart' show AccessibilityInfo, LegalSection;

/// ───────────────────────────────────────────────────────────────────────────
/// תנאי שימוש
///
/// המסמך החשוב מבין השלושה עבור אפליקציה כמו זו: המסך מציג פלט בצורת
/// "המלצת AI: קנייה", וצריך להיות ברור לחלוטין שאין מדובר בייעוץ השקעות
/// כמשמעותו בחוק הסדרת העיסוק בייעוץ השקעות, בשיווק השקעות ובניהול תיקי
/// השקעות, התשנ"ה-1995, ושהתוכן מיוצר אוטומטית ועשוי לטעות.
///
/// ⚠️ זה אינו ייעוץ משפטי. מומלץ שעורך/ת דין יעברו על הנוסח לפני פרסום,
/// במיוחד על סעיפי הגבלת האחריות.
/// ───────────────────────────────────────────────────────────────────────────
class TermsOfUse {
  const TermsOfUse._();

  static const String lastUpdated = '1 באוגוסט 2026';
  static const String lastUpdatedEn = '1 August 2026';

  static List<LegalSection> forLang(String lang) => lang == 'he' ? _he : _en;

  static const List<LegalSection> _he = [
    LegalSection('קבלת התנאים', [
      'השימוש באתר ${AccessibilityInfo.siteName} '
          '(${AccessibilityInfo.siteUrl}) ובשירותיו מהווה הסכמה לתנאים '
          'שלהלן. אם אינך מסכים להם, אנא הימנע משימוש באתר.',
      'עודכן לאחרונה: $lastUpdated.',
    ]),
    LegalSection('מהות השירות', [
      'האתר מציג מידע על מניות: נתוני שוק, נתונים פונדמנטליים, ציון '
          'מספרי המחושב על ידינו, סיכום שוק יומי וניתוח טקסטואלי הנוצר '
          'על ידי מנועי בינה מלאכותית.',
      'השירות ניתן כפי שהוא (AS IS), ללא התחייבות לזמינות רציפה, '
          'לשלמות המידע או להתאמתו לצורך כלשהו.',
    ]),
    LegalSection(
      'אינו ייעוץ השקעות',
      ['זהו הסעיף המהותי ביותר במסמך זה, ויש לקרוא אותו במלואו.'],
      bullets: [
        'התוכן באתר, לרבות הציון, ההמלצה וכל ניסוח מסוג "קנייה", '
            '"מכירה" או "החזקה", אינו ייעוץ השקעות, אינו שיווק השקעות '
            'ואינו תחליף לייעוץ אישי מבעל רישיון.',
        'איננו בעלי רישיון ייעוץ השקעות ואיננו פועלים לפי חוק הסדרת '
            'העיסוק בייעוץ השקעות, בשיווק השקעות ובניהול תיקי השקעות, '
            'התשנ"ה-1995.',
        'התוכן אינו מתחשב בנתוניך האישיים, בצרכיך, במצבך הכלכלי או '
            'במטרות ההשקעה שלך, ואינו מותאם לך בשום צורה.',
        'אין באמור באתר הצעה, שידול או המלצה לרכוש או למכור נייר ערך '
            'כלשהו.',
        'כל החלטת השקעה היא באחריותך הבלעדית. מומלץ להתייעץ עם בעל '
            'רישיון לפני כל פעולה.',
      ],
    ),
    LegalSection(
      'תוכן שנוצר על ידי בינה מלאכותית',
      [],
      bullets: [
        'הניתוח המילולי, הסיכום היומי והנימוקים נוצרים אוטומטית על ידי '
            'מודלי שפה של ספקים חיצוניים.',
        'מודלים כאלה עלולים לטעות, להסיק מסקנות שגויות או לנסח דברים '
            'שאינם מדויקים, גם כאשר הנתונים שהוזנו להם נכונים.',
        'הציון המספרי מחושב על ידינו לפי נוסחה קבועה מתוך נתונים '
            'פונדמנטליים. הוא אינו חיזוי, אינו הבטחה ואינו מדד מקובל '
            'בענף.',
        'אין להסתמך על תוכן שנוצר אוטומטית כעל בדיקה מקצועית.',
      ],
    ),
    LegalSection(
      'דיוק הנתונים וזמינותם',
      [],
      bullets: [
        'נתוני השוק מגיעים מספקים חיצוניים ועשויים להיות שגויים, חסרים '
            'או מתעכבים. אין להתייחס אליהם כאל נתוני מסחר בזמן אמת.',
        'התראות המחיר נבדקות במרווחי זמן ואינן מובטחות. ייתכן עיכוב, '
            'ייתכן שהתראה לא תישלח כלל, וייתכן שהמחיר ישתנה בין הבדיקה '
            'לבין קבלת ההתראה.',
        'אין להסתמך על ההתראות לצורך פעולה תלוית זמן.',
        'השירות עשוי להיות מושבת לצורך תחזוקה או מסיבות טכניות, ללא '
            'הודעה מראש.',
      ],
    ),
    LegalSection(
      'שימוש מותר',
      ['בעת השימוש באתר אינך רשאי:'],
      bullets: [
        'לבצע גריפה אוטומטית, לשלוח בקשות בנפח חריג או לעקוף מנגנוני '
            'הגבלת קצב.',
        'לנסות לחדור למערכת, לפאנל הניהול או לחשבונות של אחרים.',
        'להציג את תוכן האתר כתוכן שלך או להפיצו מסחרית ללא רשות בכתב.',
        'להשתמש באתר לכל מטרה בלתי חוקית.',
      ],
    ),
    LegalSection('קניין רוחני', [
      'העיצוב, הלוגו, שם המותג, נוסחת הציון והקוד הם רכושו של בעל '
          'האתר. נתוני השוק שייכים לספקים שמהם התקבלו, ולוגואי החברות הם '
          'סימני המסחר של בעליהם ומוצגים לצורך זיהוי בלבד.',
    ]),
    LegalSection('הגבלת אחריות', [
      'בכפוף לכל דין, בעל האתר לא יישא באחריות לכל נזק ישיר או עקיף, '
          'ובכלל זה הפסד כספי, אובדן רווח או הפסד הזדמנות, שנגרם '
          'כתוצאה משימוש באתר, מהסתמכות על תוכנו, מאי-זמינותו או '
          'מטעות בנתונים.',
      'האחריות הכוללת, ככל שתחול, לא תעלה על הסכום ששילמת עבור '
          'השירות — ומאחר שהשירות ניתן ללא תשלום, סכום זה הוא אפס.',
    ]),
    LegalSection('שינויים בשירות ובתנאים', [
      'אנו רשאים לשנות, להשעות או להפסיק את השירות, כולו או חלקו, בכל '
          'עת. תנאים אלה עשויים להתעדכן; הנוסח המעודכן יפורסם כאן '
          'ותאריך העדכון ישתנה בהתאם. המשך השימוש לאחר עדכון מהווה '
          'הסכמה לנוסח החדש.',
    ]),
    LegalSection('דין וסמכות שיפוט', [
      'על תנאים אלה יחולו דיני מדינת ישראל. סמכות השיפוט הבלעדית '
          'נתונה לבתי המשפט המוסמכים בישראל.',
    ]),
    LegalSection('יצירת קשר', [
      'לשאלות בנוגע לתנאי השימוש: ${AccessibilityInfo.contactEmail}',
    ]),
  ];

  // ── English — courtesy translation; the Hebrew text governs ──
  static const List<LegalSection> _en = [
    LegalSection('Acceptance', [
      'Using ${AccessibilityInfo.siteName} '
          '(${AccessibilityInfo.siteUrl}) means you accept these terms. If '
          'you do not, please do not use the site.',
      'Last updated: $lastUpdatedEn. This is a courtesy translation; the '
          'Hebrew version is the governing text.',
    ]),
    LegalSection('What the service is', [
      'The site presents stock information: market data, fundamentals, a '
          'numeric score we compute, a daily market brief and textual '
          'analysis generated by AI engines.',
      'The service is provided AS IS, with no guarantee of availability, '
          'completeness or fitness for any purpose.',
    ]),
    LegalSection(
      'Not investment advice',
      ['This is the most important section here; please read all of it.'],
      bullets: [
        'Nothing on the site — including the score, the recommendation and '
            'any "buy", "sell" or "hold" wording — is investment advice, '
            'investment marketing, or a substitute for personal advice from '
            'a licensed professional.',
        'We hold no investment advisory licence and do not operate under '
            "Israel's Regulation of Investment Advice, Investment Marketing "
            'and Portfolio Management Law, 1995.',
        'The content does not take your circumstances, needs, financial '
            'position or investment goals into account in any way.',
        'Nothing here is an offer, solicitation or recommendation to buy or '
            'sell any security.',
        'Every investment decision is yours alone. Consult a licensed '
            'professional before acting.',
      ],
    ),
    LegalSection(
      'AI-generated content',
      [],
      bullets: [
        'The written analysis, the daily brief and the stated reasons are '
            'produced automatically by third-party language models.',
        'Such models can be wrong, draw incorrect conclusions or phrase '
            'things inaccurately, even when the input data is correct.',
        'The numeric score is computed by us from fundamentals using a fixed '
            'formula. It is not a forecast, not a promise and not an industry '
            'standard measure.',
        'Do not treat automatically generated content as professional '
            'due diligence.',
      ],
    ),
    LegalSection(
      'Data accuracy and availability',
      [],
      bullets: [
        'Market data comes from third-party providers and may be wrong, '
            'incomplete or delayed. It is not real-time trading data.',
        'Price alerts are checked at intervals and are not guaranteed. They '
            'may be delayed, may not arrive at all, and the price may move '
            'between the check and the delivery.',
        'Do not rely on alerts for time-sensitive action.',
        'The service may be taken down for maintenance or technical reasons '
            'without notice.',
      ],
    ),
    LegalSection(
      'Acceptable use',
      ['You may not:'],
      bullets: [
        'Scrape the site, send abnormal request volumes or work around rate '
            'limiting.',
        'Attempt to break into the system, the admin panel or anyone else\'s '
            'data.',
        'Present the content as your own or redistribute it commercially '
            'without written permission.',
        'Use the site for any unlawful purpose.',
      ],
    ),
    LegalSection('Intellectual property', [
      'The design, logo, brand name, scoring formula and source code belong '
          'to the site owner. Market data belongs to the providers it came '
          'from, and company logos are the trademarks of their owners, shown '
          'for identification only.',
    ]),
    LegalSection('Limitation of liability', [
      'To the extent permitted by law, the site owner is not liable for any '
          'direct or indirect damage, including financial loss, lost profit '
          'or lost opportunity, arising from use of the site, reliance on '
          'its content, its unavailability or an error in the data.',
      'Total liability, if any applies, will not exceed what you paid for '
          'the service — and since the service is free, that is zero.',
    ]),
    LegalSection('Changes', [
      'We may change, suspend or discontinue the service at any time. These '
          'terms may be updated; the new text will be published here and the '
          'date will change. Continued use after an update constitutes '
          'acceptance of it.',
    ]),
    LegalSection('Governing law', [
      'These terms are governed by the laws of the State of Israel, and the '
          'competent courts in Israel have exclusive jurisdiction.',
    ]),
    LegalSection('Contact', [
      'Questions about these terms: ${AccessibilityInfo.contactEmail}',
    ]),
  ];
}
