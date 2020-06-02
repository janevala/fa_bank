import 'package:fa_bank/podo/portfolio/daily_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'daily_values.g.dart';

@JsonSerializable()
class DailyValues {
  List<DailyValue> dailyValue;

  DailyValues(this.dailyValue);

  factory DailyValues.fromJson(Map<String, dynamic> json) => _$DailyValuesFromJson(json);

  Map<String, dynamic> toJson() => _$DailyValuesToJson(this);
}