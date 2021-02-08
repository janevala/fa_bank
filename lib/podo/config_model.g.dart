// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigModel _$ConfigModelFromJson(Map<String, dynamic> json) {
  return ConfigModel(
    loginUserName: json['login_user_name'] as String,
    loginPassword: json['login_password'] as String,
    backend: json['backend'] as String,
    clientId: json['client_id'] as String,
    clientSecret: json['client_secret'] as String,
    portfolioId: json['portfolio_id'] as int,
  );
}

Map<String, dynamic> _$ConfigModelToJson(ConfigModel instance) =>
    <String, dynamic>{
      'login_user_name': instance.loginUserName,
      'login_password': instance.loginPassword,
      'backend': instance.backend,
      'client_id': instance.clientId,
      'client_secret': instance.clientSecret,
      'portfolio_id': instance.portfolioId,
    };
