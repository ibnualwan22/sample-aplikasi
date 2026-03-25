#!/bin/bash
set -e

exec > install_apk.log 2>&1

echo "1. Mempersiapkan Direktori Android SDK..."
export ANDROID_HOME=$HOME/android-sdk
mkdir -p $ANDROID_HOME/cmdline-tools

echo "2. Mengunduh Command Line Tools..."
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O $ANDROID_HOME/cmdline-tools.zip

echo "3. Mengekstrak menggunakan Python (Tidak Perlu Akses Root/Sudo)..."
python3 -m zipfile -e $ANDROID_HOME/cmdline-tools.zip $ANDROID_HOME/cmdline-tools

echo "4. Menata penamaan /latest..."
if [ -d "$ANDROID_HOME/cmdline-tools/cmdline-tools" ]; then
    mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest
fi
rm -f $ANDROID_HOME/cmdline-tools.zip

echo "5. Mengatur Environment Variables..."
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

if ! grep -q "ANDROID_HOME" ~/.bashrc; then
    echo '' >> ~/.bashrc
    echo '# Flutter Android SDK' >> ~/.bashrc
    echo 'export ANDROID_HOME=$HOME/android-sdk' >> ~/.bashrc
    echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.bashrc
fi

chmod +x $ANDROID_HOME/cmdline-tools/latest/bin/*

echo "6. Menerima Lisensi Android (Otomatis)..."
yes | sdkmanager --licenses > /dev/null

echo "7. Mengunduh SDK Platforms Android 34 (Butuh Beberapa Menit)..."
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null

echo "8. Meregistrasi SDK ke Flutter..."
flutter config --android-sdk $ANDROID_HOME

echo "9. Menerima Lisensi Flutter Android (Otomatis)..."
yes | flutter doctor --android-licenses > /dev/null

echo "10. Memulai Compile APK..."
cd /home/ibnualwan/sample-aplikasi
flutter build apk --release

echo "DONE!"
