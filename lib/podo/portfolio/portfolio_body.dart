import 'package:fa_bank/podo/portfolio/portfolio.dart';
import 'package:json_annotation/json_annotation.dart';

part 'portfolio_body.g.dart';

@JsonSerializable()
class PortfolioBody {
  Portfolio portfolio;
  @JsonKey(ignore: true)
  String error;

  PortfolioBody(this.portfolio);

  factory PortfolioBody.fromJson(Map<String, dynamic> json) => _$PortfolioBodyFromJson(json);

  Map<String, dynamic> toJson() => _$PortfolioBodyToJson(this);

  PortfolioBody.withError(this.error);
}