import 'package:json_annotation/json_annotation.dart';

part 'daily_value.g.dart';

@JsonSerializable()
class DailyValue {
  DateTime date;
  double portfolioMinus100;
  double benchmarkMinus100;

  DailyValue(this.date, this.benchmarkMinus100, this.portfolioMinus100);

  factory DailyValue.fromJson(Map<String, dynamic> json) => _$DailyValueFromJson(json);

  Map<String, dynamic> toJson() => _$DailyValueToJson(this);
}