
Hybrid AI Assistant - Full project scaffold
------------------------------------------

What I included:
- Flutter app with Chat UI (text + Telegram-style voice recording)
- Offline ASR pipeline (native Vosk integration, ModelSelector to download Vosk model)
- Google Drive backup & restore (list backups, restore selected)
- Local SQLite memory for messages
- Kotlin MainActivity with MethodChannel (loadModel, recognizeFile)
- Codemagic YAML for building APK/AAB and publishing to Google Play (production track)
- Keystore configuration is hardcoded into android/app/build.gradle for testing purposes (NOT secure for public repos)
- google-services.json is included if you uploaded it.

Important steps before building:
1. Add your keystore file at: android/app/keystore/my-release-key.jks
   (You created one locally; place it in the path above before building release)
2. If you want to keep google-services.json secret, remove the file from repo and set ANDROID_FIREBASE_SECRET in Codemagic (base64 of the file).
3. If you plan to publish to Google Play: upload the Service Account JSON in Codemagic Publish settings (Codemagic will provide GCLOUD_SERVICE_ACCOUNT_CREDENTIALS variable).

Local build (example):
- Install Flutter & JDK 17
- flutter pub get
- flutter build apk --release -t lib/main.dart

Security note: storing keystore or passwords in the repo is insecure. For production, use Codemagic secure files or environment variables.
