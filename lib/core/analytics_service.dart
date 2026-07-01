import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around Firebase Analytics used only for anonymous app-usage
/// metrics (daily / weekly / monthly active users).
///
/// Firebase derives DAU/WAU/MAU automatically from the `session_start` and
/// `user_engagement` events it logs once collection is enabled — those counts
/// are keyed on a pseudonymous per-install app-instance id, not on any user
/// identity. To stay within our privacy policy this service deliberately:
///   * never calls [FirebaseAnalytics.setUserId] or sets user properties,
///   * disables collection of advertising/consent-based identifiers.
/// So no user is identified; we only ever learn *how many* installs are active.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Navigator observer that logs `screen_view` events, which feed the
  /// engagement/active-user metrics. Attach to `MaterialApp.navigatorObservers`.
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Enables anonymous usage collection and records the launch. Safe to call
  /// once during bootstrap after `Firebase.initializeApp`.
  static Future<void> init() async {
    // Explicitly opt out of any identity/ad signals; keep only aggregate usage.
    await _analytics.setConsent(
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
      analyticsStorageConsentGranted: true,
    );
    await _analytics.setAnalyticsCollectionEnabled(true);
    await _analytics.logAppOpen();
  }
}
