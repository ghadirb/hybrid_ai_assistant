
#!/bin/bash
mkdir -p android/app/keystore
keytool -genkey -v -keystore android/app/keystore/my-release-key.jks -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000 -storepass 12345678 -keypass 12345678 -dname "CN=ghadir baraty, OU=Tejarat No, O=Tejarat No, L=Mashhad, ST=Khorasan Razavi, C=IR"
echo "Keystore created at android/app/keystore/my-release-key.jks"
