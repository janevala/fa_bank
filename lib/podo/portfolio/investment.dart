import 'package:fa_bank/podo/security/security.dart';
import 'package:json_annotation/json_annotation.dart';

part 'investment.g.dart';

@JsonSerializable()
class Investment {
  Security security;
  double amount;
  double positionValue;
  double changePercent;
  double purchaseValue;

  Investment(this.security, this.amount, this.positionValue, this.changePercent, this.purchaseValue);

  factory Investment.fromJson(Map<String, dynamic> json) => _$InvestmentFromJson(json);

  Map<String, dynamic> toJson() => _$InvestmentToJson(this);
}