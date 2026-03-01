import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signature/signature.dart';
import '../main.dart'; // Renk değişimi için eklendi
import 'signature_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _mailController = TextEditingController();
  final _sifreController = TextEditingController();
  final _teknisyenAdController = TextEditingController();
  final _merkezMailController = TextEditingController();
  final _ccMailController = TextEditingController();
  final _altNotController = TextEditingController();

  final SignatureController _teknisyenImzaController = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.transparent);
  Uint8List? _kayitliImza;
  String? _logoPath;
  
  // YENİ: Renk Seçimi
  int _seciliRenk = 0xFF0D47A1; // Varsayılan Lacivert
  final List<int> _renkPaleti = [
    0xFF0D47A1, // Lacivert
    0xFFB71C1C, // Koyu Kırmızı
    0xFF1B5E20, // Koyu Yeşil
    0xFFE65100, // Koyu Turuncu
    0xFF4A148C, // Koyu Mor
    0xFF212121, // Siyah/Antrasit
  ];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    
    setState(() {
      _mailController.text = prefs.getString('gondericiMail') ?? '';
      _teknisyenAdController.text = prefs.getString('teknisyenAd') ?? '';
      _merkezMailController.text = prefs.getString('merkezMail') ?? '';
      _ccMailController.text = prefs.getString('ccMails') ?? '';
      _altNotController.text = prefs.getString('altNot') ?? 'Bu belge bir fatura yerine geçmez, sadece bilgilendirme amaçlı servis formudur.';
      _logoPath = prefs.getString('sirketLogoPath');
      _seciliRenk = prefs.getInt('themeColor') ?? 0xFF0D47A1; // Kayıtlı rengi çek
      
      final imzaBase64 = prefs.getString('teknisyenImzaBase64');
      if (imzaBase64 != null) _kayitliImza = base64Decode(imzaBase64);
    });
    _sifreController.text = await secureStorage.read(key: 'uygulamaSifresi') ?? '';
  }

  Future<void> _logoSec() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _logoPath = pickedFile.path);
  }

  Future<void> _kaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gondericiMail', _mailController.text.trim());
    await prefs.setString('teknisyenAd', _teknisyenAdController.text.trim());
    await prefs.setString('merkezMail', _merkezMailController.text.trim());
    await prefs.setString('ccMails', _ccMailController.text.trim());
    await prefs.setString('altNot', _altNotController.text.trim());
    await prefs.setInt('themeColor', _seciliRenk); // Rengi kaydet
    
    if (_logoPath != null) await prefs.setString('sirketLogoPath', _logoPath!);

    if (_teknisyenImzaController.isNotEmpty) {
      final imzaBytes = await _teknisyenImzaController.toPngBytes();
      if (imzaBytes != null) await prefs.setString('teknisyenImzaBase64', base64Encode(imzaBytes));
    }

    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: 'uygulamaSifresi', value: _sifreController.text.trim());

    // UYGULAMANIN RENGİNİ ANINDA DEĞİŞTİRİR
    appThemeColor.value = Color(_seciliRenk);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayarlar Kaydedildi!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // YENİ: LOGO VE RENK SEÇİMİ BÖLÜMÜ
            _sectionTitle('Kurumsal Kimlik (Logo ve Renk)'),
            Row(
              children: [
                GestureDetector(
                  onTap: _logoSec,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                    child: _logoPath != null && File(_logoPath!).existsSync() 
                      ? Image.file(File(_logoPath!), fit: BoxFit.contain) 
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 30), Text('Logo Seç', style: TextStyle(fontSize: 12))]),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Uygulama & PDF Rengi', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: _renkPaleti.map((renk) => GestureDetector(
                          onTap: () => setState(() => _seciliRenk = renk),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(renk),
                            child: _seciliRenk == renk ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 40),

            _sectionTitle('Teknisyen Bilgileri & İmza'),
            _inputField(_teknisyenAdController, 'Adınız Soyadınız', Icons.person),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(5)),
              child: Column(
                children: [
                  const Text('Varsayılan Teknisyen İmzası', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_teknisyenImzaController.isNotEmpty)
                    Container(height: 80, color: Colors.grey.shade100, child: Signature(controller: _teknisyenImzaController, backgroundColor: Colors.transparent))
                  else if (_kayitliImza != null)
                    Image.memory(_kayitliImza!, height: 80)
                  else
                    const Text('Kayıtlı imza yok.', style: TextStyle(color: Colors.red)),
                  ElevatedButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => SignatureScreen(baslik: 'İmza', controller: _teknisyenImzaController))); setState(() {}); }, icon: const Icon(Icons.draw), label: const Text('İmza At / Değiştir')),
                ],
              ),
            ),
            const SizedBox(height: 15),
            _inputField(_mailController, 'Gönderici Gmail Adresiniz', Icons.email),
            _inputField(_sifreController, 'Gmail Uygulama Şifresi', Icons.lock, obscure: true),
            const Divider(height: 40),
            
            _sectionTitle('Merkez & CC Ayarları'),
            _inputField(_merkezMailController, 'Merkez Arşiv E-postası', Icons.business),
            _inputField(_ccMailController, 'CC E-postalar (Virgül ile ayırın)', Icons.copy),
            const Divider(height: 40),

            _sectionTitle('PDF Alt Bilgi (Yasal Uyarı)'),
            _inputField(_altNotController, 'Formun en altında yazacak uyarı metni', Icons.gavel, maxLines: 3),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              onPressed: _kaydet, 
              child: const Text('TÜMÜNÜ KAYDET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
  Widget _inputField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: ctrl, obscureText: obscure, maxLines: maxLines, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder())));
}