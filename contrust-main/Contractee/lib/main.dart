import 'dart:ui';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_welcome.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/utils/supabase_config.dart';


class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad
      };
}

Future<void> main() async {

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;
  runApp(MyApp(isFirstOpen: isFirstOpen));
}

class MyApp extends StatelessWidget {

  final bool isFirstOpen;

  const MyApp({super.key, required this.isFirstOpen}); 

  

  @override
  Widget build(BuildContext context) {  
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      home: isFirstOpen ? WelcomePage() : HomePage(contracteeId: session!.user.id),
    );
  }
}