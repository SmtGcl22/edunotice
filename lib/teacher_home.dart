import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'welcome_page.dart';
import 'storage_service.dart';

enum TeacherAnnFilter { all, mine, targetAll, targetClass, targetUsers }

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  final List<String> _classes = ['10-A', '10-B', '11-A', '11-B', '12-A'];
  final Set<String> _selectedClasses = {};
  final Set<String> _selectedStudentUids = {};

  bool _sendToAll = false;
  bool _sending = false;

  // ✅ Çoklu ekler
  final List<File> _pickedImages = [];
  final List<File> _pickedFiles = [];
  final List<String> _pickedFileNames = [];

  // ✅ Son duyurular için arama + filtre
  final _annSearchCtrl = TextEditingController();
  TeacherAnnFilter _annFilter = TeacherAnnFilter.all;

  @override
  void initState() {
    super.initState();
    _annSearchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    _annSearchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _teacherInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {'uid': '', 'name': 'Öğretmen'};
    final doc =
    await FirebaseFirestore.instance.collection('ogretmenler').doc(uid).get();
    final data = doc.data() ?? {};
    return {'uid': uid, 'name': (data['isim'] ?? 'Öğretmen').toString()};
  }

  // ✅ Çoklu görsel seç
  Future<void> _pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;

      setState(() {
        for (final x in images) {
          _pickedImages.add(File(x.path));
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Görsel seçilemedi.")),
      );
    }
  }

  // ✅ Çoklu dosya seç
  Future<void> _pickFiles() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;

      setState(() {
        for (final f in res.files) {
          final p = f.path;
          if (p == null) continue;
          _pickedFiles.add(File(p));
          _pickedFileNames.add(f.name);
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dosya seçilemedi.")),
      );
    }
  }

  void _removeImageAt(int i) {
    setState(() {
      _pickedImages.removeAt(i);
    });
  }

  void _removeFileAt(int i) {
    setState(() {
      _pickedFiles.removeAt(i);
      _pickedFileNames.removeAt(i);
    });
  }

  Future<void> _openStudentSelector() async {
    if (_selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Önce şube seçmelisin.")));
      return;
    }

    final searchCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(80),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.75,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Seçili Şubeler: ${_selectedClasses.join(', ')}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: searchCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon:
                                const Icon(Icons.search, color: Colors.white),
                                hintText: "Öğrenci ara (isim)",
                                hintStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withAlpha(28),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => setModal(() {}),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  "Seçili: ${_selectedStudentUids.length}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _selectedStudentUids.clear());
                                    setModal(() {});
                                  },
                                  child: const Text("Seçimi Temizle"),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _sendToAll = true;
                                      _selectedStudentUids.clear();
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text("Tümünü Seç"),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('ogrenciler')
                                    .where('sinif',
                                    whereIn: _selectedClasses.toList())
                                    .snapshots(),
                                builder: (context, snap) {
                                  if (snap.hasError) {
                                    return Center(
                                      child: Text(
                                        "Hata: ${snap.error}",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }
                                  if (snap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white),
                                    );
                                  }
                                  if (!snap.hasData) {
                                    return const Center(
                                      child: Text("Veri yok.",
                                          style: TextStyle(color: Colors.white)),
                                    );
                                  }

                                  final docs = snap.data!.docs;
                                  if (docs.isEmpty) {
                                    return const Center(
                                      child: Text("Bu şubelerde öğrenci yoktur.",
                                          style: TextStyle(color: Colors.white)),
                                    );
                                  }

                                  final q = searchCtrl.text.trim().toLowerCase();
                                  final list = docs.where((d) {
                                    final data =
                                        d.data() as Map<String, dynamic>? ?? {};
                                    final isim = (data['isim'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    return q.isEmpty ? true : isim.contains(q);
                                  }).toList()
                                    ..sort((a, b) {
                                      final da =
                                          a.data() as Map<String, dynamic>? ?? {};
                                      final db =
                                          b.data() as Map<String, dynamic>? ?? {};
                                      return (da['isim'] ?? '')
                                          .toString()
                                          .compareTo((db['isim'] ?? '').toString());
                                    });

                                  if (list.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        "Aramaya uygun öğrenci bulunamadı.",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: list.length,
                                    itemBuilder: (_, i) {
                                      final d = list[i];
                                      final data =
                                          d.data() as Map<String, dynamic>? ?? {};
                                      final uid = d.id;
                                      final isim = (data['isim'] ?? '').toString();
                                      final sinif =
                                      (data['sinif'] ?? '').toString();
                                      final selectedNow =
                                      _selectedStudentUids.contains(uid);

                                      return Theme(
                                        data: Theme.of(ctx).copyWith(
                                          checkboxTheme: CheckboxThemeData(
                                            fillColor: WidgetStatePropertyAll(
                                              Colors.white.withAlpha(220),
                                            ),
                                            checkColor:
                                            const WidgetStatePropertyAll(
                                                Colors.deepPurple),
                                          ),
                                        ),
                                        child: CheckboxListTile(
                                          value: selectedNow,
                                          title: Text(isim,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                          subtitle: Text(sinif,
                                              style: const TextStyle(
                                                  color: Colors.white70)),
                                          onChanged: (v) {
                                            setState(() {
                                              _sendToAll = false;
                                              if (v == true) {
                                                _selectedStudentUids.add(uid);
                                              } else {
                                                _selectedStudentUids.remove(uid);
                                              }
                                            });
                                            setModal(() {});
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Kapat"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Tamam"),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _matchesAnnSearch(Map<String, dynamic> data) {
    final q = _annSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final t = (data['baslik'] ?? '').toString().toLowerCase();
    final m = (data['mesaj'] ?? '').toString().toLowerCase();
    return t.contains(q) || m.contains(q);
  }

  bool _matchesAnnFilter(Map<String, dynamic> data) {
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    final senderUid = (data['senderUid'] ?? '').toString();
    final type = (data['targetType'] ?? 'all').toString();

    switch (_annFilter) {
      case TeacherAnnFilter.all:
        return true;
      case TeacherAnnFilter.mine:
        return senderUid.isNotEmpty && senderUid == me;
      case TeacherAnnFilter.targetAll:
        return type == 'all';
      case TeacherAnnFilter.targetClass:
        return type == 'class';
      case TeacherAnnFilter.targetUsers:
        return type == 'users';
    }
  }

  String _annFilterLabel(TeacherAnnFilter f) {
    switch (f) {
      case TeacherAnnFilter.all:
        return "Tümü";
      case TeacherAnnFilter.mine:
        return "Sadece benim";
      case TeacherAnnFilter.targetAll:
        return "Hedef: ALL";
      case TeacherAnnFilter.targetClass:
        return "Hedef: Şube";
      case TeacherAnnFilter.targetUsers:
        return "Hedef: Öğrenci";
    }
  }

  Future<void> _sendAnnouncement() async {
    if (_sending) return;

    final title = _titleCtrl.text.trim();
    final msg = _msgCtrl.text.trim();

    // ✅ Başlık şart
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Başlık gerekli.")));
      return;
    }

    // ✅ Sadece başlık yasak: mesaj veya en az 1 ek olmalı
    final hasAnyAttachment = _pickedImages.isNotEmpty || _pickedFiles.isNotEmpty;
    if (msg.isEmpty && !hasAnyAttachment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text("Sadece başlık ile gönderilemez. Mesaj yaz veya ek ekle.")),
      );
      return;
    }

    // hedef tipi belirle
    String targetType;
    List<String> targets;

    if (_sendToAll) {
      targetType = 'all';
      targets = ['ALL'];
    } else if (_selectedStudentUids.isNotEmpty) {
      targetType = 'users';
      targets = _selectedStudentUids.toList();
    } else if (_selectedClasses.isNotEmpty) {
      targetType = 'class';
      targets = _selectedClasses.toList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hedef seçmelisin (şube veya tümü).")),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final tinfo = await _teacherInfo();
      final senderUid = tinfo['uid'] as String;
      final senderName = tinfo['name'] as String;

      final List<Map<String, dynamic>> attachments = [];

      // ✅ Görselleri yükle
      for (int i = 0; i < _pickedImages.length; i++) {
        final file = _pickedImages[i];
        final url = await StorageService.uploadFile(
          file: file,
          folder: 'duyuru_images',
          fileName: '${DateTime.now().millisecondsSinceEpoch}_img_$i.jpg',
        );
        attachments.add({
          'type': 'image',
          'url': url,
          'name': 'Görsel ${i + 1}',
        });
      }

      // ✅ Dosyaları yükle
      for (int i = 0; i < _pickedFiles.length; i++) {
        final file = _pickedFiles[i];
        final name = (i < _pickedFileNames.length) ? _pickedFileNames[i] : 'Dosya';
        final url = await StorageService.uploadFile(
          file: file,
          folder: 'duyuru_files',
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$name',
        );
        attachments.add({
          'type': 'file',
          'url': url,
          'name': name,
        });
      }

      await FirebaseFirestore.instance.collection('duyurular').add({
        'baslik': title,
        'mesaj': msg, // ✅ boş olabilir (ek varsa)
        'tarih': FieldValue.serverTimestamp(),
        'senderUid': senderUid,
        'senderName': senderName,
        'targetType': targetType,
        'targets': targets,
        'attachments': attachments,
      });

      _titleCtrl.clear();
      _msgCtrl.clear();
      setState(() {
        _pickedImages.clear();
        _pickedFiles.clear();
        _pickedFileNames.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Duyuru yayınlandı.")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    await FirebaseFirestore.instance.collection('duyurular').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradColors = isDark
        ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
        : [const Color(0xFF667EEA), const Color(0xFF764BA2)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Öğretmen Paneli"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const WelcomePage()),
              );
            },
          )
        ],
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
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _glassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Duyuru Gönder",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            "Tümünü Seç (ALL)",
                            style: TextStyle(color: Colors.white),
                          ),
                          value: _sendToAll,
                          onChanged: (v) {
                            setState(() {
                              _sendToAll = v;
                              if (v) {
                                _selectedClasses.clear();
                                _selectedStudentUids.clear();
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 8),
                        const Text("Şube Seç (çoklu)",
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _classes.map((c) {
                            final sel = _selectedClasses.contains(c);
                            return ChoiceChip(
                              label: Text(c),
                              selected: sel,
                              onSelected: _sendToAll
                                  ? null
                                  : (v) {
                                setState(() {
                                  if (v) {
                                    _selectedClasses.add(c);
                                  } else {
                                    _selectedClasses.remove(c);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.group, color: Colors.white),
                          title: const Text("Öğrencileri Seç",
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text(
                            _sendToAll
                                ? "Tüm öğrenciler seçili"
                                : (_selectedStudentUids.isEmpty
                                ? "Henüz öğrenci seçilmedi"
                                : "${_selectedStudentUids.length} öğrenci seçildi"),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: TextButton(
                            onPressed: _sendToAll ? null : _openStudentSelector,
                            child: const Text("Seç"),
                          ),
                        ),

                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _glassInput("Başlık (zorunlu)"),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _msgCtrl,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          decoration: _glassInput("Mesaj (isteğe bağlı)"),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(Icons.image),
                                label: Text(
                                  _pickedImages.isEmpty
                                      ? "Görsel Ekle"
                                      : "${_pickedImages.length} görsel seçildi",
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickFiles,
                                icon: const Icon(Icons.attach_file),
                                label: Text(
                                  _pickedFiles.isEmpty
                                      ? "Dosya Ekle"
                                      : "${_pickedFiles.length} dosya seçildi",
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_pickedImages.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text("Seçilen Görseller",
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_pickedImages.length, (i) {
                              return _chip(
                                icon: Icons.image,
                                text: "Görsel ${i + 1}",
                                onRemove: () => _removeImageAt(i),
                              );
                            }),
                          ),
                        ],

                        if (_pickedFiles.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text("Seçilen Dosyalar",
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_pickedFiles.length, (i) {
                              final name = (i < _pickedFileNames.length)
                                  ? _pickedFileNames[i]
                                  : "Dosya ${i + 1}";
                              return _chip(
                                icon: Icons.attach_file,
                                text: name,
                                onRemove: () => _removeFileAt(i),
                              );
                            }),
                          ),
                        ],

                        const SizedBox(height: 12),
                        _sending
                            ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white),
                        )
                            : SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _sendAnnouncement,
                            icon: const Icon(Icons.send),
                            label: const Text("Yayınla"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Son Duyurular",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Arama + filtre barı
                _glassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _annSearchCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Duyuru ara (başlık / mesaj)",
                                  hintStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon:
                                  const Icon(Icons.search, color: Colors.white),
                                  suffixIcon: _annSearchCtrl.text.isEmpty
                                      ? null
                                      : IconButton(
                                    tooltip: "Temizle",
                                    icon: const Icon(Icons.close,
                                        color: Colors.white70),
                                    onPressed: () => _annSearchCtrl.clear(),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(28),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            PopupMenuButton<TeacherAnnFilter>(
                              tooltip: "Filtre",
                              initialValue: _annFilter,
                              icon: const Icon(Icons.filter_list_rounded,
                                  color: Colors.white),
                              onSelected: (v) => setState(() => _annFilter = v),
                              itemBuilder: (ctx) => [
                                for (final f in TeacherAnnFilter.values)
                                  PopupMenuItem(
                                    value: f,
                                    child: Text(_annFilterLabel(f)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Filtre: ${_annFilterLabel(_annFilter)}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('duyurular')
                      .orderBy('tarih', descending: true)
                      .limit(200)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Text("Hata: ${snap.error}",
                          style: const TextStyle(color: Colors.white));
                    }
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final docs = snap.data!.docs;

                    // ✅ arama + filtre uygula
                    final filtered = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>? ?? {};
                      return _matchesAnnSearch(data) && _matchesAnnFilter(data);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(
                          child: Text(
                            "Sonuç yok.",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final d = filtered[i];
                        final data = d.data() as Map<String, dynamic>? ?? {};
                        final title = (data['baslik'] ?? 'Duyuru').toString();
                        final msg = (data['mesaj'] ?? '').toString();
                        final type = (data['targetType'] ?? 'all').toString();

                        final typeLabel = type == 'all'
                            ? "ALL"
                            : (type == 'class'
                            ? "Şube"
                            : (type == 'users' ? "Öğrenci" : "-"));

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _glassCard(
                            child: ListTile(
                              title: Text(title,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                msg.isEmpty ? "(Mesaj yok)" : msg,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              leading: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(28),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.white),
                                onPressed: () => _deleteAnnouncement(d.id),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UI helper'lar
  Widget _glassCard({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      ),
    ),
  );

  InputDecoration _glassInput(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.white.withAlpha(28),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  Widget _chip({
    required IconData icon,
    required String text,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
