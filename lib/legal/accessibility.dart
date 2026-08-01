/// ───────────────────────────────────────────────────────────────────────────
/// הצהרת נגישות
///
/// נדרשת לפי סימן ג' ותקנה 35 לתקנות שוויון זכויות לאנשים עם מוגבלות
/// (התאמות נגישות לשירות), התשע"ג-2013. התקנה מחייבת לפרסם אותה במקום
/// בולט באתר וגם באפליקציה, ולכלול: מה הונגש, פרטי קשר לדיווח על תקלת
/// נגישות, ורכיבים שלא הונגשו יחד עם דרך חלופית לקבל את המידע שבהם.
///
/// הנוסח כאן מתאר את מה שבאמת נעשה בקוד. אין להרחיב אותו לטענות שלא
/// נבדקו — הצהרה שאינה נכונה גרועה מהיעדר הצהרה.
///
/// ⚠️ זה אינו ייעוץ משפטי. מומלץ שעורך/ת דין יעברו על הנוסח לפני פרסום.
/// ───────────────────────────────────────────────────────────────────────────
library;

class AccessibilityInfo {
  const AccessibilityInfo._();

  /// כתובת לפניות בנושא נגישות. ⚠️ שנה כאן, במקום אחד, כדי לעדכן בכל האתר.
  static const String contactEmail = 'idanamrani1@gmail.com';

  /// מועד הבדיקה האחרונה. יש לעדכן בכל סבב נגישות.
  static const String lastReviewed = '1 באוגוסט 2026';
  static const String lastReviewedEn = '1 August 2026';

  static const String siteName = 'Finova';
  static const String siteUrl = 'finovam.ddns.net';
}

/// סעיף בהצהרה: כותרת ושורות תוכן.
class LegalSection {
  const LegalSection(this.heading, this.paragraphs, {this.bullets = const []});

  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
}

class AccessibilityStatement {
  const AccessibilityStatement._();

  static List<LegalSection> forLang(String lang) => lang == 'he' ? _he : _en;

  // ── עברית — הנוסח המחייב ──
  static const List<LegalSection> _he = [
    LegalSection('מחויבות לנגישות', [
      'אתר ${AccessibilityInfo.siteName} (${AccessibilityInfo.siteUrl}) פועל '
          'כדי שאנשים עם מוגבלות יוכלו להשתמש בו באופן עצמאי, שוויוני ומכבד. '
          'ההנגשה בוצעה בהתאם לתקנות שוויון זכויות לאנשים עם מוגבלות '
          '(התאמות נגישות לשירות), התשע"ג-2013.',
    ]),
    LegalSection('רמת הנגישות והתקן', [
      'האתר הונגש בהתאם לתקן הישראלי ת"י 5568, המבוסס על הנחיות '
          'WCAG 2.0 של ארגון W3C, ברמת הנגישות AA.',
      'בדיקת הנגישות האחרונה נערכה בתאריך '
          '${AccessibilityInfo.lastReviewed}.',
    ]),
    LegalSection(
      'התאמות הנגישות שבוצעו באתר',
      [],
      bullets: [
        'האתר מוגדר בעברית ובכיוון כתיבה מימין לשמאל, כך שתוכנות הקראה '
            'מזהות את שפת התוכן ומקריאות אותו נכון.',
        'שכבת הנגישות (semantics) פעילה מרגע טעינת האתר, ולא רק אחרי '
            'איתור והפעלה ידנית שלה.',
        'כל הפעולות באתר ניתנות להפעלה מהמקלדת בלבד, באמצעות מקש Tab '
            'למעבר ומקשי Enter או רווח להפעלה.',
        'לפריט שנמצא במיקוד יש מסגרת סגולה בולטת, כדי שתמיד יהיה ברור '
            'היכן נמצאת נקודת ההפעלה.',
        'לכפתורים המסומנים באייקון בלבד — פעמון ההתראות, תפריט הפרופיל, '
            'מחיקת התראה וכפתורי הניווט — הוגדרו תוויות מילוליות בעברית.',
        'ציון Finova מוקרא כטקסט מלא ("ציון 85 מתוך 100") ולא כתמונה, '
            'וגרף המחיר מוקרא עם מספר ימי המסחר והמחיר הנוכחי.',
        'ניגודיות הצבעים בטקסטים עומדת ביחס של 4.5:1 לפחות מול הרקע.',
        'ניתן להגדיל את הטקסט בשלוש רמות דרך מסך "עוד" > "גודל טקסט", '
            'בלי שהתוכן ייחתך או ייעלם.',
        'משתמש שהגדיר במערכת ההפעלה שלו העדפה לצמצום אנימציות — כל '
            'התנועות באתר מתבטלות עבורו.',
        'אזורי המגע בסרגל הניווט התחתון בגודל 44 פיקסלים לפחות.',
        'גרף המחיר ניתן להפעלה מהמקלדת: מקש Tab מעביר אליו את המיקוד, '
            'מקשי החצים מזיזים את נקודת הקריאה, Home ו-End קופצים לקצוות '
            'ו-Esc מבטל את הבחירה.',
      ],
    ),
    LegalSection(
      'רכיבים שטרם הונגשו במלואם',
      [
        'למרות מאמצינו, ייתכנו חלקים באתר שעדיין אינם נגישים במלואם. '
            'הרכיבים הידועים לנו הם:',
      ],
      bullets: [
        'האתר בנוי בטכנולוגיית Flutter Web, שמציירת את התוכן על גבי '
            'קנבס. ההתנהגות עם תוכנות הקראה עשויה להיות שונה מאתר רגיל, '
            'ובחלק מהדפדפנים ייתכנו פערים בהקראה.',
        'תוכן הניתוח נוצר אוטומטית על ידי מנוע בינה מלאכותית, ולכן '
            'אורך הטקסט וניסוחו משתנים בין מניה למניה ואינם נשלטים מראש.',
      ],
    ),
    LegalSection('דרכים חלופיות לקבלת המידע', [
      'אם נתקלת ברכיב שאינו נגיש עבורך, נשמח לספק לך את המידע שבו בדרך '
          'חלופית — בדואר אלקטרוני, בטקסט פשוט או בשיחה. פנה אלינו '
          'בכתובת ${AccessibilityInfo.contactEmail} ונחזור אליך.',
    ]),
    LegalSection('פניות בנושא נגישות', [
      'נתקלת בבעיית נגישות? יש לך הצעה לשיפור? נשמח לשמוע. פנייתך '
          'תטופל בהקדם.',
      'דואר אלקטרוני: ${AccessibilityInfo.contactEmail}',
      'בפנייה מומלץ לפרט את הדף או המסך שבו נתקלת בבעיה, מה ניסית '
          'לעשות, ובאיזה דפדפן או מכשיר — כדי שנוכל לשחזר ולתקן.',
    ]),
  ];

