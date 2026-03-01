import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ekranı yan çevirmek için gerekli paket
import 'package:signature/signature.dart';

class SignatureScreen extends StatefulWidget {
  final String baslik;
  final SignatureController controller;

  const SignatureScreen({super.key, required this.baslik, required this.controller});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında ekranı YATAY (Landscape) yap ve tam ekran (Immersive) moduna geç
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Sayfa kapandığında ekranı tekrar DİKEY (Portrait) yap ve üst çubuğu geri getir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.baslik} İmzası Lütfen'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => widget.controller.clear(),
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            label: const Text('Temizle', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // İmzayı kaydet ve geri dön
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Kaydet ve Çık', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      // Bütün ekranı kaplayan imza alanı
      body: Signature(
        controller: widget.controller,
        backgroundColor: Colors.white,
      ),
    );
  }
}