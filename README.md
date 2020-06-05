# FA Bank Flutter App

About: demo and concept app for potential sales cases.

## Portfolio App
- Authentication Dio HTTP & Bloc state management (flutter_bloc).
- Graphql stocks data (graphql_flutter).
- To (re)generate Podo's: flutter packages pub run build_runner build --delete-conflicting-outputs

## TODO:
- Current dual architecture of Dio & Block and graphql_flutter is less than ideal, and was done in a hurry for demo purposes. It would be better to handle all network traffic and state management using Dio and Block, and remove graphql_flutter from the app altogether.
