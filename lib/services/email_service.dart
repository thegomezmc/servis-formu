import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> mailGonder({
    required File pdfDosyasi,
    required String gondericiMail,
    required String uygulamaSifresi,
    required List<String> alicilar,
    required List<String> ccAlicilar, // YENİ: Bilgi (CC) listesi
  }) async {
    final smtpServer = gmail(gondericiMail, uygulamaSifresi);

    final message = Message()
      ..from = Address(gondericiMail, 'Teknik Servis Sistemi')
      ..recipients.addAll(alicilar.where((e) => e.isNotEmpty)) // Ana alıcılar
      ..ccRecipients.addAll(ccAlicilar.where((e) => e.isNotEmpty)) // CC alıcılar
      ..subject = 'Teknik Servis Raporu - ${DateTime.now().toString().split('.')[0]}'
      ..text = 'Merhaba,\n\nYapılan işleme ait servis formu ektedir.\n\nİyi çalışmalar.'
      ..attachments.add(FileAttachment(pdfDosyasi));

    try {
      await send(message, smtpServer);
    } on MailerException catch (e) {
      throw Exception('Mail gönderim hatası: $e');
    }
  }
}