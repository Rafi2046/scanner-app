import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/providers/auth_provider.dart';
import 'package:scanner_app/views/home/home_view.dart';
import 'package:scanner_app/views/lock/app_lock_view.dart';

class ScannerApp extends ConsumerWidget {
  const ScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool locked = ref.watch(authNotifierProvider).isLocked;

    return MaterialApp(
      title: 'Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (BuildContext context, Widget? child) {
        return Stack(
          children: <Widget>[
            child ?? const SizedBox.shrink(),
            if (locked) const Positioned.fill(child: AppLockView()),
          ],
        );
      },
      home: const HomeView(),
    );
  }
}
