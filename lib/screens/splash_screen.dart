import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'form_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _logoYukleVeGecisYap();
  }

  Future<void> _logoYukleVeGecisYap() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _logoPath = prefs.getString('sirketLogoPath');
    });

    // Ekranda logonun 2 saniye görünmesini sağlar
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FormScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ayarlarda logo varsa onu, yoksa standart bir ikon gösterir
            if (_logoPath != null && File(_logoPath!).existsSync())
              Image.file(File(_logoPath!), height: 160, fit: BoxFit.contain)
            else
              Icon(Icons.engineering, size: 120, color: themeColor),
              
            const SizedBox(height: 30),
            Text('TEKNİK SERVİS SİSTEMİ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor, letterSpacing: 1.5)),
            const SizedBox(height: 40),
            CircularProgressIndicator(color: themeColor), // Yükleniyor ikonu
          ],
        ),
      ),
    );
  }
}