import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:contractor/Screen/cor_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';  
import 'package:flutter_quill/flutter_quill.dart';  
import 'package:supabase_flutter/supabase_flutter.dart';


final url = 'https://bgihfdqruamnjionhkeq.supabase.co';
final key =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJnaWhmZHFydWFtbmppb25oa2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4NzIyODksImV4cCI6MjA1NjQ0ODI4OX0.-GRaolUVu1hW6NUaEAwJuYJo8C2X5_1wZ-qB4a-9Txs';
final String bgScreen = "assets/bgloginscreen.jpg";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalization.instance.ensureInitialized();
  await Supabase.initialize(url: url, anonKey: key);

  runApp(MyApp());
}

class MyApp extends StatefulWidget { 
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();  
}

class _MyAppState extends State<MyApp> {  
  final FlutterLocalization _localization = FlutterLocalization.instance;

  @override
  void initState() {
    super.initState();
    _localization.init(
      mapLocales: [
        const MapLocale('en', {}, countryCode: 'US'),
      ],
      initLanguageCode: 'en',
    );
    _localization.onTranslatedLanguage = _onTranslatedLanguage;
  }

  void _onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contrust',
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,  
        ..._localization.localizationsDelegates,
      ],
      home: session != null ? DashboardScreen(contractorId: session.user.id) : LoginScreen(),
    );
  }
}
