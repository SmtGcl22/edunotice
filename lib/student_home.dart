import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_page.dart';
import 'announcement_detail.dart';

enum AnnouncementFilter { all, unread, read }

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  String? isim, sinif;
  Set<String> okunan = {}; // okundu duyuru id’leri

  // ✅ yeni
  final _searchCtrl = TextEditingController();
  AnnouncementFilter _filter = AnnouncementFilter.all;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {}); // aramayı canlı yenile
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('ogrenciler')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (!mounted) return;

    if (doc.exists && data != null) {
      final list = (data['okunanDuyurular'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [];
      setState(() {
        isim = (data['isim'] ?? '').toString();
        sinif = (data['sinif'] ?? '').toString();
        okunan = list.toSet();
      });
    }
  }

  bool _isForMe(DocumentSnapshot d) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final data = d.data() as Map<String, dynamic>?;
    if (data == null) return false;

    final type = (data['targetType'] ?? 'all').toString();
    final targets =
        (data['targets'] as List?)?.map((e) => e.toString()).toList() ?? [];

    if (type == 'all') return true;
    if (type == 'class') return sinif != null && targets.contains(sinif);
    if (type == 'users') return targets.contains(user.uid);
    return false;
  }

  Future<void> _markRead(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (okunan.contains(id)) return;

    setState(() => okunan.add(id));

    await FirebaseFirestore.instance.collection('ogrenciler').doc(user.uid).update({
      'okunanDuyurular': FieldValue.arrayUnion([id]),
    });
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    final baslik = (data['baslik'] ?? '').toString().toLowerCase();
    final mesaj = (data['mesaj'] ?? '').toString().toLowerCase();
    return baslik.contains(q) || mesaj.contains(q);
  }

  bool _matchesFilter(String id) {
    final unread = !okunan.contains(id);
    switch (_filter) {
      case AnnouncementFilter.all:
        return true;
      case AnnouncementFilter.unread:
        return unread;
      case AnnouncementFilter.read:
        return !unread;
    }
  }

  String _filterLabel(AnnouncementFilter f) {
    switch (f) {
      case AnnouncementFilter.all:
        return "Tümü";
      case AnnouncementFilter.unread:
        return "Okunmamış";
      case AnnouncementFilter.read:
        return "Okunmuş";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradColors = isDark
        ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
        : [const Color(0xFF667EEA), const Color(0xFF764BA2)];

    if (isim == null || sinif == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Duyurular"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // ✅ filtre menüsü
          PopupMenuButton<AnnouncementFilter>(
            tooltip: "Filtre",
            initialValue: _filter,
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (ctx) => [
              for (final f in AnnouncementFilter.values)
                PopupMenuItem(
                  value: f,
                  child: Text(_filterLabel(f)),
                )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const WelcomePage()),
              );
            },
          ),
          const SizedBox(width: 6),
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
          child: Column(
            children: [
              // Header + arama
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(38),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Merhaba, $isim",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Sınıf: $sinif",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 14),

                          // ✅ arama kutusu
                          TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Duyurularda ara (başlık / mesaj)",
                              hintStyle: const TextStyle(color: Colors.white70),
                              prefixIcon:
                              const Icon(Icons.search, color: Colors.white),
                              suffixIcon: _searchCtrl.text.isEmpty
                                  ? null
                                  : IconButton(
                                tooltip: "Temizle",
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => _searchCtrl.clear(),
                              ),
                              filled: true,
                              fillColor: Colors.white.withAlpha(38),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ✅ filtre etiketi
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(38),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  "Filtre: ${_filterLabel(_filter)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (_searchCtrl.text.trim().isNotEmpty)
                                Text(
                                  "Arama: \"${_searchCtrl.text.trim()}\"",
                                  style: const TextStyle(color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('duyurular')
                      .orderBy('tarih', descending: true)
                      .limit(200)
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
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    // 1) benim hedefim
                    final all = snap.data!.docs.where(_isForMe).toList();

                    // 2) okunmamışlar üstte
                    all.sort((a, b) {
                      final aUnread = !okunan.contains(a.id);
                      final bUnread = !okunan.contains(b.id);
                      if (aUnread != bUnread) return aUnread ? -1 : 1;
                      return 0;
                    });

                    // 3) filtre + arama
                    final filtered = all.where((d) {
                      final data = d.data() as Map<String, dynamic>? ?? {};
                      return _matchesFilter(d.id) && _matchesSearch(data);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          "Sonuç yok.",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final d = filtered[i];
                        final data = d.data() as Map<String, dynamic>? ?? {};
                        final baslik = (data['baslik'] ?? 'Duyuru').toString();
                        final mesaj = (data['mesaj'] ?? '').toString();
                        final unread = !okunan.contains(d.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 250),
                                opacity: unread ? 1.0 : 0.45,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(38),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      baslik,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: unread
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      mesaj,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: unread
                                            ? Colors.white70
                                            : Colors.white38,
                                      ),
                                    ),
                                    trailing: unread
                                        ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(64),
                                        borderRadius:
                                        BorderRadius.circular(999),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: const Text(
                                        "Yeni",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                        : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.check_circle,
                                            size: 18,
                                            color: Colors.white60),
                                        SizedBox(width: 4),
                                        Text(
                                          "Okundu",
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      await _markRead(d.id);
                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AnnouncementDetailPage(
                                            data: data,
                                            docId: d.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
