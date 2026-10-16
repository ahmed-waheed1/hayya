import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../prayer_times/presentation/prayer_display.dart';
import '../cubit/location_settings_cubit.dart';

/// Settings → Location: Automatic shows the device's location with a
/// refresh; Manual searches for a city to use instead.
///
/// Needs a [LocationSettingsCubit] above it.
class LocationGroup extends StatefulWidget {
  const LocationGroup({super.key});

  @override
  State<LocationGroup> createState() => _LocationGroupState();
}

class _LocationGroupState extends State<LocationGroup> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _choose(UserLocation place) async {
    FocusScope.of(context).unfocus();
    _query.clear();
    await context.read<LocationSettingsCubit>().choose(place);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LocationSettingsCubit>();
    final state = context.watch<LocationSettingsCubit>().state;
    final manual = state.source == LocationSource.manual;
    return HayyaCard(
      padding: EdgeInsetsDirectional.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HayyaSpacing.s3,
        children: [
          SegmentedPicker<LocationSource>(
            options: [
              SegmentOption(
                value: LocationSource.automatic,
                label: LocaleKeys.settings_location_automatic.tr(),
              ),
              SegmentOption(
                value: LocationSource.manual,
                label: LocaleKeys.settings_location_manual.tr(),
              ),
            ],
            value: state.source,
            onChanged: (source) => source == LocationSource.manual
                ? cubit.showManual()
                : cubit.showAutomatic(),
          ),
          if (state.failure case final failure?) _FailureNote(failure),
          if (manual) ...[
            if (state.usingManual && state.location != null)
              _CurrentPlace(
                location: state.location!,
                detail: LocaleKeys.settings_location_chosen.tr(),
              ),
            _SearchField(controller: _query, onChanged: cubit.search),
            _SearchResults(state: state, onChoose: _choose),
          ] else ...[
            switch (state.location) {
              final location? => _CurrentPlace(
                location: location,
                detail: context.format.lastUpdated(
                  location.updatedAt,
                  DateTime.now(),
                ),
              ),
              null => const _NoPlace(),
            },
            _UpdateButton(locating: state.locating, onPressed: cubit.refresh),
          ],
        ],
      ),
    );
  }
}

/// Pin badge, "Cairo, Egypt", then coordinates and [detail].
class _CurrentPlace extends StatelessWidget {
  const _CurrentPlace({required this.location, required this.detail});

  final UserLocation location;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 2.r, vertical: 4.r),
      child: Row(
        spacing: HayyaSpacing.s3,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: HayyaIcon(
              HayyaIcons.location,
              size: 22,
              color: c.primaryInk,
              strokeWidth: 1.9,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2.r,
              children: [
                Text(
                  location.placeLabel(context.locale),
                  style: type
                      .style(15, FontWeight.w800)
                      .copyWith(color: c.text),
                ),
                Text(
                  LocaleKeys.settings_location_detail.tr(
                    args: [
                      context.format.coordinates(location.coordinates),
                      detail,
                    ],
                  ),
                  style: type
                      .style(12.5, FontWeight.w600)
                      .copyWith(color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPlace extends StatelessWidget {
  const _NoPlace();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2.r,
      children: [
        Text(
          LocaleKeys.settings_location_none.tr(),
          style: type.style(15, FontWeight.w800).copyWith(color: c.text),
        ),
        Text(
          LocaleKeys.settings_location_none_sub.tr(),
          style: type.style(12.5, FontWeight.w600).copyWith(color: c.muted),
        ),
      ],
    );
  }
}

/// Why the last "Update location" failed, with the way to fix it when
/// there is one.
class _FailureNote extends StatelessWidget {
  const _FailureNote(this.failure);

  final LocationFailure failure;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (title, action) = switch (failure) {
      LocationFailure.permissionDenied => (
        LocaleKeys.location_denied_title.tr(),
        null,
      ),
      LocationFailure.permissionDeniedForever => (
        LocaleKeys.location_denied_title.tr(),
        LocaleKeys.location_open_settings.tr(),
      ),
      LocationFailure.serviceDisabled => (
        LocaleKeys.location_unavailable_title.tr(),
        LocaleKeys.location_location_settings.tr(),
      ),
      LocationFailure.unavailable => (
        LocaleKeys.location_unavailable_title.tr(),
        null,
      ),
    };
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(14.r, 10.r, 6.r, 10.r),
      decoration: BoxDecoration(
        color: c.dangerSoft,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        spacing: HayyaSpacing.s2,
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                title,
                style: context.type
                    .style(13.5, FontWeight.w700)
                    .copyWith(color: c.danger),
              ),
            ),
          ),
          if (action != null)
            HayyaButton(
              label: action,
              variant: HayyaButtonVariant.text,
              onPressed: () => context
                  .read<LocationSettingsCubit>()
                  .openSettingsFor(failure),
            ),
        ],
      ),
    );
  }
}

