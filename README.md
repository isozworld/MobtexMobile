# Mobtex Mobile - Flutter Warehouse Management App

Modern Android depo yönetim uygulaması.

## 📱 Özellikler

✅ Modern ve kullanıcı dostu arayüz  
✅ ASP.NET Core API ile entegrasyon  
✅ Güvenli authentication sistemi  
✅ Depo işlemleri modülleri  
✅ Satış ve Alış yönetimi  
✅ Responsive tasarım  
✅ Offline session yönetimi  

## 🛠️ Windows Kurulum Adımları

### 1. Flutter SDK Kurulumu

**a) Flutter SDK İndirin:**
- https://docs.flutter.dev/get-started/install/windows adresine gidin
- "Get the Flutter SDK" bölümünden Flutter SDK'yı indirin
- Örnek: `flutter_windows_3.16.0-stable.zip`

**b) Flutter'ı Ayıklayın:**
- ZIP dosyasını ayıklayın (örn: `C:\src\flutter`)
- DİKKAT: Program Files gibi yönetici izni gerektiren yerlere koymayın

**c) Path'e Ekleyin:**
1. Windows Arama'da "Environment Variables" yazın
2. "Edit the system environment variables" seçin
3. "Environment Variables" butonuna tıklayın
4. "Path" değişkenini seçip "Edit" tıklayın
5. "New" tıklayıp Flutter'ın bin klasörünü ekleyin: `C:\src\flutter\bin`
6. "OK" ile kaydedin

**d) Terminali Yeniden Başlatın ve Test Edin:**
```bash
flutter --version
```

### 2. Android Studio Kurulumu

**a) Android Studio İndirin:**
- https://developer.android.com/studio
- "Download Android Studio" butonuna tıklayın

**b) Kurulumu Yapın:**
- İndirilen `.exe` dosyasını çalıştırın
- Varsayılan ayarlarla kuruluma devam edin
- Android SDK, Android SDK Platform ve Android Virtual Device seçili olmalı

**c) Android SDK Kurulumu:**
1. Android Studio'yu açın
2. "More Actions" > "SDK Manager"
3. "SDK Platforms" sekmesinde:
   - Android 13.0 (Tiramisu) API Level 33
   - Android 14.0 (UpsideDownCake) API Level 34
4. "SDK Tools" sekmesinde:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android SDK Platform-Tools
   - Android Emulator
5. "Apply" ve "OK"

**d) Android Licenses Kabul Edin:**
```bash
flutter doctor --android-licenses
```
Tüm lisansları "y" ile kabul edin.

### 3. Visual Studio Code (Opsiyonel ama Önerilen)

**a) VS Code İndirin:**
- https://code.visualstudio.com/

