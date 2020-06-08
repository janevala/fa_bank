// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Investment _$InvestmentFromJson(Map<String, dynamic> json) {
  return Investment(
    json['security'] == null
        ? null
        : Security.fromJson(json['security'] as Map<String, dynamic>),
    (json['amount'] as num)?.toDouble(),
    (json['positionValue'] as num)?.toDouble(),
    (json['changePercent'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$InvestmentToJson(Investment instance) =>
    <String, dynamic>{
      'security': instance.security,
      'amount': instance.amount,
      'positionValue': instance.positionValue,
      'changePercent': instance.changePercent,
    };
