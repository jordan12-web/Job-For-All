import 'package:flutter/material.dart';

import '../data/info_content.dart';
import '../widgets/static_page_shell.dart';

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  static const String routeName = '/blog';

  @override
  Widget build(BuildContext context) {
    final InfoPageData data = InfoContent.pages['Blog']!;

    return StaticPageShell(
      title: data.title,
      subtitle: data.subtitle,
      body: data.body,
    );
  }
}
