import 'package:fixburgh/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-app text size on top of the system setting (BRD FR-PRF-02).
enum TextSize {
  system(1),
  large(1.15),
  larger(1.3);

  const TextSize(this.factor);

  /// Multiplies the system text scale.
  final double factor;
}

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textSize = TextSize.system,
  });

  final ThemeMode themeMode;
  final TextSize textSize;
}

/// Display settings, stored on the device.
final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const _themeKey = 'settings.theme';
  static const _textKey = 'settings.textSize';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    T byName<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return AppSettings(
      themeMode: byName(
        ThemeMode.values,
        prefs.getString(_themeKey),
        ThemeMode.system,
      ),
      textSize: byName(
        TextSize.values,
        prefs.getString(_textKey),
        TextSize.system,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AppSettings(themeMode: mode, textSize: state.textSize);
    await ref.read(sharedPreferencesProvider).setString(_themeKey, mode.name);
  }

  Future<void> setTextSize(TextSize size) async {
    state = AppSettings(themeMode: state.themeMode, textSize: size);
    await ref.read(sharedPreferencesProvider).setString(_textKey, size.name);
  }
}

/// Applies [TextSize] on top of the system text scale.
class AppTextScale extends StatelessWidget {
  const AppTextScale({required this.size, required this.child, super.key});

  final TextSize size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (size == TextSize.system) return child;
    final media = MediaQuery.of(context);
    final system = media.textScaler.scale(1);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(system * size.factor),
      ),
      child: child,
    );
  }
}
