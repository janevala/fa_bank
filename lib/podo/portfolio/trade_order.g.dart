// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeOrder _$TradeOrderFromJson(Map<String, dynamic> json) {
  return TradeOrder(
    json['securityCode'] as String,
    json['securityName'] as String,
    (json['amount'] as num)?.toDouble(),
    json['typeName'] as String,
    json['orderStatus'] as String,
    json['transactionDate'] == null
        ? null
        : DateTime.parse(json['transactionDate'] as String),
  );
}

Map<String, dynamic> _$TradeOrderToJson(TradeOrder instance) =>
    <String, dynamic>{
      'securityCode': instance.securityCode,
      'securityName': instance.securityName,
      'amount': instance.amount,
      'typeName': instance.typeName,
      'orderStatus': instance.orderStatus,
      'transactionDate': instance.transactionDate?.toIso8601String(),
    };
