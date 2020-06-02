import 'package:fa_bank/podo/portfolio/client.dart';
import 'package:fa_bank/podo/portfolio/graph.dart';
import 'package:fa_bank/podo/portfolio/portfolio_report.dart';
import 'package:json_annotation/json_annotation.dart';

part 'portfolio.g.dart';

@JsonSerializable()
class Portfolio {
  Client client;
  String portfolioName;
  PortfolioReport portfolioReport;
  Graph graph;

  Portfolio(this.client, this.portfolioName, this.portfolioReport, this.graph);

  factory Portfolio.fromJson(Map<String, dynamic> json) => _$PortfolioFromJson(json);

  Map<String, dynamic> toJson() => _$PortfolioToJson(this);
}