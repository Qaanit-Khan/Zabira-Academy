import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

/// Zabira Academy Root App Widget
class ZabiraApp extends StatelessWidget {
  const ZabiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _RouterScope();
  }
}

class _RouterScope extends StatefulWidget {
  @override
  State<_RouterScope> createState() => _RouterScopeState();
}

class _RouterScopeState extends State<_RouterScope> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= buildRouter(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zabira Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router!,
    );
  }
}
