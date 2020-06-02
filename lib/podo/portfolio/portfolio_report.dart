import 'package:fa_bank/podo/portfolio/investment.dart';
import 'package:json_annotation/json_annotation.dart';

part 'portfolio_report.g.dart';

@JsonSerializable()
class PortfolioReport {
  double marketValue;
  double cashBalance;
  double netAssetValue;
  List<Investment> investments;

  PortfolioReport(this.marketValue, this.cashBalance, this.netAssetValue, this.investments);

  factory PortfolioReport.fromJson(Map<String, dynamic> json) => _$PortfolioReportFromJson(json);

  Map<String, dynamic> toJson() => _$PortfolioReportToJson(this);
}