import 'package:fa_bank/podo/portfolio/client.dart';
import 'package:fa_bank/podo/portfolio/graph.dart';
import 'package:fa_bank/podo/portfolio/portfolio_report.dart';
import 'package:json_annotation/json_annotation.dart';

part 'market_data.g.dart';

@JsonSerializable()
class MarketData {
  double latestValue;

  MarketData(this.latestValue);

  factory MarketData.fromJson(Map<String, dynamic> json) => _$MarketDataFromJson(json);

  Map<String, dynamic> toJson() => _$MarketDataToJson(this);
}