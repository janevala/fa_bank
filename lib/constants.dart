import 'package:json_annotation/json_annotation.dart';

class Constants {
  static const String faBaseUrl = 'https://fadev.fasolutions.com/';
  static const String faAuthApi = faBaseUrl + 'graphql';
  @JsonKey(name: 'client_id')
  static const String clientId = 'fa-back';
  @JsonKey(name: 'client_secret')
  static const String clientSecret = 'f692d597-0f4a-4495-a90e-1d090e7288fa';
}
