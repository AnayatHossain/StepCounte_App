import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingScreenBottomSheet extends StatefulWidget {
  final bool isDarkTheme;
  final bool isEnglish;
  final Function(bool) onThemeChanged;
  final Function(bool) onLanguageChanged;

  const SettingScreenBottomSheet({
    super.key,
    required this.isDarkTheme,
    required this.isEnglish,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<SettingScreenBottomSheet> createState() =>
      _SettingScreenBottomSheetState();
}

class _SettingScreenBottomSheetState extends State<SettingScreenBottomSheet> {
  late bool isDarkTheme;
  late bool isEnglish;
  final settingsBox = Hive.box('settingsBox');

  final List<Map<String, dynamic>> socialLinks = [
    {
      'icon': FontAwesomeIcons.facebookF,
      'url': 'https://www.facebook.com/anayathossainofficial',
      'fallback': 'https://m.facebook.com/anayathossainofficial',
    },
    {
      'icon': FontAwesomeIcons.linkedinIn,
      'url': 'linkedin://in/anayathossainofficial',
      'fallback': 'https://www.linkedin.com/in/anayathossainofficial',
    },
    {
      'icon': FontAwesomeIcons.github,
      'url': 'https://github.com/AnayatHossain',
    },
    {
      'icon': FontAwesomeIcons.twitter,
      'url': 'twitter://user?screen_name=AnayatOfficial',
      'fallback': 'https://x.com/AnayatOfficial',
    },
    {
      'icon': FontAwesomeIcons.instagram,
      'url': 'instagram://user?username=anayathossainofficial',
      'fallback': 'https://www.instagram.com/anayathossainofficial',
    },
    {
      'icon': FontAwesomeIcons.youtube,
      'url': 'vnd.youtube://channel/UCXYZ', // Replace with actual channel ID
      'fallback': 'https://www.youtube.com/@AnayatHossainOfficial',
    },
  ];

  @override
  void initState() {
    super.initState();
    isDarkTheme = widget.isDarkTheme;
    isEnglish = widget.isEnglish;
  }

  void _updateTheme(bool value) {
    setState(() => isDarkTheme = value);
    settingsBox.put('isDarkTheme', value);
    widget.onThemeChanged(value);
  }

  void _updateLanguage(bool value) {
    setState(() => isEnglish = value);
    settingsBox.put('isEnglish', value);
    widget.onLanguageChanged(value);
  }

  Future<void> _launchSocialUrl(String url, String? fallback) async {
    try {
      final uri = Uri.parse(url);

      // First try launching the app-specific URL
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        return;
      }

      // If app not installed, try fallback URL
      if (fallback != null) {
        final fallbackUri = Uri.parse(fallback);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Could not open link'
                  : 'লিঙ্ক খুলতে ব্যর্থ হয়েছে',
            ),
          ),
        );
      }
      debugPrint('Could not launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          gradient: widget.isDarkTheme
              ? LinearGradient(colors: [Colors.blue[400]!, Colors.blue[600]!])
              : null,
          color: widget.isDarkTheme ? null : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDarkTheme ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: widget.isDarkTheme ? Colors.white : Colors.black),
              const SizedBox(height: 20),

              // Theme Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEnglish ? "Theme" : "থিম",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        widget.isEnglish
                            ? (isDarkTheme ? "Dark" : "Light")
                            : (isDarkTheme ? "ডার্ক" : "লাইট"),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkTheme
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Switch(value: isDarkTheme, onChanged: _updateTheme),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Language Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEnglish ? "Language" : "ভাষা",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        widget.isEnglish ? "English" : "বাংলা",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkTheme
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Switch(value: isEnglish, onChanged: _updateLanguage),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(
                thickness: 1,
                color: widget.isDarkTheme ? Colors.white : Colors.black,
              ),
              const SizedBox(height: 8),

              // Developer Info Section
              _buildSection(
                context,
                title: widget.isEnglish
                    ? 'Meet the Innovator Behind App'
                    : 'অ্যাপ নির্মাতার সাথে পরিচিত হোন',
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/profile.JPG',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  widget.isEnglish
                                      ? 'Anayat Hossain'
                                      : 'এনায়েত হোসেন',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isDarkTheme
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: 'Verified account',
                                  child: Icon(
                                    Icons.verified,
                                    color: widget.isDarkTheme
                                        ? Colors.white
                                        : Colors.blue,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              widget.isEnglish
                                  ? 'B.Sc. Engg. in CSE at BUBT'
                                  : 'বিএসসি ইন সিএসই ইঞ্জিনিয়ার, বিইউবিটি',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.isDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              widget.isEnglish
                                  ? 'Founder & CEO of DigiDev Solution'
                                  : 'প্রতিষ্ঠাতা ও সিইও, DigiDev Solution',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: widget.isDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Social Icons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: socialLinks.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildSocialIcon(
                        item['icon'],
                        item['url'],
                        item['fallback'],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Divider(
                thickness: 1,
                color: widget.isDarkTheme ? Colors.white : Colors.black,
              ),
              const SizedBox(height: 10),

              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      widget.isEnglish ? "Version 1.0.1" : "ভার্সন ১.০.১",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.isEnglish
                          ? "© Anayat Hossain All rights reserved."
                          : "© এনায়েত হোসেন সর্বস্বত্ব সংরক্ষিত।",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String url, [String? fallbackUrl]) {
    return GestureDetector(
      onTap: () => _launchSocialUrl(url, fallbackUrl),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: widget.isDarkTheme ? Colors.white12 : Colors.black12,
        child: Icon(
          icon,
          size: 16,
          color: widget.isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
