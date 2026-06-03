// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegisterRequestImpl _$$RegisterRequestImplFromJson(
  Map<String, dynamic> json,
) => _$RegisterRequestImpl(
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
  termsAccepted: json['termsAccepted'] as bool,
  privacyPolicyAccepted: json['privacyPolicyAccepted'] as bool,
);

Map<String, dynamic> _$$RegisterRequestImplToJson(
  _$RegisterRequestImpl instance,
) => <String, dynamic>{
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'password': instance.password,
  'termsAccepted': instance.termsAccepted,
  'privacyPolicyAccepted': instance.privacyPolicyAccepted,
};
