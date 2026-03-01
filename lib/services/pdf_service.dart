import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

class PdfService {
  static Future<File> pdfOlustur({
    required String musteriAd,
    required String musteriYetkili,
    required String musteriTel,
    required String musteriEmail,
    required String musteriAdres,
    required String cihazModel,
    required bool isGarantili,
    required String servisNotu,
    required List<Map<String, String>> parcaListesi,
    required Uint8List? musteriImza,
    required Uint8List? teknisyenImza,
    required String teknisyenAd,
    required String altNot,
  }) async {
    final pdf = pw.Document();
    
    // Türkçe karakter desteği için font yükleme
    final fontData = await rootBundle.load("assets/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    // Ayarlardan logoyu çekme
    final prefs = await SharedPreferences.getInstance();
    final logoPath = prefs.getString('sirketLogoPath');
    pw.MemoryImage? logoImage;
    if (logoPath != null && File(logoPath).existsSync()) {
      logoImage = pw.MemoryImage(File(logoPath).readAsBytesSync());
    }

    // AYARLARDAN KURUMSAL RENGİ ÇEKME
    final int colorInt = prefs.getInt('themeColor') ?? 0xFF0D47A1;
    // Rengi PDF kütüphanesinin anlayacağı formata (RGB) dönüştürme
    final double r = ((colorInt >> 16) & 0xFF) / 255.0;
    final double g = ((colorInt >> 8) & 0xFF) / 255.0;
    final double b = (colorInt & 0xFF) / 255.0;
    
    // PdfColor'ı pw. olmadan kullanıyoruz (Hata çözümü)
    final anaRenk = PdfColor(r, g, b); // Koyu Ana Renk (Seçilen Kurumsal Renk)

    final simdi = DateTime.now();
    final String tamTarih = "${simdi.day}.${simdi.month}.${simdi.year} ${simdi.hour}:${simdi.minute.toString().padLeft(2, '0')}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- ÜST BÖLÜM: LOGO VE BAŞLIK ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (logoImage != null) pw.Image(logoImage, width: 80, height: 80, fit: pw.BoxFit.contain) else pw.SizedBox(width: 80),
                  pw.Column(children: [
                    pw.Text('TEKNİK SERVİS RAPORU', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: anaRenk)),
                    pw.Text('Kurumsal Servis ve Bakım Formu', style: const pw.TextStyle(fontSize: 9)),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text('Tarih / Saat:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(tamTarih, style: const pw.TextStyle(fontSize: 10)),
                  ]),
                ],
              ),
              pw.Divider(thickness: 1.5, color: anaRenk),
              pw.SizedBox(height: 10),

              // --- MÜŞTERİ BİLGİLERİ ---
              pw.Text('MÜŞTERİ BİLGİLERİ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: anaRenk)),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Expanded(child: pw.Text('Firma Adı: $musteriAd', style: const pw.TextStyle(fontSize: 10))),
                    pw.Expanded(child: pw.Text('Yetkili: $musteriYetkili', style: const pw.TextStyle(fontSize: 10))),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Expanded(child: pw.Text('Telefon: $musteriTel', style: const pw.TextStyle(fontSize: 10))),
                    pw.Expanded(child: pw.Text('E-posta: $musteriEmail', style: const pw.TextStyle(fontSize: 10))),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Text('Adres: ${musteriAdres.isEmpty ? "-" : musteriAdres}', style: const pw.TextStyle(fontSize: 10)),
                ]),
              ),
              pw.SizedBox(height: 15),

              // --- CİHAZ BİLGİLERİ ---
              pw.Text('CİHAZ BİLGİLERİ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: anaRenk)),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                child: pw.Row(children: [
                  pw.Expanded(child: pw.Text('Model: $cihazModel', style: const pw.TextStyle(fontSize: 10))),
                  pw.Expanded(child: pw.Text('Garanti Durumu: ${isGarantili ? "Garantili" : "Garanti Dışı"}', style: const pw.TextStyle(fontSize: 10))),
                ]),
              ),
              pw.SizedBox(height: 15),

              // --- SERVİS NOTLARI ---
              pw.Text('SERVİS NOTLARI VE ARIZA DETAYI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: anaRenk)),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), color: PdfColors.grey50),
                child: pw.Text(servisNotu.isEmpty ? "Not belirtilmedi." : servisNotu, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.SizedBox(height: 15),

              // --- PARÇA VE İŞLEM TABLOSU ---
              pw.Text('YAPILAN İŞLEMLER / KULLANILAN PARÇALAR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: anaRenk)),
              pw.SizedBox(height: 5),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: anaRenk), // Dinamik Renk
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['İşlem / Parça Tanımı', 'Birim Fiyat (TL)'],
                data: parcaListesi.map((e) => [e['adi'], '${e['ucret']} TL']).toList(),
              ),
              pw.SizedBox(height: 10),

              // --- VURGULANMIŞ GENEL TOPLAM ALANI (Renk Hatası Çözüldü) ---
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white, // Kutu içi beyaz (Dolu renk basmasını önler)
                    border: pw.Border.all(color: anaRenk, width: 2), // Çerçeve rengi kurumsal renk
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))
                  ),
                  child: pw.Text(
                    'GENEL TOPLAM: ${parcaListesi.fold(0.0, (sum, item) => sum + (double.tryParse(item['ucret']!) ?? 0)).toStringAsFixed(2)} TL',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: anaRenk),
                  ),
                ),
              ),

              pw.Spacer(),

              // --- İMZALAR ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                        pw.Text('MÜŞTERİ / YETKİLİ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text(musteriYetkili, style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 5),
                        if (musteriImza != null) pw.Container(height: 60, width: 120, child: pw.Image(pw.MemoryImage(musteriImza), fit: pw.BoxFit.contain)) else pw.SizedBox(height: 60),
                        pw.Container(width: 100, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.grey)))),
                    ]),
                  ),
                  pw.SizedBox(width: 40),
                  pw.Expanded(
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                        pw.Text('TEKNİSYEN ONAYI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text(teknisyenAd, style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 5),
                        if (teknisyenImza != null) pw.Container(height: 60, width: 120, child: pw.Image(pw.MemoryImage(teknisyenImza), fit: pw.BoxFit.contain)) else pw.SizedBox(height: 60),
                        pw.Container(width: 100, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.grey)))),
                    ]),
                  ),
                ],
              ),
              
              // --- FATURA DEĞİLDİR (ALT NOT) BÖLÜMÜ ---
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  altNot,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/servis_formu.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}