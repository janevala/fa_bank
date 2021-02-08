import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config_model.g.dart';

@JsonSerializable()
class ConfigModel {
  @JsonKey(name: 'login_user_name')
  String loginUserName;
  @JsonKey(name: 'login_password')
  String loginPassword;
  @JsonKey(name: 'backend')
  String backend;
  @JsonKey(name: 'client_id')
  String clientId;
  @JsonKey(name: 'client_secret')
  String clientSecret;
  @JsonKey(name: 'portfolio_id')
  int portfolioId;

  ConfigModel({
    @required this.loginUserName,
    @required this.loginPassword,
    @required this.backend,
    @required this.clientId,
    @required this.clientSecret,
    @required this.portfolioId,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) => _$ConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigModelToJson(this);
}
