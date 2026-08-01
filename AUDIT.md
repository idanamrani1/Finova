# AUDIT — מצב הקוד לפני העיצוב מחדש

נכתב לפי סעיף 0.1 בתכנית העבודה. מטרתו למפות את מה שקיים **לפני** נגיעה בעיצוב,
ולסמן את הפערים בין הרפרנס לבין הפיצ'רים שכבר בקוד.

---

## 0. הערה מקדימה — הפרויקט הוא Flutter, לא Web

תכנית העבודה כתובה במונחי web (`tokens.css`, Tailwind, styled-components,
`src/assets/`, Storybook, `dir="rtl"`, logical properties). הפרויקט בפועל הוא
**Flutter** שמתקמפל ל-web. כל הדרישות מתורגמות 1:1 למקבילה ב-Flutter, בלי לוותר
על אף אחת מהן:

| בתכנית (web) | בפועל (Flutter) |
|---|---|
| `tokens.css` / CSS custom properties | `lib/design/tokens.dart` — מחלקות `FColor`, `FGrad`, `FRadius`, `FSpace`, `FType`, `FBorder`, `FShadow` |
| `dir="rtl"` על ה-root | `Directionality(textDirection: TextDirection.rtl)` סביב כל האפליקציה |
| `margin-inline-start` / `padding-inline-end` | `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional` |
| `src/assets/brand/*.svg` | `assets/brand/*.svg` (מקור אמת + favicon/app icon) + `Logo` widget שמצויר נייטיב ב-`CustomPainter`, כדי לא להוסיף תלות `flutter_svg` |
| Storybook | מסך demo פנימי (`lib/design/gallery.dart`) שמציג כל primitive בכל המצבים |
| `font-variant-numeric: tabular-nums` | `FontFeature.tabularFigures()` (כבר קיים ב-theme) |
| `prefers-reduced-motion` | `MediaQuery.disableAnimations` |
| `env(safe-area-inset-bottom)` | `SafeArea` / `MediaQuery.viewPadding` |

**SVG של הלוגו**: הקבצים מופקים ונשמרים כנדרש (הם מקור האמת ל-favicon ול-app
icon), אבל הלוגו בתוך האפליקציה מצויר בקוד ולא נטען כ-SVG — הסימן הוא שלושה
מלבנים מעוגלים עם gradient, שזה 20 שורות `Canvas` מול תלות חיצונית שלמה.

---

## 1. מבנה הקוד היום

**קובץ אחד**: `lib/main.dart` — 5,757 שורות. אין תיקיית `lib/` נוספת, אין הפרדה
בין theme / components / screens. כל האפליקציה היא `DashboardScreen` אחד עם
`_selectedIndex` שמחליף מסכים ב-`switch`.

```
lib/main.dart
├── class T                    (מערכת תרגום he/en — מפה סטטית, ~110 מפתחות)
├── MyApp                      (MaterialApp, theme בהיר/כהה, textScale, שפה, splash)
├── SplashScreen
├── DashboardScreen            ← כל האפליקציה
│   └── _DashboardScreenState  (5,000+ שורות: state, קריאות API, וכל המסכים)
├── _MiniChartPainter
├── _CandlestickLoader / _CandlestickPainter
├── _PulsingLiveDot
└── _ScoreRingPainter
```

---

## 2. מסכים קיימים (routes)

אין ניווט אמיתי — `_buildBody()` בשורה 1485 עושה `switch (_selectedIndex)`.

| # | מסך | פונקציה | תפקיד |
|---|---|---|---|
| 0 | Research | `_buildDashboardContent()` (1597) | חיפוש מניה + מחיר חי + גרף + 3 טאבים של ניתוח |
| 1 | סיכום יומי | `_buildDailyBriefScreen()` (2189) | בריף שוק יומי, מדדים, חדשות, "המניות שלי", מקורות, ארכיון |
| 2 | התראות | `_buildAlertsScreen()` (4534) | התראות מחיר + push notifications |
| 3 | הגדרות | `_buildSettingsScreen()` (4885) | שפה, מצב כהה, גודל טקסט, מפתחות API, הבהרה משפטית |

**מסכי-משנה (dialogs / bottom sheets)** — לא ראוטים אבל הם מסכים לכל דבר:

| דיאלוג | פונקציה | תוכן |
|---|---|---|
| פירוט הציון | `_showScoreBreakdown()` (3682) | כל ה-factors לפי קטגוריה + הסבר המשקולות |
| נימוק ההמלצה | `_showRecommendationReason()` (3361) | למה ה-AI המליץ מה שהמליץ |
| הסבר מונח | `_showTermExplanation()` (4135) | הסבר על P/E, ROE וכו' |

**טאבים פנימיים במסך Research** (`TabController`, 3 טאבים):
`_buildSummaryTab()` (3212) · `_buildFundamentalsTab()` (3291) · `_buildCatalystsTab()` (3327)

