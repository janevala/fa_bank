import 'package:json_annotation/json_annotation.dart';

part 'trade_order.g.dart';

@JsonSerializable()
class TradeOrder {
  String securityCode;
  String securityName;
  double amount;
  String typeName;
  String orderStatus;
  DateTime transactionDate;

  TradeOrder(this.securityCode, this.securityName, this.amount, this.typeName, this.orderStatus, this.transactionDate);

  factory TradeOrder.fromJson(Map<String, dynamic> json) => _$TradeOrderFromJson(json);

  Map<String, dynamic> toJson() => _$TradeOrderToJson(this);
}