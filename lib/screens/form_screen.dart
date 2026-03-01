import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pdf_service.dart';
import 'settings_screen.dart';
import 'signature_screen.dart';
import 'pdf_preview_screen.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final TextEditingController _tarihController = TextEditingController();
  final TextEditingController _musteriAdController = TextEditingController();
  final TextEditingController _musteriYetkiliController = TextEditingController();
  final TextEditingController _musteriEmailController = TextEditingController();
  final TextEditingController _musteriTelController = TextEditingController();
  final TextEditingController _musteriAdresController = TextEditingController();
  final TextEditingController _cihazModelController = TextEditingController();
  final TextEditingController _servisNotlariController = TextEditingController();
  
  bool _isGarantili = false;
  List<Map<String, String>> _parcaListesi = [];
  final TextEditingController _parcaAdiController = TextEditingController();
  final TextEditingController _parcaUcretController = TextEditingController();

  final SignatureController _musteriImzaController = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.transparent);
  List<Map<String, String>> _kayitliMusteriler = [];

  @override
  void initState() {
    super.initState();
    _tarihController.text = "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";
    _musterileriYukle();
  }

  @override
  void dispose() {
    _musteriAdController.dispose();
    _musteriYetkiliController.dispose();
    _musteriEmailController.dispose();
    _musteriTelController.dispose();
    _musteriAdresController.dispose();
    _cihazModelController.dispose();
    _servisNotlariController.dispose();
    _parcaAdiController.dispose();
    _parcaUcretController.dispose();
    _musteriImzaController.dispose();
    super.dispose();
  }

  Future<void> _musterileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final String? musterilerJson = prefs.getString('musteriListesi');
    if (musterilerJson != null) {
      final List<dynamic> cozulmusVeri = jsonDecode(musterilerJson);
      setState(() { _kayitliMusteriler = cozulmusVeri.map((e) => Map<String, String>.from(e)).toList(); });
    }
  }

  Future<void> _musteriyiKaydet() async {
    final ad = _musteriAdController.text.trim();
    if (ad.isEmpty) return;

    // Müşterinin daha önce kayıtlı olup olmadığını kontrol ediyoruz
    int index = _kayitliMusteriler.indexWhere((m) => m['ad'] == ad);

    if (index != -1) {
      // EĞER KAYITLIYSA: Mevcut bilgileri yeni girilen adres, tel ve e-posta ile günceller
      _kayitliMusteriler[index] = {
        'ad': ad,
        'email': _musteriEmailController.text.trim(),
        'tel': _musteriTelController.text.trim(),
        'adres': _musteriAdresController.text.trim(), // Adres güncelleniyor
      };
    } else {
      // EĞER YENİ MÜŞTERİYSE: Listeye sıfırdan ekler
      _kayitliMusteriler.add({
        'ad': ad,
        'email': _musteriEmailController.text.trim(),
        'tel': _musteriTelController.text.trim(),
        'adres': _musteriAdresController.text.trim(), // Adres ekleniyor
      });
    }

    // Güncel listeyi telefonun hafızasına kaydeder
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('musteriListesi', jsonEncode(_kayitliMusteriler));
  }

  double _toplamHesapla() {
    double toplam = 0;
    for (var parca in _parcaListesi) {
      toplam += double.tryParse(parca['ucret'] ?? '0') ?? 0;
    }
    return toplam;
  }

  @override
  Widget build(BuildContext context) {
    // YENİ: Temadan güncel rengi alıyoruz
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TEKNİK SERVİS FORMU'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _customTextField(_tarihController, 'Form Tarihi', Icons.calendar_today, readOnly: true),
            const SizedBox(height: 20),
            
            _sectionTitle('1. Müşteri / Firma Bilgileri', themeColor),
            const SizedBox(height: 10),
            Autocomplete<Map<String, String>>(
              optionsBuilder: (TextEditingValue val) {
                if (val.text.isEmpty) return const Iterable<Map<String, String>>.empty();
                return _kayitliMusteriler.where((m) => m['ad']!.toLowerCase().contains(val.text.toLowerCase()));
              },
              displayStringForOption: (m) => m['ad']!,
              onSelected: (m) {
                _musteriAdController.text = m['ad']!;
                _musteriEmailController.text = m['email'] ?? '';
                _musteriTelController.text = m['tel'] ?? '';
                _musteriAdresController.text = m['adres'] ?? '';
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                controller.addListener(() { _musteriAdController.text = controller.text; });
                return TextField(
                  controller: controller, focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Firma Adı', prefixIcon: Icon(Icons.business), border: OutlineInputBorder()),
                );
              },
            ),
            const SizedBox(height: 10),
            _customTextField(_musteriTelController, 'İletişim Numarası', Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _customTextField(_musteriEmailController, 'E-Posta Adresi', Icons.email),
            const SizedBox(height: 10),
            _customTextField(_musteriAdresController, 'Açık Adres', Icons.location_on, maxLines: 2),
            
            const SizedBox(height: 25),
            _sectionTitle('2. Cihaz ve Garanti', themeColor),
            const SizedBox(height: 10),
            _customTextField(_cihazModelController, 'Cihaz Marka / Model', Icons.devices),
            SwitchListTile(
              title: const Text('Garanti Kapsamında mı?'),
              activeColor: themeColor,
              value: _isGarantili,
              onChanged: (val) => setState(() => _isGarantili = val),
            ),
            
            const SizedBox(height: 25),
            _sectionTitle('3. Servis Notları', themeColor),
            const SizedBox(height: 10),
            _customTextField(_servisNotlariController, 'Arıza Detayı ve Yapılan İşlemler', Icons.description, maxLines: 4),
            
            const SizedBox(height: 25),
            _sectionTitle('4. Parça ve İşlem Ücretleri', themeColor),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _customTextField(_parcaAdiController, 'İşlem', Icons.settings)),
                const SizedBox(width: 8),
                SizedBox(width: 100, child: _customTextField(_parcaUcretController, 'Tutar', Icons.payments, keyboardType: TextInputType.number)),
                IconButton(
                  icon: Icon(Icons.add_circle, color: themeColor, size: 35),
                  onPressed: () {
                    if (_parcaAdiController.text.isNotEmpty) {
                      setState(() {
                        _parcaListesi.add({'adi': _parcaAdiController.text, 'ucret': _parcaUcretController.text});
                        _parcaAdiController.clear(); _parcaUcretController.clear();
                      });
                    }
                  },
                )
              ],
            ),
            if (_parcaListesi.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    ..._parcaListesi.asMap().entries.map((e) => ListTile(
                      title: Text(e.value['adi']!),
                      trailing: Text('${e.value['ucret']} TL'),
                      leading: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _parcaListesi.removeAt(e.key))),
                    )),
                    Container(
                      color: themeColor.withOpacity(0.1), // Dinamik açık arkaplan
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GENEL TOPLAM', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${_toplamHesapla().toStringAsFixed(2)} TL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: themeColor)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
            _sectionTitle('5. Onay ve İmzalar', themeColor),
            const SizedBox(height: 10),
            _customTextField(_musteriYetkiliController, 'İmzayı Atan Müşteri Yetkilisi (Ad Soyad)', Icons.person_pin),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: _signatureButton('Müşteriden İmza Al', _musteriImzaController, themeColor),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('RAPORU ÖNİZLE VE TAMAMLA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _formuTamamla,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _formuTamamla() async {
    if (_musteriAdController.text.isEmpty || _musteriYetkiliController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firma ve Yetkili adı zorunludur!')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final tAd = prefs.getString('teknisyenAd') ?? 'Teknisyen';
    final altNot = prefs.getString('altNot') ?? 'Bu belge bilgilendirme amaçlıdır.';
    final imzaBase64 = prefs.getString('teknisyenImzaBase64');
    
    Uint8List? tImzaBytes;
    if (imzaBase64 != null) {
      tImzaBytes = base64Decode(imzaBase64);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen ayarlardan Teknisyen imzanızı kaydedin.')));
      return;
    }

    await _musteriyiKaydet();
    final mImza = await _musteriImzaController.toPngBytes();

    final pdfFile = await PdfService.pdfOlustur(
      musteriAd: _musteriAdController.text,
      musteriYetkili: _musteriYetkiliController.text,
      musteriTel: _musteriTelController.text,
      musteriEmail: _musteriEmailController.text,
      musteriAdres: _musteriAdresController.text,
      cihazModel: _cihazModelController.text,
      isGarantili: _isGarantili,
      servisNotu: _servisNotlariController.text,
      parcaListesi: _parcaListesi,
      musteriImza: mImza,
      teknisyenImza: tImzaBytes,
      teknisyenAd: tAd,
      altNot: altNot,
    );

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PdfPreviewScreen(pdfFile: pdfFile, musteriEmail: _musteriEmailController.text)));
    }
  }

  Widget _sectionTitle(String title, Color color) => Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: color));

  Widget _customTextField(TextEditingController ctrl, String label, IconData icon, {bool readOnly = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl, readOnly: readOnly, maxLines: maxLines, keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _signatureButton(String label, SignatureController controller, Color themeColor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        backgroundColor: controller.isNotEmpty ? Colors.green : Colors.grey.shade300,
        foregroundColor: controller.isNotEmpty ? Colors.white : Colors.black87,
        elevation: 0
      ),
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => SignatureScreen(baslik: label, controller: controller)));
        setState(() {});
      },
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}