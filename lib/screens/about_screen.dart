import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/chuncho.jpg',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.paper),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 82,
                  child: Text(
                    "Chuncho (Glaucidium nana)",
                    style: TextStyle(color: AppColors.sageLight, fontSize: 10),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.ink],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Zéfiro Strix",
                          style: TextStyle(color: AppColors.paper, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "Tetrapoda® SpA",
                          style: TextStyle(color: AppColors.sageLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Zéfiro Strix es un sistema de monitoreo bioacústico para detección de aves nocturnas mediante playback y grabación de respuesta, desarrollado por Tetrapoda® SpA para monitoreos de cumplimiento ambiental bajo el Sistema de Evaluación de Impacto Ambiental (SEA) de Chile.",
                    style: TextStyle(color: AppColors.paper, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF2C332E), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "USO RESPONSABLE",
                          style: TextStyle(color: AppColors.orange, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "El uso de playback puede alterar el comportamiento natural de la fauna silvestre. Esta técnica debe aplicarse solo por personal capacitado, siguiendo los protocolos de monitoreo autorizados, evitando la sobreexposición de un mismo individuo o punto de muestreo.",
                          style: TextStyle(color: AppColors.sageLight, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _contactRow(Icons.language, "tetrapoda.cl", () => _open("https://www.tetrapoda.cl")),
                  _contactRow(Icons.email_outlined, "contacto@tetrapoda.cl", () => _open("mailto:contacto@tetrapoda.cl")),
                  _contactRow(Icons.chat_bubble_outline, "+56 9 7788 5573", () => _open("https://wa.me/56977885573")),
                  _contactRow(Icons.camera_alt_outlined, "@tetrapodaspa", () => _open("https://www.instagram.com/tetrapodaspa")),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => _open("https://www.tetrapoda.cl/manual-zefiro-strix.pdf"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Manual de usuario", style: TextStyle(color: AppColors.paper, fontSize: 13)),
                          Icon(Icons.open_in_new, size: 16, color: AppColors.sage),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final info = snapshot.data;
                        final version = info == null ? '' : 'v${info.version} (${info.buildNumber})';
                        return Text(
                          "Zéfiro Strix $version · ${DateTime.now().year}",
                          style: TextStyle(color: AppColors.sage, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.sage),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: AppColors.paper, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}