---

## 3. קומפוננטות משותפות

אין קומפוננטות אמיתיות — הכל מתודות `_build*` פרטיות בתוך ה-State, בלי props
ובלי אפשרות לשימוש חוזר מחוץ למחלקה.

### 3.1 מה שכבר מתפקד כקומפוננטה (יהפוך ל-primitive)

| מתודה | שורה | מה זה | ל-primitive |
|---|---|---|---|
| `_buildNavItem` | 1548 | פריט בניווט התחתון | `NavItem` |
| `_buildStatCardNew` | 4200 | כרטיס נתון (אייקון + תווית + ערך) | `StatCard` |
| `_buildTextCardNew` | 4290 | כרטיס טקסט עם accent | `FCard` + `SectionTitle` |
| `_buildListCardNew` | 4324 | כרטיס עם רשימת bullets | `FCard` |
| `_buildSectionTitle` | 4420 | כותרת סקשן | `SectionTitle` |
| `_buildNewsCard` | 3106 | כרטיס חדשה בבריף | `FCard` |
| `_buildMarketCard` | 3166 | כרטיס מדד (S&P וכו') | `FCard` |
| `_buildAlertRow` | 4799 | שורת התראה | `ActionRow` |
| `_buildTextPreset` | 5337 | בורר גודל טקסט | `FChip` |
| `_ScoreRingPainter` | 5714 | טבעת הציון (סטטית) | `ScoreRing` (+אנימציה) |
| `_MiniChartPainter` | 5376 | גרף מחיר sparkline | נשאר, מקבל צבעים מטוקנים |
| `_CandlestickLoader` | 5471 | אנימציית טעינה | נשאר / מוחלף ב-skeleton |
| `_PulsingLiveDot` | 5613 | נקודת LIVE פועמת | `LiveDot` |

### 3.2 מה שחסר לגמרי היום

- **אין Skeletons** — מצב הטעינה הוא `_CandlestickLoader` (אנימציה מרכזית אחת) + טקסט שלבים (`_startLoadingStages`). אין shimmer ברמת הרכיב.
- **אין Empty state אחיד** — כל מסך ממציא אחד משלו (`tr('searchToStart')`, `tr('noAlerts')`, `tr('myStocksEmpty')`, `tr('archiveEmpty')`).
- **אין Error state אחיד** — `_buildNotFound()` (4483) למסך אחד, `briefError` למסך אחר.
- **אין קומפוננטת Logo** — הלוגו מופיע רק ב-`SplashScreen` כאייקון, לא בהדר.
- **אין הדר בכלל** — אף מסך לא מציג הדר עליון קבוע. אין פעמון, אין אווטאר.

---

## 4. איפה מוגדרים היום צבעים / פונטים / מרווחים

### 4.1 צבעים — שלושה מקומות, לא מסונכרנים

1. **`ThemeData` ב-`MyApp`** (שורות 303–336) — `scaffoldBackgroundColor`, `cardColor`, `primaryColor`, `textTheme`. זה המקור ה"רשמי".
   - כהה: רקע `#0B0B14`, כרטיס `#16161F`, מותג `#7C7FF2`, טקסט `#F5F5FA`, משני `#7A7A92`
   - בהיר: רקע `#EBEEF6`, כרטיס לבן, מותג `#6366F1`, טקסט `#1A1A2E`, משני `#6B6B85`
2. **שתי פונקציות עזר**:
   - `_overlay(opacity)` (3428) — לבן/שחור שקוף לפי brightness. משמש לגבולות ורקעים.
   - `_scoreColor(v)` (3436) — טורקיז `#2DD4BF` ≥68 / אינדיגו `#818CF8` ≥50 / סגול `#C084FC` מתחת.
3. **ערכים קשיחים בגוף הווידג'טים** — ~50 ערכי `Color(0xFF…)` פזורים. הנפוצים:
   - `#4ade80` ירוק עלייה (19 מופעים) · `#f87171` אדום ירידה (15) · `#fbbf24` ניטרלי (3)
   - רקעי גרדיאנט של כרטיסים: `#1A2333`, `#2A1620`, `#14301F`, `#0F2418`, `#301414`, `#240F0F`, `#302814`, `#24200F`

### 4.2 טיפוגרפיה

**אין פונט מוגדר בכלל.** `pubspec.yaml` לא מכיל סקשן `fonts`, כך שהאפליקציה
רצה על ברירת המחדל של Flutter (Roboto), שהעברית בו נופלת ל-fallback של המערכת —
זו הסיבה שהעברית נראית שונה בין אייפון לאנדרואיד. גדלים וmשקלים נכתבים inline
בכל `TextStyle`, בלי סקאלה: בשימוש כיום 9, 10, 11, 12, 13, 14, 16, 20, 26, 28, 30, 40.

`FontFeature.tabularFigures()` כבר מוגדר ב-`bodyMedium`/`bodySmall` — נשמר.

### 4.3 מרווחים

`EdgeInsets` inline בכל מקום. הערכים בשימוש: 3, 4, 5, 6, 8, 9, 10, 11, 12, 14,
16, 18, 20, 24. קרוב לסקאלה של התכנית (4/8/12/16/20/24/32) אבל לא זהה —
בעיקר 18 (padding צד גלובלי היום) מול 20 שהתכנית מבקשת.

### 4.4 RTL — נקודתי, לא גלובלי

אין `Directionality` ברמת ה-root. במקום זה יש 4 עטיפות מקומיות (שורות 2194,
3476, 3696, 4139) שכל אחת בודקת `widget.lang == 'he'`. שאר המסכים יורשים LTR
מ-`MaterialApp`, ולכן `CrossAxisAlignment.start` בהם מיישר **שמאלה** גם בעברית.
זה באג קיים, לא רק סטייה מהתכנית. שני שימושים בלבד ב-`EdgeInsetsDirectional`
(1948, 2440) ואחד ב-`AlignmentDirectional` (4272) — כל השאר `EdgeInsets` סימטרי
או `left`/`right` מרומז.

---

## 5. נתונים אמיתיים שזמינים לעיצוב

חשוב לעיצוב המסך הראשי — מה באמת מגיע מהשרת (`https://finovam.ddns.net`):

| Endpoint | מחזיר | משמש ל |
|---|---|---|
| `GET /api/analyze/{ticker}?lang=` | `symbol`, `exchange`, `currentPrice`, `dailyChange`, `chartData[]`, `analysis{}`, `finovaScore{}` | הכרטיס הראשי, הציון, ההמלצה |
| `GET /api/quote/{ticker}` | `price`, `dailyChange` | רענון מחיר כל 15ש' |
| `POST /api/movers` | `[{ticker, change}]` | צ'יפים פופולריים + "המניות שלי" |
| `GET /api/search/{q}` | `[{symbol, description}]` | השלמה אוטומטית |
| `GET /api/daily-brief?lang=` | בריף יומי מלא | מסך הסיכום |
| `GET /api/daily-brief/archive?lang=` | סיכומים קודמים | ארכיון |

**`analysis{}`** מכיל: `finalRecommendation`, `verdict`, `confidenceLevel`,
`recommendationReason`, `thesisSummary`, `catalysts`, `upcomingEvents`,
`revenueGrowth`, `revenueGrowthReal`, `marginsTrend`, `valuationVsPeers`,
`freeCashFlow`, `peRatio`, `roe`, `netMargin`, `debtToEquity`, `beta`,
`marketCap`, `dividendYield`, `oneYearReturn`, `fiftyTwoWeekRange`.

**`finovaScore{}`** מכיל: `total`, `label`, `quickTake`, `quality`, `value`,
`growth`, `risk`, `factors[]` (כל אחד עם `category`).

→ **כל מה שהרפרנס מציג קיים כנתון אמיתי.** "AI Score 92" = `finovaScore.total`,
"המלצת AI: קנייה" = `finalRecommendation`, "ביטחון 94%" = `confidenceLevel`,
ותיבות "למה?" = `factors[]` / `recommendationReason`. אין צורך בנתוני דמה.

---

## 6. צריך החלטה

הפערים בין הרפרנס לבין מה שקיים. **אף פיצ'ר לא יימחק** — לכל אחד מוצעת התאמה.

### 6.1 הניווט התחתון — 5 פריטים ברפרנס מול 4 בקוד

הרפרנס: `בית · שוק · חיפוש · מעקב · עוד`. הקוד: `בית(=Research) · סיכום יומי · התראות · עוד`.

**מה שאני מבצע** (ניתן להיפוך אם תחליט אחרת):

| טאב ברפרנס | ממופה למסך הקיים | הערה |
|---|---|---|
| בית | **מסך חדש** | לא היה קיים — נבנה מהנתונים הקיימים בלבד |
| שוק | `_buildDailyBriefScreen` | הסיכום היומי הוא בפועל מסך שוק (מדדים, חדשות, מה מזיז את העולם) |
| חיפוש | `_buildDashboardContent` | מסך ה-Research הקיים במלואו — חיפוש, גרף, 3 טאבים, ציון, המלצה |
| מעקב | `_buildAlertsScreen` | ההתראות הן בפועל רשימת המעקב |
| עוד | `_buildSettingsScreen` | ללא שינוי תפקודי |

התוצאה: אפס פיצ'רים אבודים, והמסך היחיד שנוסף הוא זה שהרפרנס מבקש במפורש.

### 6.2 התנגשות ירוק — מותג מול כיוון שוק

התכנית מגדירה `--accent-green #22C55E` גם ל-AI Score, גם ל"המלצת קנייה" וגם
ל"מגמה חיובית". זו בדיוק ההתנגשות שתוקנה קודם בפרויקט: `_scoreColor()` קיבל
סקאלה משלו (טורקיז/אינדיגו/סגול) כדי שירוק ואדום יישארו **רק** לכיוון שוק,
אחרת ציון 45 בירוק נקרא כמו "המניה עולה".

**מה שאני מבצע**: הולך לפי התכנית — הטבעת בכרטיס ה-Hero והצ'יפ "המלצת AI"
ירוקים כפי שהוגדר, כי המספר שם צמוד להמלצה ולא למחיר. **שומר** את הסקאלה
הנפרדת בתת-הציונים (איכות/צמיחה/מחיר/סיכון) בכרטיס הפירוט, כדי שארבעה מספרים
בירוק-אדום לא ייקראו כארבע מניות שעולות ויורדות. אם תעדיף אחידות מלאה — שורה
אחת ב-`tokens.dart`.

### 6.3 פיצ'רים בקוד שאין להם מקום ברפרנס

| פיצ'ר | היכן היום | מה נעשה איתו |
|---|---|---|
| **מצב בהיר (Light mode)** | `MyApp` + toggle בהגדרות | התכנית מגדירה פלטה כהה בלבד. הטוקנים נבנים עם שתי סקימות, הכהה כברירת מחדל; המתג נשאר בהגדרות ולא נמחק |
| **בורר גודל טקסט** (3 presets) | הגדרות | נשאר. מתיישב עם דרישת Dynamic Type בסעיף 8 |
| **בורר שפה he/en** | הגדרות | נשאר. ב-en ה-`Directionality` מתהפך ל-LTR — הטוקנים והמרווחים לוגיים ולכן זה עובד לבד |
| **פאנל מפתחות API** (מוגן סיסמה) | הגדרות | נשאר, מקבל את השפה החדשה. לא נוגע בלוגיקה או ב-tokens של ה-session |
| **התראות Push** + הרשמה | מסך התראות | נשאר. הפעמון בהדר מקבל את הנקודה מהמצב האמיתי של ההתראות |
| **Splash screen** | `SplashScreen` | נשאר, מקבל את הלוגו החדש והרקע `--bg-app` |
| **מסגרת המכשיר במסך רחב** | `build()` שורה 1441 | נשאר — 430×860 מתאים בדיוק לרוחב שהתכנית מבקשת לבדוק |
| **שורת קרדיט ©** | תחתית מסך Research | עובר למסך "עוד", כדי שלא ייתקע מתחת לניווט הקבוע |
| **גרף נרות/sparkline** | כרטיס המחיר | נשאר. הצבעים עוברים לטוקנים (`--accent-green`/`--accent-red`, שזה כיוון שוק — מותר) |
| **צ'יפים של מניות פופולריות** | מתחת לחיפוש | הופך לקרוסלת "הזדמנויות היום" במסך הבית; נשאר גם במסך החיפוש |

### 6.4 דברים ברפרנס שאין להם נתון

| ברפרנס | מצב | פתרון |
|---|---|---|
| לוגואים אמיתיים של מניות (NVDA, AMD…) | אין endpoint, אין קבצים | fallback לפי התכנית: עיגול עם האות הראשונה על `--bg-surface-2`. `assets/tickers/` נוצרת ומוכנה לקבצים אם יתווספו |
| "עודכן לפני 3 דקות" | לא נשמר זמן הניתוח | נגזר מזמן ה-fetch המקומי (`DateTime.now()` בעת קבלת התשובה) |
| ראשי תיבות באווטאר ("IA") | אין מערכת משתמשים | קבוע `IA` (Idan Amrani) — אין login באפליקציה |
| שם בברכה ("בוקר טוב, עידן") | אין מערכת משתמשים | קבוע "עידן", שמור ב-`SharedPreferences` כדי שיהיה ניתן לשינוי בהמשך |
| נקודת התראה על הפעמון | — | אמיתית: מוצגת אם יש התראת מחיר שהופעלה ולא נקראה |

---

## 7. סיכום

- **קובץ אחד, 5,757 שורות, אפס שכבת עיצוב.** נדרשת שכבת טוקנים חדשה מאפס.
- **RTL שבור חלקית** — לא רק פער מהתכנית אלא באג יישור קיים בעברית.
- **אין פונט מוגדר** — העברית נראית שונה בכל מכשיר.
- **כל הנתונים שהרפרנס מציג כבר קיימים ב-API.** המסך החדש נבנה על אמת, לא על דמה.
- **פיצ'ר אחד נוסף** (מסך בית), **אפס פיצ'רים נמחקים**, שני נושאים לאישורך: מיפוי 5 הטאבים (6.1) והתנגשות הירוק (6.2).
