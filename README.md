# FA Bank Flutter App

About: Demo and concept app, developed in Flutter and Graphql

## Portfolio App
- User authentication done using OAuth2
-- Access token expires in 1 minute, and is renewed with refresh token
- Portfolio data in Graphql backend
- Bloc state management
- Dio HTTP client
- Caching with Shared Preferences

- To (re)generate Podo's (models):
    flutter packages pub run build_runner build --delete-conflicting-outputs

- To create new Android release, run commands in repo:
    cd android/
    ./gradlew clean assembleRelease

- To create new iOS release, use Xcode -> Product -> Archive

- Backend configuration is assets/config.b64 Base 64 encoded file.

- Generate backend config
    openssl base64  -A -in config.json -out config.b64

- Android, iOS, MacOS desktop and web builds experimented, but form factor is mobile