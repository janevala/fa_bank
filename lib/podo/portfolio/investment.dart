import 'package:fa_bank/podo/security/security.dart';
import 'package:json_annotation/json_annotation.dart';

part 'investment.g.dart';

@JsonSerializable()
class Investment {
  Security security;
  double positionValue;
  double changePercent;

  Investment(this.security, this.positionValue, this.changePercent);

  factory Investment.fromJson(Map<String, dynamic> json) => _$InvestmentFromJson(json);

  Map<String, dynamic> toJson() => _$InvestmentToJson(this);
}