  // ── English — courtesy translation; the Hebrew text above governs ──
  static const List<LegalSection> _en = [
    LegalSection('Commitment to accessibility', [
      '${AccessibilityInfo.siteName} (${AccessibilityInfo.siteUrl}) works to '
          'let people with disabilities use it independently and equally, '
          'in line with the Israeli Equal Rights for Persons with '
          'Disabilities (Accessibility Adjustments to Service) Regulations, '
          '2013.',
      'This is a courtesy translation. The Hebrew version is the governing '
          'text.',
    ]),
    LegalSection('Conformance level', [
      'The site follows Israeli Standard 5568, which is based on the W3C '
          'WCAG 2.0 guidelines, at conformance level AA.',
      'Last reviewed on ${AccessibilityInfo.lastReviewedEn}.',
    ]),
    LegalSection(
      'What has been done',
      [],
      bullets: [
        'The page declares Hebrew and right-to-left direction, so screen '
            'readers announce the content in the correct language.',
        'The accessibility semantics layer is enabled from load, not only '
            'after a hidden control is found and activated.',
        'Every action can be performed with the keyboard alone: Tab to '
            'move, Enter or Space to activate.',
        'The focused element carries a clearly visible violet outline.',
        'Icon-only buttons — the notifications bell, profile, delete alert '
            'and the navigation tabs — have text labels.',
        'The Finova score is exposed as text ("score 85 out of 100") '
            'rather than as an image, and the price chart is announced with '
            'its range and current price.',
        'Text contrast is at least 4.5:1 against its background.',
        'Text can be enlarged in three steps from More > Text size without '
            'content being cut off.',
        'If the operating system requests reduced motion, all animation is '
            'switched off.',
        'Bottom navigation touch targets are at least 44px.',
        'The price chart is keyboard operable: Tab focuses it, the arrow '
            'keys move the read-out, Home and End jump to either end and '
            'Esc clears the selection.',
      ],
    ),
    LegalSection(
      'Known limitations',
      ['Some parts are not yet fully accessible:'],
      bullets: [
        'The site is built with Flutter Web, which paints to a canvas. '
            'Screen-reader behaviour can differ from a conventional site '
            'and may vary between browsers.',
        'Analysis text is generated by an AI engine, so its length and '
            'wording vary per stock and are not fixed in advance.',
      ],
    ),
    LegalSection('Alternative ways to get the information', [
      'If any part is not accessible to you, we will provide its content '
          'another way — by email, as plain text, or by phone. Write to '
          '${AccessibilityInfo.contactEmail}.',
    ]),
    LegalSection('Accessibility feedback', [
      'Found a problem, or have a suggestion? We would like to hear about '
          'it and will respond as soon as we can.',
      'Email: ${AccessibilityInfo.contactEmail}',
      'Please include the screen, what you were trying to do, and the '
          'browser or device you used, so we can reproduce and fix it.',
    ]),
  ];
}
