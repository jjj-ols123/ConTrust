import 'package:backend/utils/supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/app_websitestart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ConTrust',
      home: kIsWeb ? const WebsiteStartPage() : const _NonWebPlaceholder(),
    );
  }
}

class _NonWebPlaceholder extends StatelessWidget {
  const _NonWebPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Use platform-specific apps on mobile. This entry is for web.'),
      ),
    );
  }
}