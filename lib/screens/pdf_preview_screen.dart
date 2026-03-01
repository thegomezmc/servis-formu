import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../services/email_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PdfPreviewScreen extends StatelessWidget {
  final File pdfFile;
  final String musteriEmail;

  const PdfPreviewScreen({super.key, required this.pdfFile, required this.musteriEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapor Önizleme', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor, // Kurumsal renge uyarlandı
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) => pdfFile.readAsBytesSync(),
        allowPrinting: true,
        allowSharing: false, // Varsayılan paylaşımı kapattık, kendi butonlarımızı ekledik
        pdfFileName: "servis_raporu.pdf",
        actions: [
          // MAİL GÖNDER BUTONU
          PdfPreviewAction(
            icon: const Icon(Icons.email, color: Colors.white),
            onPressed: (context, build, format) => _otomatikMailDagitimi(context),
          ),
          // PAYLAŞ (WHATSAPP VB.) BUTONU
          PdfPreviewAction(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: (context, build, format) async {
              await Share.shareXFiles([XFile(pdfFile.path)], text: 'Teknik servis raporunuz ektedir.');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _otomatikMailDagitimi(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    
    final gondericiMail = prefs.getString('gondericiMail') ?? '';
    final uygulamaSifresi = await secureStorage.read(key: 'uygulamaSifresi') ?? '';
    final merkezMail = prefs.getString('merkezMail') ?? '';
    final ccMailsRaw = prefs.getString('ccMails') ?? '';
    
    List<String> ccListesi = ccMailsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    List<String> anaAlicilar = [merkezMail];
    if (musteriEmail.isNotEmpty) anaAlicilar.add(musteriEmail);

    // Ayarlar boşsa uyar ve durdur
    if (gondericiMail.isEmpty || uygulamaSifresi.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen ayarlardan e-posta ve uygulama şifrenizi girin!')));
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor tüm birimlere dağıtılıyor, lütfen bekleyin...')));

    try {
      // Arka planda mail gönderme işlemi
      await EmailService.mailGonder(
        pdfDosyasi: pdfFile,
        gondericiMail: gondericiMail,
        uygulamaSifresi: uygulamaSifresi,
        alicilar: anaAlicilar,
        ccAlicilar: ccListesi,
      );
      
      // KRİTİK KONTROL: Eğer mail giderken kullanıcı bu ekrandan çıktıysa hata verme, sessizce bitir.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor başarıyla gönderildi!')));

    } catch (e) {
      // KRİTİK KONTROL: Hata durumunda da ekran kapalıysa çökmesini engeller
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }
}