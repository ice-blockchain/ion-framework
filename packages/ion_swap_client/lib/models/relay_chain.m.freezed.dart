// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relay_chain.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RelayChain _$RelayChainFromJson(Map<String, dynamic> json) {
  return _RelayChain.fromJson(json);
}

/// @nodoc
mixin _$RelayChain {
  String get name => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  int get id => throw _privateConstructorUsedError;
  bool get disabled => throw _privateConstructorUsedError;
  RelayCurrency get currency => throw _privateConstructorUsedError;

  /// Serializes this RelayChain to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelayChain
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelayChainCopyWith<RelayChain> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelayChainCopyWith<$Res> {
  factory $RelayChainCopyWith(
          RelayChain value, $Res Function(RelayChain) then) =
      _$RelayChainCopyWithImpl<$Res, RelayChain>;
  @useResult
  $Res call(
      {String name,
      String displayName,
      int id,
      bool disabled,
      RelayCurrency currency});

  $RelayCurrencyCopyWith<$Res> get currency;
}

/// @nodoc
class _$RelayChainCopyWithImpl<$Res, $Val extends RelayChain>
    implements $RelayChainCopyWith<$Res> {
  _$RelayChainCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelayChain
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? displayName = null,
    Object? id = null,
    Object? disabled = null,
    Object? currency = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      disabled: null == disabled
          ? _value.disabled
          : disabled // ignore: cast_nullable_to_non_nullable
              as bool,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as RelayCurrency,
    ) as $Val);
  }

  /// Create a copy of RelayChain
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RelayCurrencyCopyWith<$Res> get currency {
    return $RelayCurrencyCopyWith<$Res>(_value.currency, (value) {
      return _then(_value.copyWith(currency: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RelayChainImplCopyWith<$Res>
    implements $RelayChainCopyWith<$Res> {
  factory _$$RelayChainImplCopyWith(
          _$RelayChainImpl value, $Res Function(_$RelayChainImpl) then) =
      __$$RelayChainImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String displayName,
      int id,
      bool disabled,
      RelayCurrency currency});

  @override
  $RelayCurrencyCopyWith<$Res> get currency;
}

/// @nodoc
class __$$RelayChainImplCopyWithImpl<$Res>
    extends _$RelayChainCopyWithImpl<$Res, _$RelayChainImpl>
    implements _$$RelayChainImplCopyWith<$Res> {
  __$$RelayChainImplCopyWithImpl(
      _$RelayChainImpl _value, $Res Function(_$RelayChainImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelayChain
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? displayName = null,
    Object? id = null,
    Object? disabled = null,
    Object? currency = null,
  }) {
    return _then(_$RelayChainImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      disabled: null == disabled
          ? _value.disabled
          : disabled // ignore: cast_nullable_to_non_nullable
              as bool,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as RelayCurrency,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelayChainImpl implements _RelayChain {
  _$RelayChainImpl(
      {required this.name,
      required this.displayName,
      required this.id,
      required this.disabled,
      required this.currency});

  factory _$RelayChainImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelayChainImplFromJson(json);

  @override
  final String name;
  @override
  final String displayName;
  @override
  final int id;
  @override
  final bool disabled;
  @override
  final RelayCurrency currency;

  @override
  String toString() {
    return 'RelayChain(name: $name, displayName: $displayName, id: $id, disabled: $disabled, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelayChainImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.disabled, disabled) ||
                other.disabled == disabled) &&
            (identical(other.currency, currency) ||
                other.currency == currency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, displayName, id, disabled, currency);

  /// Create a copy of RelayChain
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelayChainImplCopyWith<_$RelayChainImpl> get copyWith =>
      __$$RelayChainImplCopyWithImpl<_$RelayChainImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelayChainImplToJson(
      this,
    );
  }
}

abstract class _RelayChain implements RelayChain {
  factory _RelayChain(
      {required final String name,
      required final String displayName,
      required final int id,
      required final bool disabled,
      required final RelayCurrency currency}) = _$RelayChainImpl;

  factory _RelayChain.fromJson(Map<String, dynamic> json) =
      _$RelayChainImpl.fromJson;

  @override
  String get name;
  @override
  String get displayName;
  @override
  int get id;
  @override
  bool get disabled;
  @override
  RelayCurrency get currency;

  /// Create a copy of RelayChain
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelayChainImplCopyWith<_$RelayChainImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
