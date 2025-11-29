import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/auth/auth_bloc.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(),
        ),
        // Thêm các bloc khác nếu cần
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Local Service Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