class _UpdateButton extends StatelessWidget {
  const _UpdateButton({required this.locating, required this.onPressed});

  final bool locating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(14.r);
    return Semantics(
      button: true,
      enabled: !locating,
      child: Material(
        color: c.primarySoft,
        borderRadius: radius,
        child: InkWell(
          onTap: locating ? null : onPressed,
          borderRadius: radius,
          child: Container(
            constraints: BoxConstraints(minHeight: 48.r),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: HayyaSpacing.s3,
              vertical: HayyaSpacing.s2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: HayyaSpacing.s2,
              children: [
                if (locating)
                  SizedBox.square(
                    dimension: 18.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: c.primaryInk,
                    ),
                  )
                else
                  HayyaIcon(
                    HayyaIcons.retry,
                    size: 18,
                    color: c.primaryInk,
                    strokeWidth: 2,
                  ),
                Flexible(
                  child: Text(
                    LocaleKeys.home_update_location.tr(),
                    textAlign: TextAlign.center,
                    style: context.type
                        .style(15, FontWeight.w800)
                        .copyWith(color: c.primaryInk),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.type.style(16, FontWeight.w600);
    return Container(
      constraints: BoxConstraints(minHeight: 50.r),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 14.r,
        vertical: HayyaSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: c.primaryInk, width: 2),
      ),
      child: Row(
        spacing: 10.r,
        children: [
          HayyaIcon(
            HayyaIcons.search,
            size: 20,
            color: c.muted,
            strokeWidth: 2,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: style.copyWith(color: c.text),
              cursorColor: c.primaryInk,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: LocaleKeys.settings_search_city.tr(),
                hintStyle: style.copyWith(color: c.faint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.state, required this.onChoose});

  final LocationSettingsState state;
  final ValueChanged<UserLocation> onChoose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final message = switch (state.searchStatus) {
      PlaceSearchStatus.idle => null,
      PlaceSearchStatus.searching => LocaleKeys.settings_searching.tr(),
      PlaceSearchStatus.failed => LocaleKeys.settings_search_failed.tr(),
      PlaceSearchStatus.done when state.results.isEmpty =>
        LocaleKeys.settings_search_no_results.tr(args: [state.query.trim()]),
      PlaceSearchStatus.done => null,
    };
    if (message != null) {
      return Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 4.r),
        child: Semantics(
          liveRegion: true,
          child: Text(
            message,
            style: context.type
                .style(13, FontWeight.w600)
                .copyWith(color: c.muted),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, place) in state.results.indexed) ...[
          if (i > 0) Divider(color: c.line, height: 1),
          _ResultRow(place: place, onTap: () => onChoose(place)),
        ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.place, required this.onTap});

  final UserLocation place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final name = place.placeName(context.locale.languageCode);
    final coordinates = context.format.coordinates(place.coordinates);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 52.r),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: 4.r,
              vertical: 6.r,
            ),
            child: Row(
              spacing: HayyaSpacing.s3,
              children: [
                HayyaIcon(
                  HayyaIcons.location,
                  size: 18,
                  color: c.muted,
                  strokeWidth: 1.9,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1.r,
                    children: [
                      Text(
                        name?.city ?? name?.country ?? coordinates,
                        style: type
                            .style(15, FontWeight.w700)
                            .copyWith(color: c.text),
                      ),
                      Text(
                        switch (name) {
                          PlaceName(city: _?, country: final country?) =>
                            LocaleKeys.settings_location_detail.tr(
                              args: [country, coordinates],
                            ),
                          _ => coordinates,
                        },
                        style: type
                            .style(12.5, FontWeight.w600)
                            .copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
