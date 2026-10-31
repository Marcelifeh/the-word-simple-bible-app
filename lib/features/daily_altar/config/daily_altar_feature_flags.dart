/// Runtime-independent feature controls for My Daily Altar.
///
/// MDA-1 intentionally keeps the feature disabled and disconnected from
/// application navigation. Later phases may replace this constant with a
/// remotely configurable feature flag.
///
/// Existing application features must never depend on this flag.
abstract final class DailyAltarFeatureFlags {
  /// Master kill switch for the My Daily Altar feature.
  ///
  /// Must remain false throughout MDA-1.
  static const bool enabled = false;

  /// Premium entitlement enforcement is deliberately not active yet.
  ///
  /// Billing and entitlement infrastructure will be introduced in a later
  /// phase only after the feature itself is stable.
  static const bool premiumGateEnabled = false;
}
