// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PortfolioReport _$PortfolioReportFromJson(Map<String, dynamic> json) {
  return PortfolioReport(
    (json['marketValue'] as num)?.toDouble(),
    (json['cashBalance'] as num)?.toDouble(),
    (json['netAssetValue'] as num)?.toDouble(),
    (json['investments'] as List)
        ?.map((e) =>
            e == null ? null : Investment.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$PortfolioReportToJson(PortfolioReport instance) =>
    <String, dynamic>{
      'marketValue': instance.marketValue,
      'cashBalance': instance.cashBalance,
      'netAssetValue': instance.netAssetValue,
      'investments': instance.investments,
    };
