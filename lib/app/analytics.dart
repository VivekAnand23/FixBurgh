import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Journey events for Burghood: society, channels, services and providers.
///
/// Each event also leaves a Crashlytics breadcrumb, so a crash report shows
/// the steps that led to it. Parameters never carry names, text, IDs or
/// places: only the kinds of things below, so nothing identifies a person.
abstract class Analytics {
  const Analytics();

  Future<void> log(String event, [Map<String, Object> params = const {}]);

  // Society.
  Future<void> societySearch({required int results}) =>
      log('society_search', {'results': results});
  Future<void> societyJoinRequested() => log('society_join_requested');
  Future<void> societyJoinedWithCode() => log('society_joined_with_code');
  Future<void> societyClaimSubmitted() => log('society_claim_submitted');

  // Channels.
  Future<void> channelPost({required int photos}) =>
      log('channel_post', {'photos': photos});
  Future<void> channelComment({required bool reply}) =>
      log('channel_comment', {'reply': reply ? 1 : 0});
  Future<void> channelReaction() => log('channel_reaction');

  // Services.
  Future<void> providerSearch({
    required bool typed,
    required int miles,
    required int results,
  }) => log('provider_search', {
    'typed': typed ? 1 : 0,
    'miles': miles,
    'results': results,
  });
  Future<void> serviceRequestPosted({
    required String category,
    required String scope,
    required bool hasProvider,
  }) => log('service_request_posted', {
    'category': category,
    'scope': scope,
    'has_provider': hasProvider ? 1 : 0,
  });
  Future<void> serviceRequestStep(String status) =>
      log('service_request_step', {'status': status});
  Future<void> reviewPosted({required int stars}) =>
      log('review_posted', {'stars': stars});

  // Providers.
  Future<void> providerApplied({required int categories}) =>
      log('provider_applied', {'categories': categories});
}

/// Does nothing; the default where Firebase isn't set up, as in tests.
class NoAnalytics extends Analytics {
  const NoAnalytics();

  @override
  Future<void> log(String event, [Map<String, Object> params = const {}]) =>
      Future.value();
}

class FirebaseJourneyAnalytics extends Analytics {
  const FirebaseJourneyAnalytics(this._analytics, this._crashlytics);

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> log(
    String event, [
    Map<String, Object> params = const {},
  ]) async {
    // Analytics must never break the step it records.
    try {
      await _crashlytics.log(
        params.isEmpty ? event : '$event $params',
      );
      await _analytics.logEvent(name: event, parameters: params);
    } on Object {
      // Ignored.
    }
  }
}

/// Overridden in `bootstrap` with [FirebaseJourneyAnalytics].
final analyticsProvider = Provider<Analytics>((ref) => const NoAnalytics());
