import 'package:freezed_annotation/freezed_annotation.dart';

part 'ion_signature.m.freezed.dart';
part 'ion_signature.m.g.dart';

@freezed
class IonSignature with _$IonSignature {
  factory IonSignature({
    required String r,
    required String s,
    required String? encoded,
  }) = _IonSignature;

  factory IonSignature.fromJson(Map<String, dynamic> json) => _$IonSignatureFromJson(json);
}
