// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'addresses.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Addresses _$AddressesFromJson(Map<String, dynamic> json) {
  return _Addresses.fromJson(json);
}

/// @nodoc
mixin _$Addresses {
  String get blockchain => throw _privateConstructorUsedError;
  String get ionConnect => throw _privateConstructorUsedError;

  /// Serializes this Addresses to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Addresses
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddressesCopyWith<Addresses> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddressesCopyWith<$Res> {
  factory $AddressesCopyWith(Addresses value, $Res Function(Addresses) then) =
      _$AddressesCopyWithImpl<$Res, Addresses>;
  @useResult
  $Res call({String blockchain, String ionConnect});
}

/// @nodoc
class _$AddressesCopyWithImpl<$Res, $Val extends Addresses> implements $AddressesCopyWith<$Res> {
  _$AddressesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Addresses
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? blockchain = null, Object? ionConnect = null}) {
    return _then(
      _value.copyWith(
            blockchain: null == blockchain
                ? _value.blockchain
                : blockchain // ignore: cast_nullable_to_non_nullable
                      as String,
            ionConnect: null == ionConnect
                ? _value.ionConnect
                : ionConnect // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AddressesImplCopyWith<$Res> implements $AddressesCopyWith<$Res> {
  factory _$$AddressesImplCopyWith(_$AddressesImpl value, $Res Function(_$AddressesImpl) then) =
      __$$AddressesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String blockchain, String ionConnect});
}

/// @nodoc
class __$$AddressesImplCopyWithImpl<$Res> extends _$AddressesCopyWithImpl<$Res, _$AddressesImpl>
    implements _$$AddressesImplCopyWith<$Res> {
  __$$AddressesImplCopyWithImpl(_$AddressesImpl _value, $Res Function(_$AddressesImpl) _then)
    : super(_value, _then);

  /// Create a copy of Addresses
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? blockchain = null, Object? ionConnect = null}) {
    return _then(
      _$AddressesImpl(
        blockchain: null == blockchain
            ? _value.blockchain
            : blockchain // ignore: cast_nullable_to_non_nullable
                  as String,
        ionConnect: null == ionConnect
            ? _value.ionConnect
            : ionConnect // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AddressesImpl implements _Addresses {
  const _$AddressesImpl({required this.blockchain, required this.ionConnect});

  factory _$AddressesImpl.fromJson(Map<String, dynamic> json) => _$$AddressesImplFromJson(json);

  @override
  final String blockchain;
  @override
  final String ionConnect;

  @override
  String toString() {
    return 'Addresses(blockchain: $blockchain, ionConnect: $ionConnect)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddressesImpl &&
            (identical(other.blockchain, blockchain) || other.blockchain == blockchain) &&
            (identical(other.ionConnect, ionConnect) || other.ionConnect == ionConnect));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, blockchain, ionConnect);

  /// Create a copy of Addresses
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddressesImplCopyWith<_$AddressesImpl> get copyWith =>
      __$$AddressesImplCopyWithImpl<_$AddressesImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AddressesImplToJson(this);
  }
}

abstract class _Addresses implements Addresses {
  const factory _Addresses({required final String blockchain, required final String ionConnect}) =
      _$AddressesImpl;

  factory _Addresses.fromJson(Map<String, dynamic> json) = _$AddressesImpl.fromJson;

  @override
  String get blockchain;
  @override
  String get ionConnect;

  /// Create a copy of Addresses
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddressesImplCopyWith<_$AddressesImpl> get copyWith => throw _privateConstructorUsedError;
}

AddressesPatch _$AddressesPatchFromJson(Map<String, dynamic> json) {
  return _AddressesPatch.fromJson(json);
}

/// @nodoc
mixin _$AddressesPatch {
  String? get blockchain => throw _privateConstructorUsedError;
  String? get ionConnect => throw _privateConstructorUsedError;

  /// Serializes this AddressesPatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$AddressesPatchImpl implements _AddressesPatch {
  const _$AddressesPatchImpl({this.blockchain, this.ionConnect});

  factory _$AddressesPatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$AddressesPatchImplFromJson(json);

  @override
  final String? blockchain;
  @override
  final String? ionConnect;

  @override
  String toString() {
    return 'AddressesPatch(blockchain: $blockchain, ionConnect: $ionConnect)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddressesPatchImpl &&
            (identical(other.blockchain, blockchain) || other.blockchain == blockchain) &&
            (identical(other.ionConnect, ionConnect) || other.ionConnect == ionConnect));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, blockchain, ionConnect);

  @override
  Map<String, dynamic> toJson() {
    return _$$AddressesPatchImplToJson(this);
  }
}

abstract class _AddressesPatch implements AddressesPatch {
  const factory _AddressesPatch({final String? blockchain, final String? ionConnect}) =
      _$AddressesPatchImpl;

  factory _AddressesPatch.fromJson(Map<String, dynamic> json) = _$AddressesPatchImpl.fromJson;

  @override
  String? get blockchain;
  @override
  String? get ionConnect;
}
