import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';

/// Settings → About: the app's version, the privacy policy (opened in the
/// browser) and the licenses page (packages, the bundled fonts and the
/// adhan recording, see `app_licenses.dart`).
///
/// Not in the design.
class AboutGroup extends StatefulWidget {
  const AboutGroup({super.key});

  @override
  State<AboutGroup> createState() => _AboutGroupState();
}

class _AboutGroupState extends State<AboutGroup> {
  final _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        // "1.0.0 (1)": the version name and the build number.
        final version = info == null
            ? null
            : context.format.digits(
                info.buildNumber.isEmpty
                    ? info.version
                    : LocaleKeys.settings_version_value.tr(
                        args: [info.version, info.buildNumber],
                      ),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: HayyaSpacing.s2,
          children: [
            SettingsTile(
              title: LocaleKeys.settings_version.tr(),
              trailing: Padding(
                padding: EdgeInsetsDirectional.only(end: 12.r),
                child: Text(
                  version ?? '',
                  style: context.type
                      .style(14, FontWeight.w700)
                      .copyWith(color: context.colors.muted),
                ),
              ),
            ),
            SettingsTile(
              title: LocaleKeys.settings_privacy_policy.tr(),
              subtitle: LocaleKeys.settings_privacy_policy_sub.tr(),
              onTap: () => _openPrivacyPolicy(context),
            ),
            SettingsTile(
              title: LocaleKeys.settings_licenses.tr(),
              subtitle: LocaleKeys.settings_licenses_sub.tr(),
              onTap: () => showLicensePage(
                context: context,
                useRootNavigator: true,
                applicationName: LocaleKeys.app_name.tr(),
                applicationVersion: version,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The published policy (the `hayya-privacy` repository on GitHub Pages),
/// in the app's language.
Uri privacyPolicyUrl(String languageCode) => Uri.https(
  'ahmed-waheed1.github.io',
  languageCode == 'ar' ? '/hayya-privacy/ar.html' : '/hayya-privacy/',
);

Future<void> _openPrivacyPolicy(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final url = privacyPolicyUrl(context.locale.languageCode);
  final failed = LocaleKeys.settings_privacy_policy_failed.tr(
    args: [url.toString()],
  );
  final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
}
