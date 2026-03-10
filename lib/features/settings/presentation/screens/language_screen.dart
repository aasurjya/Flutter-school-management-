import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// Map from language code to flag emoji.
const _flagEmojis = {
  'en': '🇬🇧',
  'fr': '🇫🇷',
  'hi': '🇮🇳',
  'ar': '🇸🇦',
};

/// Map from language code to the name shown in English.
const _englishNames = {
  'en': 'English',
  'fr': 'French',
  'hi': 'Hindi',
  'ar': 'Arabic',
};

class _RadioDot<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final Color activeColor;

  const _RadioDot({
    super.key,
    required this.value,
    required this.groupValue,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? activeColor : const Color(0xFF9CA3AF),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              ),
            )
          : null,
    );
  }
}

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
      ),
      body: ListView(
        children: LocaleNotifier.supportedLocales.map((locale) {
          final code = locale.languageCode;
          final flag = _flagEmojis[code] ?? '';
          final nativeName = LocaleNotifier.localeNames[code] ?? code;
          final englishName = _englishNames[code] ?? code;
          final isSelected = currentLocale.languageCode == code;

          return ListTile(
            leading: _RadioDot<Locale>(
              value: locale,
              groupValue: currentLocale,
              activeColor: theme.colorScheme.primary,
            ),
            title: Row(
              children: [
                Text(
                  flag,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nativeName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.titleSmall?.color,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    Text(
                      englishName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(locale);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('App will restart to apply changes'),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
