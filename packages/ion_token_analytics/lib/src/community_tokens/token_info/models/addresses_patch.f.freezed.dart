// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'addresses_patch.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AddressesPatch _$AddressesPatchFromJson(Map<String, dynamic> json) {
  return _AddressesPatch.fromJson(json);
}

/// @nodoc
mixin _$AddressesPatch {
  String? get blockchain => throw _privateConstructorUsedError;
  String? get ionConnect => throw _privateConstructorUsedError;

  /// Serializes this AddressesPatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AddressesPatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddressesPatchCopyWith<AddressesPatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddressesPatchCopyWith<$Res> {
  factory $AddressesPatchCopyWith(
    AddressesPatch value,
    $Res Function(AddressesPatch) then,
  ) = _$AddressesPatchCopyWithImpl<$Res, AddressesPatch>;
  @useResult
  $Res call({String? blockchain, String? ionConnect});
}

/// @nodoc
class _$AddressesPatchCopyWithImpl<$Res, $Val extends AddressesPatch>
    implements $AddressesPatchCopyWith<$Res> {
  _$AddressesPatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AddressesPatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? blockchain = freezed, Object? ionConnect = freezed}) {
    return _then(
      _value.copyWith(
            blockchain: freezed == blockchain
                ? _value.blockchain
                : blockchain // ignore: cast_nullable_to_non_nullable
                      as String?,
            ionConnect: freezed == ionConnect
                ? _value.ionConnect
                : ionConnect // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AddressesPatchImplCopyWith<$Res>
    implements $AddressesPatchCopyWith<$Res> {
  factory _$$AddressesPatchImplCopyWith(
    _$AddressesPatchImpl value,
    $Res Function(_$AddressesPatchImpl) then,
  ) = __$$AddressesPatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? blockchain, String? ionConnect});
}

/// @nodoc
class __$$AddressesPatchImplCopyWithImpl<$Res>
    extends _$AddressesPatchCopyWithImpl<$Res, _$AddressesPatchImpl>
    implements _$$AddressesPatchImplCopyWith<$Res> {
  __$$AddressesPatchImplCopyWithImpl(
    _$AddressesPatchImpl _value,
    $Res Function(_$AddressesPatchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AddressesPatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? blockchain = freezed, Object? ionConnect = freezed}) {
    return _then(
      _$AddressesPatchImpl(
        blockchain: freezed == blockchain
            ? _value.blockchain
            : blockchain // ignore: cast_nullable_to_non_nullable
                  as String?,
        ionConnect: freezed == ionConnect
            ? _value.ionConnect
            : ionConnect // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AddressesPatchImpl extends _AddressesPatch {
  const _$AddressesPatchImpl({this.blockchain, this.ionConnect}) : super._();

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
            (identical(other.blockchain, blockchain) ||
                other.blockchain == blockchain) &&
            (identical(other.ionConnect, ionConnect) ||
                other.ionConnect == ionConnect));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, blockchain, ionConnect);

  /// Create a copy of AddressesPatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddressesPatchImplCopyWith<_$AddressesPatchImpl> get copyWith =>
      __$$AddressesPatchImplCopyWithImpl<_$AddressesPatchImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AddressesPatchImplToJson(this);
  }
}

abstract class _AddressesPatch extends AddressesPatch {
  const factory _AddressesPatch({
    final String? blockchain,
    final String? ionConnect,
  }) = _$AddressesPatchImpl;
  const _AddressesPatch._() : super._();

  factory _AddressesPatch.fromJson(Map<String, dynamic> json) =
      _$AddressesPatchImpl.fromJson;

  @override
  String? get blockchain;
  @override
  String? get ionConnect;

  /// Create a copy of AddressesPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddressesPatchImplCopyWith<_$AddressesPatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
