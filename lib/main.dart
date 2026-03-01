import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart'; // Açılış ekranımız

// Uygulama rengini anlık değiştirmemizi sağlayan global değişken
final ValueNotifier<Color> appThemeColor = ValueNotifier<Color>(const Color(0xFF0D47A1)); // Varsayılan: Lacivert

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Kaydedilmiş renk varsa uygulamayı o renkle başlat
  final prefs = await SharedPreferences.getInstance();
  final savedColor = prefs.getInt('themeColor');
  if (savedColor != null) {
    appThemeColor.value = Color(savedColor);
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (context, color, child) {
        return MaterialApp(
          title: 'Teknik Servis',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: color,
            appBarTheme: AppBarTheme(backgroundColor: color, foregroundColor: Colors.white),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: color),
          ),
          home: const SplashScreen(), // Uygulama artık direkt forma değil, açılış ekranına gidiyor
        );
      },
    );
  }
}