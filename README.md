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

## TODO's
- Caching could be done using more robust storage, for example Realmdb