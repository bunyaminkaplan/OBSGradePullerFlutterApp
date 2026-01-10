# 📚 OBS Grade Puller

Üniversite Öğrenci Bilgi Sistemi'nin (OBS) mobil deneyimini yeniden tasarlayan bir Flutter uygulaması.

---

## 🤔 Neden Bu Proje?

Üniversitemin OBS sistemi bazı kronik sorunlara sahip:

- 🐢 **Yavaş ve hantal arayüz** — 10 saniyelik işlem 10 dakikaya uzuyor
- 🔐 **Captcha engelı** — Her girişte manuel çözüm gerektiriyor
- 📱 **Mobil desteği yok** — Responsive bile değil, küçük ekranlarda kullanılamaz
- 🔄 **Gereksiz adımlar** — Aynı bilgileri defalarca girmek zorunda kalıyorsunuz

API desteği talep ettim, olmadı. O zaman kendi yolumu açtım.

---

## ✨ Özellikler

| Özellik | Açıklama |
|---------|----------|
| 🤖 **Otomatik Captcha Çözümü** | TensorFlow Lite ile eğitilmiş model, captcha'yı saniyeler içinde çözüyor |
| 🚀 **Tek Dokunuşla Giriş** | Kayıtlı hesaplardan seçip anında giriş yapın |
| ⚡ **Hızlı Başlangıç** | Otomatik giriş aktifken uygulama açılır açılmaz notlarınız karşınızda |
| 🌙 **Dark/Light Tema** | Göz yormayan, tercihinizi hatırlayan tema desteği |
| 📊 **Sınıf İstatistikleri** | Her ders için ortalama ve dağılım bilgileri |
| 🎨 **Modern Arayüz** | Animasyonlar, blur efektleri ve akıcı geçişler |

---

## 🏗️ Mimari

Proje, Clean Architecture prensipleri üzerine inşa edildi. Her katman belirli bir sorumluluğa sahip ve birbirinden bağımsız test edilebilir durumda.

```
lib/
├── core/              # Ortak servisler, sabitler
├── features/
│   ├── auth/          # Giriş, profil yönetimi
│   ├── grades/        # Not görüntüleme
│   ├── settings/      # Uygulama ayarları
│   └── captcha/       # TFLite model entegrasyonu
└── infrastructure/    # Storage, DI, network
```

**Katman yapısı:**
- **Domain** — İş kuralları, saf Dart (Flutter bağımlılığı yok)
- **Data** — API iletişimi, veri dönüşümleri
- **Presentation** — UI, state yönetimi (Provider + ViewModel)


---

## 🧠 Captcha Eğitim ve İşleme Süreci

Bu modül, nihai üründe kullanılan yapay zeka modellerinin üretim fabrikasıdır. Ham veriden mobil uyumlu modele giden süreç şu 5 adımda işler:

1.  **Veri Yakalama (Async Ingestion):**
    Uygulama, ana akışı kilitlemeden (non-blocking) dış kaynaktan sürekli ham Captcha görseli çeker.

2.  **Akıllı Parçalama (Segmentation):**
    Gelen gürültülü görsel, görüntü işleme algoritmalarıyla analiz edilir ve her bir rakam, **32x32** piksellik bağımsız matrislere bölünür.

3.  **Hibrit Etiketleme (Human-in-the-Loop):**
    Yapay zeka, bölünen parçalar için bir ön tahmin sunar. Operatör sadece doğruluğu onaylar veya düzeltir. Bu sayede hatalı veri sıfıra indirilir.

4.  **Model Eğitimi (CNN Training):**
    Doğrulanmış veri seti, **Convolutional Neural Network (CNN)** mimarisiyle eğitilir. Veriler normalize edilerek modelin genelleme yeteneği artırılır.

5.  **Optimizasyon & Çıktı:**
    Eğitilen model, son kullanıcı cihazlarında (mobil/desktop) yüksek performansla çalışabilmesi için sıkıştırılmış formatlara (TFLite) dönüştürülür.


> Model eğitim araçları ve detayları ayrı bir repoda paylaşılacak.

---

## 🔮 Gelecek Planları

- [ ] Ders programı entegrasyonu
- [ ] Bildirimler (yeni not gelince)
- [ ] Widget desteği (ana ekran)

---

## ⚠️ Yasal Uyarı

Bu proje tamamen eğitim amaçlıdır. Yalnızca kendi hesabınızla kullanın. Üniversitenizin kullanım şartlarını ihlal etmekten kaçının.
