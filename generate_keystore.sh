
#!/bin/bash
mkdir -p android/app/keystore
keytool -genkey -v -keystore android/app/keystore/my-release-key.jks -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000
echo "Keystore created at android/app/keystore/my-release-key.jks"
