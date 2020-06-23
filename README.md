# FA Bank Flutter App

About: demo and concept app

## Portfolio App
- User authentication done using OAuth2
-- Access token expires in 1 minute, and is renewed with refresh token
- Stocks data in Graphql backend
- Bloc state management
- Dio HTTP client
- Caching with Shared Preferences

- To (re)generate Podo's:
    flutter packages pub run build_runner build --delete-conflicting-outputs

- To create new Android release, run commands in repo:
    cd android/
    ./gradlew clean assembleRelease
