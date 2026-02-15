# 🚀 Windows için Detaylı Kurulum Rehberi

## 📋 İçindekiler
1. [Flutter SDK Kurulumu](#flutter-sdk-kurulumu)
2. [Android Studio Kurulumu](#android-studio-kurulumu)
3. [Emülatör Kurulumu](#emülatör-kurulumu)
4. [Projeyi Çalıştırma](#projeyi-çalıştırma)
5. [Sorun Giderme](#sorun-giderme)

---

## 1️⃣ Flutter SDK Kurulumu

### Adım 1: Flutter İndirin
1. https://docs.flutter.dev/get-started/install/windows adresine gidin
2. "Get the Flutter SDK" bölümünden en son stable sürümü indirin
3. ZIP dosyasını indirin (örn: `flutter_windows_3.16.0-stable.zip`)

### Adım 2: Flutter'ı Kurun
1. ZIP dosyasını bir klasöre çıkarın:
   - ✅ Önerilen: `C:\src\flutter`
   - ❌ Kullanmayın: `C:\Program Files\flutter` (izin sorunu)

2. Klasör yapısı şöyle olmalı:
   ```
   C:\src\flutter\
   ├── bin\
   ├── packages\
   └── ...
   ```

### Adım 3: PATH'e Ekleyin
1. **Windows Arama'da** "env" yazın
2. **"Edit the system environment variables"** seçin
3. **"Environment Variables"** butonuna tıklayın
4. **User variables** altında **"Path"** seçin ve **"Edit"** tıklayın
5. **"New"** tıklayın
6. Flutter bin klasörünü ekleyin: `C:\src\flutter\bin`
7. **"OK"** ile tüm pencereleri kapatın

### Adım 4: Test Edin
Yeni bir **Command Prompt** veya **PowerShell** açın:
```bash
flutter --version
```

Çıktı:
```
Flutter 3.16.0 • channel stable
```

---

## 2️⃣ Android Studio Kurulumu

### Adım 1: İndirin
1. https://developer.android.com/studio adresine gidin
2. **"Download Android Studio"** butonuna tıklayın
3. Lisans şartlarını kabul edin ve indirin

### Adım 2: Kurun
1. İndirilen `.exe` dosyasını çalıştırın
2. "Next" ile ilerleyin
3. **Önemli:** Bu seçenekler işaretli olmalı:
   - ✅ Android SDK
   - ✅ Android SDK Platform
   - ✅ Android Virtual Device
4. Kurulumu tamamlayın

### Adım 3: İlk Kurulum Sihirbazı
1. Android Studio'yu açın
2. "Do not import settings" seçin
3. "Next" ile ilerleyin
4. "Standard" kurulum seçin
5. Tema seçin (istediğinizi)
6. "Finish" - SDK'lar indirilecek (10-15 dakika sürebilir)

### Adım 4: SDK Manager'dan Gerekli Paketleri Kurun
1. Android Studio'yu açın
2. **"More Actions"** > **"SDK Manager"**
3. **"SDK Platforms"** sekmesi:
   - ✅ Android 13.0 (Tiramisu) - API Level 33
   - ✅ Android 14.0 (UpsideDownCake) - API Level 34

4. **"SDK Tools"** sekmesi (Show Package Details işaretleyin):
   - ✅ Android SDK Build-Tools 34.0.0
   - ✅ Android SDK Command-line Tools (latest)
   - ✅ Android SDK Platform-Tools
   - ✅ Android Emulator
   - ✅ Intel x86 Emulator Accelerator (HAXM installer)

5. **"Apply"** > **"OK"** - Paketler indirilecek

### Adım 5: Android Lisansları
Command Prompt veya PowerShell'de:
```bash
flutter doctor --android-licenses
```
Her soru için **"y"** yazın ve Enter'a basın.

---

## 3️⃣ Emülatör Kurulumu

### Adım 1: BIOS Ayarı (Önemli!)
**Emülatör çalışması için Virtualization aktif olmalı:**

1. Bilgisayarı yeniden başlatın
2. BIOS'a girin (genellikle F2, F10, Del veya Esc)
3. "Virtualization Technology" veya "VT-x" / "AMD-V" bulun
4. **Enabled** yapın
5. Kaydet ve çık

### Adım 2: Emülatör Oluşturma
1. Android Studio'yu açın
2. **"More Actions"** > **"Virtual Device Manager"**
3. **"Create Device"** tıklayın

4. **Hardware Seçimi:**
   - **Önerilen:** Pixel 6 veya Pixel 7
   - "Next"

5. **System Image:**
   - **Tiramisu (API 33)** veya **UpsideDownCake (API 34)** seçin
   - Yanında "Download" varsa indirin
   - "Next"

6. **AVD Yapılandırması:**
   - AVD Name: `Pixel_6_API_33`
   - **Advanced Settings:**
     - RAM: 2048 MB (2 GB)
     - Internal Storage: 2048 MB
     - Graphics: Automatic
   - "Finish"

### Adım 3: Emülatörü Test Edin
1. Virtual Device Manager'da oluşturduğunuz cihazın yanındaki **▶ (Play)** butonuna tıklayın
2. Emülatör açılmalı (ilk açılış 2-3 dakika sürebilir)

---

## 4️⃣ Projeyi Çalıştırma

### Adım 1: Flutter Doctor Kontrolü
```bash
flutter doctor
```

**Beklenen Çıktı:**
```
[✓] Flutter (Channel stable, 3.16.0)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Android Studio (version 2023.1)
[!] Connected device
    ! No devices available
```

### Adım 2: Projeyi Açın
```bash
cd C:\path\to\MobtexMobile
```

### Adım 3: Bağımlılıkları Yükleyin
```bash
flutter pub get
```

Çıktı:
```
Running "flutter pub get" in MobtexMobile...
Resolving dependencies... (5.2s)
Got dependencies!
```

### Adım 4: API URL'sini Ayarlayın
**`lib/services/api_service.dart`** dosyasını düzenleyin:

```dart
// Emülatör için (localhost)
static const String baseUrl = 'http://10.0.2.2:5000';

// VEYA gerçek cihaz için (PC'nizin IP'si)
static const String baseUrl = 'http://192.168.1.XXX:5000';
```

**PC IP'nizi bulmak için:**
```bash
ipconfig
```
"IPv4 Address" satırına bakın.

### Adım 5: Emülatörü Başlatın
**Seçenek 1: Android Studio'dan**
1. Virtual Device Manager > Play butonu

**Seçenek 2: Komut satırından**
```bash
flutter emulators
flutter emulators --launch Pixel_6_API_33
```

### Adım 6: Uygulamayı Çalıştırın
```bash
flutter run
```

**İlk çalıştırma 2-5 dakika sürebilir!**

Çıktı:
```
Launching lib\main.dart on Pixel 6 API 33 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk.
Installing build\app\outputs\flutter-apk\app.apk...
Syncing files to device Pixel 6 API 33...
```

### Adım 7: Hot Reload
Uygulama çalışırken:
- **`r`** - Hot reload (değişiklikleri anında uygula)
- **`R`** - Hot restart (uygulamayı yeniden başlat)
- **`q`** - Çık

---

## 5️⃣ Sorun Giderme

### ❌ "Flutter SDK not found"
**Çözüm:**
```bash
# PATH'i kontrol edin
echo %PATH%

# Flutter bin klasörü listede yoksa tekrar ekleyin
# Environment Variables > Path > New > C:\src\flutter\bin
```

### ❌ "Android SDK not found"
**Çözüm:**
```bash
flutter config --android-sdk C:\Users\YourName\AppData\Local\Android\Sdk
```

### ❌ "Android license status unknown"
**Çözüm:**
```bash
flutter doctor --android-licenses
# Tümüne 'y' deyin
```

### ❌ Emülatör çok yavaş
**Çözüm:**
1. BIOS'ta Virtualization aktif mi kontrol edin
2. Emülatör RAM'ini artırın (4 GB'a çıkarın)
3. Graphics: Hardware - GLES 2.0 seçin

### ❌ "Gradle build failed"
**Çözüm:**
```bash
cd android
gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### ❌ "Unable to connect to API"
**Çözüm:**
1. API servisinin çalıştığını kontrol edin
2. Windows Firewall'da port 5000 açık mı kontrol edin
3. Emülatör için `10.0.2.2` kullanın
4. Gerçek cihaz için PC'nin yerel IP'sini kullanın

### ❌ "HAXM installation failed"
**Çözüm:**
1. BIOS'ta VT-x/AMD-V aktif mi kontrol edin
2. Hyper-V kapalı mı kontrol edin:
   ```bash
   bcdedit /set hypervisorlaunchtype off
   # Sonra bilgisayarı yeniden başlatın
   ```

---

## 📱 VS Code ile Geliştirme (Opsiyonel)

### Adım 1: VS Code İndirin
https://code.visualstudio.com/

### Adım 2: Flutter Extension
1. VS Code'u açın
2. Extensions (Ctrl+Shift+X)
3. "Flutter" arayın
4. "Install" tıklayın (Dart otomatik gelecek)

### Adım 3: Projeyi Açın
```bash
code .
```

### Adım 4: Çalıştırın
- **F5** - Debug modda çalıştır
- **Ctrl+F5** - Release modda çalıştır

---

## ✅ Başarılı Kurulum Kontrol Listesi

- [ ] `flutter --version` çalışıyor
- [ ] `flutter doctor` tüm checkmark'lar ✓
- [ ] Android Studio kurulu
- [ ] Emülatör oluşturuldu ve çalışıyor
- [ ] `flutter devices` emülatörü gösteriyor
- [ ] `flutter run` uygulamayı başlatıyor
- [ ] Login ekranı görünüyor
- [ ] API bağlantısı çalışıyor

---

## 🎯 Önerilen Geliştirme Ortamı

**Windows 10/11:**
- RAM: En az 8 GB (16 GB önerilen)
- Disk: 10 GB boş alan
- CPU: Intel i5 veya AMD Ryzen 5 (daha iyisi)
- Virtualization: BIOS'ta aktif

**Yazılım:**
- Flutter SDK 3.16+
- Android Studio 2023.1+
- VS Code (opsiyonel)
- Git (version control için)

---

## 📞 Yardım

Sorun yaşıyorsanız:
1. `flutter doctor -v` çıktısını kontrol edin
2. Hata mesajlarını not edin
3. README.md'deki sorun giderme bölümüne bakın

**Happy Coding! 🚀**
