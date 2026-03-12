import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _notificationsKey = 'notifications_enabled';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationsPreference();
  }

  Future<void> _loadNotificationsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    });
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    setState(() => _notificationsEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return SwitchListTile(
                title: Text(l10n.darkMode),
                subtitle: Text(
                  themeProvider.themeMode == ThemeMode.dark ? 'On' : 'Off',
                ),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (_) => themeProvider.toggleTheme(),
              );
            },
          ),
          const Divider(height: 1),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return ListTile(
                title: Text(l10n.language),
                subtitle: Text(
                  LocaleProvider.localeNames[localeProvider.locale.languageCode] ??
                      localeProvider.locale.languageCode,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageSheet(context, localeProvider),
              );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(l10n.notifications),
            value: _notificationsEnabled,
            onChanged: _setNotificationsEnabled,
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(l10n.about),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context, l10n),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, LocaleProvider localeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleProvider.supportedLocales.map((locale) {
            final name = LocaleProvider.localeNames[locale.languageCode] ?? locale.languageCode;
            final isSelected = localeProvider.locale.languageCode == locale.languageCode;
            return ListTile(
              title: Text(name),
              trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                localeProvider.setLocale(locale);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: l10n.appName,
      applicationVersion: '1.0.0',
      applicationLegalese: 'RideLink - Real-Time Carpooling Platform for Daily Commuters',
    );
  }
}
