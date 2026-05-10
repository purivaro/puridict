import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puridict/screens/home_screen.dart';
import 'package:puridict/services/dictionary_service.dart';
import 'package:puridict/theme/theme_manager.dart';
import 'package:puridict/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ตั้งค่าให้แอพแสดงผลในแนวตั้งเท่านั้น
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // เพิ่มส่วนนี้เพื่อทำให้ status bar เป็นสีเดียวกับ app bar
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // ทำให้โปร่งใสเพื่อให้สีพื้นหลังแสดงผ่าน
    statusBarIconBrightness: Brightness.light, // ไอคอนเป็นสีขาว (สำหรับ Android)
    statusBarBrightness: Brightness.dark, // ไอคอนเป็นสีขาว (สำหรับ iOS)
  ));
  
  // โหลดค่าการตั้งค่าธีม
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;
  
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  
  const MyApp({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('darkMode', _isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DictionaryService()),
        // เปลี่ยนจาก Provider.value เป็น Provider รูปแบบนี้
        Provider<ThemeManager>(
          create: (_) => ThemeManager(
            isDarkMode: _isDarkMode,
            toggleTheme: toggleTheme,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'พจนานุกรมบาลี-ไทย | PuriDict',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}