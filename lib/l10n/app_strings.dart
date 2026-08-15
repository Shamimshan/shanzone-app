import 'package:flutter/foundation.dart';

/// Lightweight custom localization (no .arb pipeline needed).
/// `AppLocale.current` is a ValueNotifier the whole app listens to —
/// flipping the top-right language toggle updates every screen instantly.
enum AppLang { en, hi }

class AppLocale {
  AppLocale._();
  static final ValueNotifier<AppLang> current = ValueNotifier(AppLang.en);

  static void toggle() {
    current.value = current.value == AppLang.en ? AppLang.hi : AppLang.en;
  }
}

class S {
  S._();

  static const Map<String, Map<AppLang, String>> _strings = {
    // Splash
    'appName': {AppLang.en: 'SHAN ZONE', AppLang.hi: 'शान ज़ोन'},
    'tagline': {
      AppLang.en: 'Fast. Reliable. Always Connected.',
      AppLang.hi: 'तेज़। भरोसेमंद। हमेशा कनेक्टेड।'
    },

    // Login
    'welcomeBack': {AppLang.en: 'Welcome Back', AppLang.hi: 'वापसी पर स्वागत है'},
    'loginSubtitle': {
      AppLang.en: 'Login with your registered mobile number',
      AppLang.hi: 'अपने रजिस्टर्ड मोबाइल नंबर से लॉगिन करें'
    },
    'mobileNumber': {AppLang.en: 'Mobile Number', AppLang.hi: 'मोबाइल नंबर'},
    'sendOtp': {AppLang.en: 'Send OTP', AppLang.hi: 'OTP भेजें'},
    'enterOtp': {AppLang.en: 'Enter OTP', AppLang.hi: 'OTP दर्ज करें'},
    'otpSentTo': {AppLang.en: 'OTP sent to', AppLang.hi: 'OTP भेजा गया'},
    'verifyLogin': {AppLang.en: 'Verify & Login', AppLang.hi: 'सत्यापित करें और लॉगिन करें'},
    'resendOtp': {AppLang.en: 'Resend OTP', AppLang.hi: 'OTP दोबारा भेजें'},
    'changeNumber': {AppLang.en: 'Change Number', AppLang.hi: 'नंबर बदलें'},
    'invalidMobile': {
      AppLang.en: 'Enter a valid 10-digit mobile number',
      AppLang.hi: 'सही 10 अंकों का मोबाइल नंबर दर्ज करें'
    },
    'invalidOtp': {AppLang.en: 'Incorrect code, try again', AppLang.hi: 'गलत OTP, दोबारा कोशिश करें'},
    'verifying': {AppLang.en: 'VERIFYING', AppLang.hi: 'सत्यापित हो रहा है'},
    'verifiedSuccess': {AppLang.en: 'Verified successfully', AppLang.hi: 'सफलतापूर्वक सत्यापित'},
    'notRegistered': {
      AppLang.en: 'This mobile number is not linked to any SHAN ZONE account.',
      AppLang.hi: 'यह मोबाइल नंबर किसी भी शान ज़ोन खाते से जुड़ा नहीं है।'
    },

    // Home
    'welcome': {AppLang.en: 'Welcome', AppLang.hi: 'स्वागत है'},
    'activePlan': {AppLang.en: 'Active Plan', AppLang.hi: 'सक्रिय प्लान'},
    'expiresOn': {AppLang.en: 'Expires on', AppLang.hi: 'समाप्ति तिथि'},
    'daysLeft': {AppLang.en: 'days left', AppLang.hi: 'दिन बचे हैं'},
    'expired': {AppLang.en: 'Expired', AppLang.hi: 'समाप्त हो गया'},
    'recharge': {AppLang.en: 'Recharge Now', AppLang.hi: 'रीचार्ज करें'},
    'chooseAccount': {AppLang.en: 'Choose Account', AppLang.hi: 'खाता चुनें'},
    'userId': {AppLang.en: 'User ID', AppLang.hi: 'यूज़र आईडी'},

    // Recent payment card + quick actions (Home)
    'lastPayment': {AppLang.en: 'Last Payment', AppLang.hi: 'आख़िरी भुगतान'},
    'viewAll': {AppLang.en: 'View All', AppLang.hi: 'सभी देखें'},
    'callSupport': {AppLang.en: 'Call', AppLang.hi: 'कॉल करें'},

    // Recharge sheet
    'selectPlan': {AppLang.en: 'Select a Plan', AppLang.hi: 'प्लान चुनें'},
    'payNow': {AppLang.en: 'Pay Now', AppLang.hi: 'अभी भुगतान करें'},
    'currentPlanTag': {AppLang.en: 'Current Plan', AppLang.hi: 'मौजूदा प्लान'},
    'scanQr': {AppLang.en: 'Scan QR', AppLang.hi: 'QR स्कैन करें'},
    'enterUpiId': {AppLang.en: 'Enter UPI ID', AppLang.hi: 'UPI ID दर्ज करें'},
    'openUpiApp': {AppLang.en: 'Open in UPI App', AppLang.hi: 'UPI ऐप में खोलें'},
    'ivePaid': {AppLang.en: "I've Paid", AppLang.hi: 'मैंने भुगतान कर दिया है'},
    'ivePaidHint': {
      AppLang.en: "Tap after paying — we'll verify & activate your plan shortly.",
      AppLang.hi: 'भुगतान के बाद दबाएँ — हम जल्द ही सत्यापित कर आपका प्लान सक्रिय करेंगे।'
    },
    'claimSubmitted': {
      AppLang.en: 'Thank you! Your plan will be activated after verification.',
      AppLang.hi: 'धन्यवाद! सत्यापन के बाद आपका प्लान सक्रिय कर दिया जाएगा।'
    },
    'claimFailed': {
      AppLang.en: 'Could not submit. Check your internet and try again.',
      AppLang.hi: 'सबमिट नहीं हो पाया। इंटरनेट जांचें और दोबारा प्रयास करें।'
    },

    // Bottom nav
    'navHome': {AppLang.en: 'Home', AppLang.hi: 'होम'},
    'navSpeed': {AppLang.en: 'Speed Test', AppLang.hi: 'स्पीड टेस्ट'},
    'navHistory': {AppLang.en: 'History', AppLang.hi: 'इतिहास'},
    'navProfile': {AppLang.en: 'Profile', AppLang.hi: 'प्रोफ़ाइल'},

    // Profile
    'editPhoto': {AppLang.en: 'Edit Photo', AppLang.hi: 'फ़ोटो बदलें'},
    'mobile': {AppLang.en: 'Mobile Number', AppLang.hi: 'मोबाइल नंबर'},
    'address': {AppLang.en: 'Address', AppLang.hi: 'पता'},
    'whatsappSupport': {
      AppLang.en: 'Chat with Support on WhatsApp',
      AppLang.hi: 'WhatsApp पर सपोर्ट से बात करें'
    },
    'logout': {AppLang.en: 'Logout', AppLang.hi: 'लॉगआउट'},
    'camera': {AppLang.en: 'Camera', AppLang.hi: 'कैमरा'},
    'gallery': {AppLang.en: 'Gallery', AppLang.hi: 'गैलरी'},

    // Plans
    'lite': {AppLang.en: 'Lite Plan', AppLang.hi: 'लाइट प्लान'},
    'pro': {AppLang.en: 'Pro Plan', AppLang.hi: 'प्रो प्लान'},
    'boost': {AppLang.en: 'Boost Plan', AppLang.hi: 'बूस्ट प्लान'},

    // Speed test
    'speedTestTitle': {AppLang.en: 'Speed Test', AppLang.hi: 'स्पीड टेस्ट'},
    'speedTestIdle': {AppLang.en: 'Tap start to test your speed', AppLang.hi: 'Speed test karne ke liye start dabayein'},
    'speedTestPinging': {AppLang.en: 'Checking ping...', AppLang.hi: 'Ping check ho raha hai...'},
    'speedTestDownloading': {AppLang.en: 'Testing download...', AppLang.hi: 'Download test ho raha hai...'},
    'speedTestUploading': {AppLang.en: 'Testing upload...', AppLang.hi: 'Upload test ho raha hai...'},
    'speedTestComplete': {AppLang.en: 'Test complete', AppLang.hi: 'Test poora hua'},
    'speedTestStart': {AppLang.en: 'Start Test', AppLang.hi: 'Test Shuru Karein'},
    'speedTestRunning': {AppLang.en: 'Testing...', AppLang.hi: 'Test ho raha hai...'},
    'download': {AppLang.en: 'Download', AppLang.hi: 'Download'},
    'upload': {AppLang.en: 'Upload', AppLang.hi: 'Upload'},
    'ping': {AppLang.en: 'Ping', AppLang.hi: 'Ping'},

    // Payment History
    'paymentHistory': {AppLang.en: 'Payment History', AppLang.hi: 'भुगतान इतिहास'},
    'noPayments': {AppLang.en: 'No payments yet', AppLang.hi: 'अभी तक कोई भुगतान नहीं'},
    'verified': {AppLang.en: 'Verified', AppLang.hi: 'सत्यापित'},
    'pending': {AppLang.en: 'Pending', AppLang.hi: 'लंबित'},

    // Common
    'cancel': {AppLang.en: 'Cancel', AppLang.hi: 'रद्द करें'},
    'ok': {AppLang.en: 'OK', AppLang.hi: 'ठीक है'},
    'loading': {AppLang.en: 'Loading...', AppLang.hi: 'लोड हो रहा है...'},
    'somethingWrong': {
      AppLang.en: 'Something went wrong. Please try again.',
      AppLang.hi: 'कुछ गड़बड़ हो गई। कृपया दोबारा प्रयास करें।'
    },
  };

  static String of(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[AppLocale.current.value] ?? entry[AppLang.en] ?? key;
  }
}
