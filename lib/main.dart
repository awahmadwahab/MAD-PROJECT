import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_state.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'router.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CampuScanApp());
}

class CampuScanApp extends StatefulWidget {
  const CampuScanApp({super.key});

  @override
  State<CampuScanApp> createState() => _CampuScanAppState();
}

class _CampuScanAppState extends State<CampuScanApp> {
  late final AppState _appState;
  late final GoRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appRouter = createAppRouter(_appState);
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appState,
      child: MaterialApp.router(
        title: 'CampuScan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _appRouter,
      ),
    );
  }
}
