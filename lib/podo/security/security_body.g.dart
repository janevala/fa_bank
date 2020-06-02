// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityBody _$SecurityBodyFromJson(Map<String, dynamic> json) {
  return SecurityBody(
    (json['securities'] as List)
        ?.map((e) =>
            e == null ? null : Security.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$SecurityBodyToJson(SecurityBody instance) =>
    <String, dynamic>{
      'securities': instance.securities,
    };
