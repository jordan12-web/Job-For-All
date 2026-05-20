import 'package:flutter/material.dart';

import '../data/info_content.dart';
import '../widgets/static_page_shell.dart';

/// Generic static content page for footer links (help, terms, careers, etc.).
class StaticInfoPage extends StatelessWidget {
  const StaticInfoPage({super.key, required this.data});

  final InfoPageData data;

  static InfoPageData? dataForLink(String link) => InfoContent.pages[link];

  @override
  Widget build(BuildContext context) {
    return StaticPageShell(
      title: data.title,
      subtitle: data.subtitle,
      body: data.body,
    );
  }
}
