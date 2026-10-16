import 'package:equatable/equatable.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';
import '../../../prayer_times/domain/entities/prayer.dart';

enum OnboardingPage { welcome, location, notifications }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.page = OnboardingPage.welcome,
    this.location,
    this.nextPrayer,
    this.locating = false,
    this.locationFailure,
    this.requestingNotifications = false,
    this.notificationsDenied = false,
    this.done = false,
  });

  final OnboardingPage page;

  /// Found with the permission, or a city chosen by hand.
  final UserLocation? location;

  /// The next prayer at [location], shown on the notifications slide.
  final PrayerTime? nextPrayer;

  /// Waiting for the permission prompt or a fix.
  final bool locating;

  /// Why the location couldn't be found; the slide then explains and
  /// offers a city instead.
  final LocationFailure? locationFailure;

  final bool requestingNotifications;

  /// The notification permission was refused; the slide says how to turn
  /// it on later.
  final bool notificationsDenied;

  /// Finished or skipped: time for Home.
  final bool done;

  OnboardingState copyWith({
    OnboardingPage? page,
    UserLocation? location,
    PrayerTime? nextPrayer,
    bool? locating,
    LocationFailure? Function()? locationFailure,
    bool? requestingNotifications,
    bool? notificationsDenied,
    bool? done,
  }) => OnboardingState(
    page: page ?? this.page,
    location: location ?? this.location,
    nextPrayer: nextPrayer ?? this.nextPrayer,
    locating: locating ?? this.locating,
    locationFailure: locationFailure == null
        ? this.locationFailure
        : locationFailure(),
    requestingNotifications:
        requestingNotifications ?? this.requestingNotifications,
    notificationsDenied: notificationsDenied ?? this.notificationsDenied,
    done: done ?? this.done,
  );

  @override
  List<Object?> get props => [
    page,
    location,
    nextPrayer,
    locating,
    locationFailure,
    requestingNotifications,
    notificationsDenied,
    done,
  ];
}
