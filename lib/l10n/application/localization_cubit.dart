import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/core/widget_service.dart';

class LocalizationCubit extends Cubit<Locale> {
  factory LocalizationCubit() => instance;
  LocalizationCubit._internal()
      : super(
          SingletonSharedPreference.loadLangCode() != null
              ? Locale(
                  SingletonSharedPreference.loadLangCode()!,
                )
              : Locale(Platform.localeName.substring(0, 2)),
        );
  static final LocalizationCubit instance = LocalizationCubit._internal();

  // late ThemeData _theme;

  Future<void> changeLocale(String selectedLanguage) async {
    if (selectedLanguage != state.languageCode) {
      await SingletonSharedPreference.setLangCode(selectedLanguage);
      emit(Locale(selectedLanguage));
      // Refresh the home-screen widget so its button labels follow the newly
      // selected language.
      unawaited(WidgetService.sync());
    }
  }
}
