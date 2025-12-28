const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

exports.notifyOnNewAnnouncement = functions.firestore
  .document("duyurular/{duyuruId}")
  .onCreate(async (snap, context) => {
    const duyuruId = context.params.duyuruId;
    const d = snap.data() || {};

    const baslik = (d.baslik || "Yeni duyuru").toString();
    const mesaj = (d.mesaj || "Yeni bir duyuru yayınlandı.").toString();

    // Hedefleme alanları (TeacherHome’da bunları yazıyoruz)
    const targetAll = !!d.targetAll; // true => tüm öğrenciler
    const targetUids = Array.isArray(d.targetUids) ? d.targetUids : [];
    const targetClasses = Array.isArray(d.targetClasses) ? d.targetClasses : [];

    const db = admin.firestore();
    const tokens = new Set();

    // 1) Tüm öğrenciler
    if (targetAll || (targetUids.length === 0 && targetClasses.length === 0)) {
      const qs = await db.collection("ogrenciler").get();
      qs.forEach(doc => {
        const t = (doc.data() || {}).fcmToken;
        if (t) tokens.add(t);
      });
    } else {
      // 2) Seçili öğrenciler (uid)
      if (targetUids.length > 0) {
        for (const c of chunk(targetUids, 10)) {
          const qs = await db.collection("ogrenciler")
            .where(admin.firestore.FieldPath.documentId(), "in", c)
            .get();
          qs.forEach(doc => {
            const t = (doc.data() || {}).fcmToken;
            if (t) tokens.add(t);
          });
        }
      }

      // 3) Seçili sınıflar
      if (targetClasses.length > 0) {
        for (const c of chunk(targetClasses, 10)) {
          const qs = await db.collection("ogrenciler")
            .where("sinif", "in", c)
            .get();
          qs.forEach(doc => {
            const t = (doc.data() || {}).fcmToken;
            if (t) tokens.add(t);
          });
        }
      }
    }

    const tokenList = Array.from(tokens);
    if (tokenList.length === 0) {
      console.log("No FCM tokens found. Skip.");
      return null;
    }

    // FCM multicast (500 limit)
    const batches = chunk(tokenList, 500);

    for (const b of batches) {
      const res = await admin.messaging().sendEachForMulticast({
        tokens: b,
        notification: {
          title: baslik,
          body: mesaj.length > 120 ? mesaj.substring(0, 120) + "..." : mesaj
        },
        data: {
          duyuruId: duyuruId
        },
        android: {
          priority: "high",
          notification: {
            channelId: "default_channel"
          }
        }
      });

      // Geçersiz token temizleme (opsiyonel)
      // res.responses.forEach((r, idx) => {
      //   if (!r.success) console.log("FCM error:", r.error?.message);
      // });
    }

    return null;
  });
