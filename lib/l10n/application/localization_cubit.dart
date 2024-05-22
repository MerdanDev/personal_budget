import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wallet/core/shared_preference.dart';

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
    }
  }
}
