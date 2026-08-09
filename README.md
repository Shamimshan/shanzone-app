# SHAN ZONE — Customer App (Flutter)

Poora source code yahan hai. Neeche diye steps follow karke GitHub pe push
karein aur APK bana lein.

## 1. Pehle karne wale kaam

### A) Apps Script update (v9)
Is folder me `apps-script-code-v9.gs` file hai — iska poora content copy
karke apne Google Apps Script editor me paste karein (purana replace),
Save karein, phir **Deploy → Manage deployments → Edit → New version →
Deploy**.

`adminEmail` variable me apna email zaroor daalein.

### B) Customers Sheet me 3 naye columns add karein
`Customers` tab me H, I, J columns banayein:

| H (NameHi) | I (Address) | J (AddressHi) |
|---|---|---|
| मोहम्मद शमीम | House No. 12, Maharajganj | मकान नंबर 12, महाराजगंज |

(Ye khaali bhi chhod sakte hain shuru me — app me bas woh field khaali
dikhega, kuch tootega nahi.)

### C) Speed Test URL set karein
`lib/screens/speedtest_screen.dart` file kholein, upar ye line dhoondein:
```dart
const String kSpeedTestUrl = 'https://REPLACE-WITH-YOUR-WEBSITE-URL/#speedtest';
```
Apni asli website ka URL daal dein jahan speed test hosted hai.

### D) App icon aur naam (optional par recommended)
- `assets/images/` folder me apna logo daal dein (jaise `logo.png`)
- App naam pehle se "SHAN ZONE" set hai (`pubspec.yaml` → `name`, aur
  `android/app/src/main/AndroidManifest.xml` → `android:label`, jo
  `flutter create` se generate hone ke baad milega — neeche dekhein)

## 2. GitHub pe daalna

1. GitHub pe ek naya empty repository banayein (jaise `shanzone-app`)
2. Is poori folder ka content us repo me push kar dein

**ZAROORI:** Ye sirf `lib/`, `pubspec.yaml`, aur `assets/` hai — ek asli
Flutter project ke liye aapko pehle ek baar khali Flutter project
generate karna hoga taaki `android/`, `ios/` jaisi platform folders bhi
ban jaayein. Do tareeke:

**Option 1 — Apne computer pe (agar Flutter install hai):**
```bash
flutter create shanzone_app
# Phir is repo ke lib/, pubspec.yaml, assets/ ko us naye project me
# copy karke replace kar dein (uska khaali lib/pubspec.yaml overwrite karein)
cd shanzone_app
flutter pub get
```

**Option 2 — Bina apne computer pe kuch install kiye (recommended):**
GitHub Actions se seedha cloud me build ho sakta hai. Neeche diya
`.github/workflows/build-apk.yml` file is repo me add kar dein (agar
nahi hai), phir GitHub pe "Actions" tab me jaake workflow run karein —
APK ban ke "Artifacts" me download ke liye milega. Isme aapke computer
pe kuch bhi install nahi karna padta.

## 3. APK Banane Ka Sabse Aasan Tareeka: Codemagic

Agar GitHub Actions samajhne me dikkat ho, **Codemagic.io** use karein:
1. codemagic.io pe free account banayein
2. Apna GitHub repo connect karein
3. "Flutter App" template select karein
4. "Start new build" → Android → APK
5. Kuch minute me APK ban ke download link milega

Isme koi coding/terminal ki zaroorat nahi — sab UI se ho jaata hai.

## 4. App Kya Karti Hai

- **Splash** → Logo + naam
- **Login** → Mobile number → OTP (SMS Alert se, Apps Script ke through —
  API key kabhi app ke andar nahi jaati, isliye safe hai)
- **Home** → Naam se welcome, Active Plan card, Expiry progress bar,
  Recharge button → Plan select → UPI payment (QR ya UPI ID) → "I've Paid"
- **Speed Test** → Website ka wahi tested speed test (WebView me embed)
- **Profile** → Editable photo, naam, mobile (locked), address (locked),
  WhatsApp support button, Logout
- **Multi-account** → Agar ek mobile pe kai connections hain, top-left
  dropdown se switch kar sakte hain
- **Language** → Top-right har screen pe Hindi/English toggle
- **Fingerprint quick-login** → Ek baar OTP se login karne ke baad, agli
  baar fingerprint se seedha login ho sakta hai (bonus feature)

Sab kuch real-time Google Sheet se hi chalta hai — jo bhi Sheet me update
karenge, app me turant reflect hoga (Home page khulte hi latest data
fetch hota hai).

## 5. iOS (iPhone) Ke Baare Me

Ye code **sirf Android APK** ke liye hai. iPhone pe chalane ke liye poora
alag process hai (Apple Developer account, Xcode, App Store review) —
ye is project se directly possible nahi hai.
