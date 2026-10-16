import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/user_location.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../cubit/location_settings_cubit.dart';

/// A search field and the matching cities. Choosing one makes it the
/// location (through [LocationSettingsCubit.choose]), then calls
/// [onChosen].
///
/// Used in Settings → Location (Manual) and onboarding's "Choose a city".
/// Needs a [LocationSettingsCubit] above it.
class CitySearch extends StatefulWidget {
  const CitySearch({super.key, this.onChosen, this.autofocus = false});

  final ValueChanged<UserLocation>? onChosen;
  final bool autofocus;

  @override
  State<CitySearch> createState() => _CitySearchState();
}

class _CitySearchState extends State<CitySearch> {
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
    widget.onChosen?.call(place);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LocationSettingsCubit>();
    final state = context.watch<LocationSettingsCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: HayyaSpacing.s3,
      children: [
        _SearchField(
          controller: _query,
          onChanged: cubit.search,
          autofocus: widget.autofocus,
        ),
        _SearchResults(state: state, onChoose: _choose),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.autofocus,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;

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
              autofocus: autofocus,
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
