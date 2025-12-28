import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const AnnouncementDetailPage({
    super.key,
    required this.data,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradColors = isDark
        ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
        : [const Color(0xFF667EEA), const Color(0xFF764BA2)];

    final baslik = (data['baslik'] ?? 'Duyuru').toString();
    final mesaj = (data['mesaj'] ?? '').toString();
    final sender = (data['senderName'] ?? 'Öğretmen').toString();
    final hedefText = _targetText(data);

    final attachments =
        (data['attachments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Duyuru Detayı"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withAlpha(115) // ~0.45
                        : Colors.white.withAlpha(64), // ~0.25
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          baslik,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(38),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            hedefText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),
                        Text(
                          mesaj,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withAlpha(60)),

                        Text(
                          "Gönderen: $sender",
                          style: const TextStyle(color: Colors.white60),
                        ),

                        const SizedBox(height: 12),

                        if (attachments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            "Ekler",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...attachments.map((a) {
                            final type = (a['type'] ?? 'file').toString();
                            final name = (a['name'] ?? 'dosya').toString();
                            final url = (a['url'] ?? '').toString();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter:
                                  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(38),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      leading: Icon(
                                        type == 'image'
                                            ? Icons.image
                                            : Icons.attach_file,
                                        color: Colors.white,
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        url.isEmpty ? "-" : "Açmak için tıkla",
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                      onTap: () async {
                                        if (url.isEmpty) return;
                                        final uri = Uri.parse(url);
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode
                                              .externalApplication,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _targetText(Map<String, dynamic> d) {
    final type = (d['targetType'] ?? 'all').toString();
    final targets =
        (d['targets'] as List?)?.map((e) => e.toString()).toList() ?? [];

    if (type == 'all') return "Hedef: Tüm öğrenciler";
    if (type == 'class') return "Hedef şube: ${targets.join(', ')}";
    if (type == 'users') return "Hedef öğrenci(ler): ${targets.length} kişi";
    return "Hedef: -";
  }
}