**b) Flutter ve Dart Extensionları:**
1. VS Code'u açın
2. Extensions (Ctrl+Shift+X)
3. "Flutter" arayın ve yükleyin (otomatik olarak Dart'ı da yükler)

### 4. Flutter Doctor Kontrolü

Terminalda çalıştırın:
```bash
flutter doctor
```

Çıktı şöyle olmalı:
```
[✓] Flutter (Channel stable, 3.16.0)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio (version 2023.1)
[✓] VS Code (version 1.85)
[✓] Connected device (1 available)
```

## 🚀 Projeyi Çalıştırma

### 1. Projeyi Açın

```bash
cd MobtexMobile
```

### 2. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 3. API URL'sini Ayarlayın

`lib/services/api_service.dart` dosyasını açın ve baseUrl'i güncelleyin:

```dart
static const String baseUrl = 'http://10.1.20.60:5000';
```

**DİKKAT:** 
- Emülatör kullanıyorsanız: `http://10.0.2.2:5000` (localhost için)
- Gerçek cihaz kullanıyorsanız: Bilgisayarınızın yerel IP'si (örn: `http://192.168.1.100:5000`)

### 4. Emülatör Oluşturma ve Çalıştırma

**Android Studio ile:**
1. Android Studio'yu açın
2. "More Actions" > "Virtual Device Manager"
3. "Create Device"
4. Cihaz seçin (örn: Pixel 6)
5. System Image seçin (örn: Android 13.0 - API 33)
6. "Finish"
7. Play butonuna tıklayarak emülatörü başlatın

**Komut satırı ile:**
```bash
# Mevcut emülatörleri listele
flutter emulators

# Emülatör oluştur (ilk kez)
flutter emulators --create

# Emülatörü başlat
flutter emulators --launch <emulator_id>
```

**Önerilen Emülatör Ayarları:**
- Device: Pixel 6 veya Pixel 7
- System Image: Android 13.0 (API 33) veya Android 14.0 (API 34)
- RAM: 2048 MB veya daha fazla
- Internal Storage: 2048 MB

### 5. Uygulamayı Çalıştırın

**VS Code ile:**
1. F5'e basın veya
2. Terminal: `flutter run`

**Android Studio ile:**
1. Projeyi açın
2. Sağ üstteki cihaz seçicide emülatörü seçin
3. Run butonuna (▶) tıklayın

**Komut satırı:**
```bash
flutter run
```

Debug modunda hot reload için: `r`  
Hot restart için: `R`  
Çıkmak için: `q`

## 📱 Gerçek Cihazda Test

### 1. USB Debugging Aktif Edin

**Android Cihazda:**
1. Ayarlar > Telefon Hakkında
2. "Yapı Numarası"na 7 kez tıklayın
3. Geliştirici seçenekleri açıldı
4. Ayarlar > Geliştirici Seçenekleri
5. "USB Debugging" aktif edin

### 2. Cihazı Bağlayın

```bash
# Cihazın bağlı olduğunu kontrol edin
flutter devices

# Uygulamayı çalıştırın
flutter run
```

## 🔑 Giriş Bilgileri

**Test Kullanıcısı:**
- Kullanıcı Adı: `admin`
- Şifre: `Abc*1234`

## 📂 Proje Yapısı

```
MobtexMobile/
├── lib/
│   ├── main.dart                 # Uygulama giriş noktası
│   ├── screens/
│   │   ├── login_screen.dart     # Login ekranı
│   │   └── home_screen.dart      # Ana menü
│   └── services/
│       └── api_service.dart      # API entegrasyonu
├── android/                      # Android özgü dosyalar
├── pubspec.yaml                  # Bağımlılıklar
└── README.md
```

## 🛠️ Yararlı Komutlar

```bash
# Bağımlılıkları güncelle
flutter pub get

# Projeyi temizle
flutter clean

# APK oluştur (release)
flutter build apk

# APK oluştur (split per ABI - daha küçük)
flutter build apk --split-per-abi

# Cihazları listele
flutter devices

# Log'ları görüntüle
flutter logs

# Performans profili
flutter run --profile
```

## 🐛 Sorun Giderme

### Gradle Hatası
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### SDK Hatası
```bash
flutter doctor --android-licenses
flutter doctor -v
```

### Emülatör Başlamıyor
1. Android Studio > AVD Manager
2. Emülatörü silin ve yeniden oluşturun
3. BIOS'ta Virtualization (VT-x/AMD-V) aktif olmalı

### API Bağlantı Hatası
1. API servisinin çalıştığından emin olun
2. Firewall/Antivirus kontrolü
3. Emülatör için doğru IP kullanın:
   - Localhost: `http://10.0.2.2:5000`
   - Gerçek cihaz: PC'nin IP'si (örn: `http://192.168.1.100:5000`)

## 🎨 Ekran Görüntüleri

- **Login Ekranı:** Modern gradient tasarım, animasyonlar
- **Ana Menü:** Kategorize edilmiş buton grid sistemi
- **User Header:** Kullanıcı bilgileri ve logout

## 📝 Notlar

- Minimum Android SDK: 21 (Android 5.0)
- Target Android SDK: 34 (Android 14)
- HTTP istekleri için `usesCleartextTraffic` aktif (development için)
- Production'da HTTPS kullanılmalı

## 🔄 Güncellemeler

Gelecek özellikler:
- Depolar Arası transfer modülü
- Araba'dan kabul modülü
- Satış ve Alış işlemleri
- Stok sayım
- Raporlama sistemi
- Offline çalışma modu

## 📞 Destek

Sorunlar için issue açabilirsiniz.

---

**Happy Coding! 🚀**
