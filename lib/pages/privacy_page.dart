import 'package:flutter/material.dart';

import '../data/info_content.dart';
import '../widgets/static_page_shell.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const String routeName = '/privacy';

  @override
  Widget build(BuildContext context) {
    final InfoPageData data = InfoContent.pages['Privacy Policy']!;

    return StaticPageShell(
      title: data.title,
      subtitle: data.subtitle,
      body: data.body,
    );
  }
}
