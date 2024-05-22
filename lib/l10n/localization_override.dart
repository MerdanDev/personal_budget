import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/l10n/application/localization_cubit.dart';
import 'package:wallet/l10n/custom_localization.dart';
import 'package:wallet/l10n/tk_intl.dart';

/// The widget that is required if you want to build
/// other widgets with a context containing
/// [TkMaterialLocalizations.delegate] and
/// [CupertinoLocalizationTk.delegate]
class LocalizationOverride extends StatelessWidget {
  const LocalizationOverride({required this.builder, super.key});
  final Widget Function(BuildContext) builder;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationCubit, Locale>(
      bloc: LocalizationCubit.instance,
      builder: (_, locale) {
        return Localizations.override(
          context: context,
          locale: locale,
          delegates: CustomLocalization.delegates,
          child: Builder(
            builder: builder,
          ),
        );
      },
    );
  }
}
