import 'dart:async';  // เพิ่มส่วนนี้
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puridict/screens/home_screen.dart';
import 'package:puridict/services/dictionary_service.dart';
import 'package:puridict/theme/theme_manager.dart';
import 'package:puridict/theme/app_theme.dart';

void main() {
  // ครอบด้วย runZonedGuarded เพื่อจับข้อผิดพลาดทั้งหมด
  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      // ตั้งค่าให้แอพแสดงผลในแนวตั้งเท่านั้น
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // เพิ่มส่วนนี้เพื่อทำให้ status bar เป็นสีเดียวกับ app bar
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // ทำให้โปร่งใสเพื่อให้สีพื้นหลังแสดงผ่าน
        statusBarIconBrightness: Brightness.light, // ไอคอนเป็นสีขาว (สำหรับ Android)
        statusBarBrightness: Brightness.dark, // ไอคอนเป็นสีขาว (สำหรับ iOS)
      ));
      
      // โหลดค่าการตั้งค่าธีม
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('darkMode') ?? false;
      
      runApp(MyApp(isDarkMode: isDarkMode));
    } catch (e, stack) {
      // จับข้อผิดพลาดระหว่างการเริ่มต้นแอป
      print('Error during initialization: $e');
      print('Stack trace: $stack');
      // แสดงแอพแบบง่ายในกรณีที่เกิดข้อผิดพลาด
      runApp(const FallbackApp());
    }
  }, (error, stack) {
    // จับข้อผิดพลาดที่ไม่ได้จัดการในแอพ
    print('Unhandled error: $error');
    print('Stack trace: $stack');
  });
}

// แอพสำรองอย่างง่ายสำหรับกรณีเกิดข้อผิดพลาด
class FallbackApp extends StatelessWidget {
  const FallbackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'พจนานุกรมบาลี-ไทย | PuriDict',
      theme: ThemeData(
        primaryColor: const Color(0xFF4155b5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4155b5)),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('พจนานุกรมบาลี-ไทย'),
          backgroundColor: const Color(0xFF4155b5),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 24),
                Text(
                  'เกิดข้อผิดพลาดในการเริ่มต้นแอพ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'กรุณาลองปิดและเปิดแอพใหม่อีกครั้ง',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  
  const MyApp({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;
  // เพิ่มตัวแปรสำหรับควบคุมการ initialize service
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    // เริ่มต้นบริการต่างๆ ในแบบที่ปลอดภัยกว่า
    _initFuture = _initializeServices();
  }

  // แยกการเริ่มต้นบริการออกมาเพื่อการจัดการข้อผิดพลาดที่ดีขึ้น
  Future<void> _initializeServices() async {
    try {
      // คุณสามารถเพิ่มการเริ่มต้นบริการอื่นๆ ที่นี่
      // เช่น โหลดข้อมูลเริ่มต้น, ตรวจสอบการเชื่อมต่อ, ฯลฯ
      return Future.value();
    } catch (e) {
      print('Error initializing services: $e');
      return Future.value(); // คืนค่า Future ที่สำเร็จเพื่อไม่ให้แอพเด้ง
    }
  }

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('darkMode', _isDarkMode);
    }).catchError((error) {
      print('Error saving theme preference: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // แสดงหน้าโหลดถ้ากำลังเริ่มต้นบริการ
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: 'พจนานุกรมบาลี-ไทย | PuriDict',
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            debugShowCheckedModeBanner: false,
          );
        }
        
        // หากมีข้อผิดพลาดระหว่างการเริ่มต้น
        if (snapshot.hasError) {
          return MaterialApp(
            title: 'พจนานุกรมบาลี-ไทย | PuriDict',
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
        }
        
        // แสดงแอพปกติถ้าเริ่มต้นสำเร็จ
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => DictionaryService(),
            ),
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
      },
    );
  }
}