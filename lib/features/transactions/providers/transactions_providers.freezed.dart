// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transactions_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionsState {

 List<TransactionModel> get items; String? get nextCursor; bool get loadingMore;/// Set when the next page failed: the list stops auto-loading until
/// `retryLoadMore` (the first page's errors go to the AsyncValue instead).
 Object? get loadMoreError;
/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionsStateCopyWith<TransactionsState> get copyWith => _$TransactionsStateCopyWithImpl<TransactionsState>(this as TransactionsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TransactionsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionsState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&const DeepCollectionEquality().equals(other.loadMoreError, _this.loadMoreError));
}


@override
int get hashCode {
  final _this = this as TransactionsState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.loadingMore,const DeepCollectionEquality().hash(_this.loadMoreError));
}

@override
String toString() {
  final _this = this as TransactionsState;
  return 'TransactionsState(items: ${_this.items}, nextCursor: ${_this.nextCursor}, loadingMore: ${_this.loadingMore}, loadMoreError: ${_this.loadMoreError})';
}


}

/// @nodoc
abstract mixin class $TransactionsStateCopyWith<$Res>  {
  factory $TransactionsStateCopyWith(TransactionsState value, $Res Function(TransactionsState) _then) = _$TransactionsStateCopyWithImpl;
@useResult
$Res call({
 List<TransactionModel> items, String? nextCursor, bool loadingMore, Object? loadMoreError
});




}
/// @nodoc
class _$TransactionsStateCopyWithImpl<$Res>
    implements $TransactionsStateCopyWith<$Res> {
  _$TransactionsStateCopyWithImpl(this._self, this._then);

  final TransactionsState _self;
  final $Res Function(TransactionsState) _then;

/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? loadingMore = null,Object? loadMoreError = freezed,}) {
  return _then(TransactionsState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TransactionModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError ,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionsState].
extension TransactionsStatePatterns on TransactionsState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionsState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionsState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionsState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TransactionModel> items,  String? nextCursor,  bool loadingMore,  Object? loadMoreError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
return $default(_that.items,_that.nextCursor,_that.loadingMore,_that.loadMoreError);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TransactionModel> items,  String? nextCursor,  bool loadingMore,  Object? loadMoreError)  $default,) {final _that = this;
switch (_that) {
case _TransactionsState():
return $default(_that.items,_that.nextCursor,_that.loadingMore,_that.loadMoreError);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TransactionModel> items,  String? nextCursor,  bool loadingMore,  Object? loadMoreError)?  $default,) {final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
return $default(_that.items,_that.nextCursor,_that.loadingMore,_that.loadMoreError);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionsState extends TransactionsState {
  const _TransactionsState({required  List<TransactionModel> items, this.nextCursor, this.loadingMore = false, this.loadMoreError}): _items = items,super._();
  

 final  List<TransactionModel> _items;
@override List<TransactionModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
@override@JsonKey() final  bool loadingMore;
/// Set when the next page failed: the list stops auto-loading until
/// `retryLoadMore` (the first page's errors go to the AsyncValue instead).
@override final  Object? loadMoreError;

/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionsStateCopyWith<_TransactionsState> get copyWith => __$TransactionsStateCopyWithImpl<_TransactionsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionsState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&const DeepCollectionEquality().equals(other.loadMoreError, loadMoreError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,loadingMore,const DeepCollectionEquality().hash(loadMoreError));
}

@override
String toString() {
    return 'TransactionsState(items: $items, nextCursor: $nextCursor, loadingMore: $loadingMore, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class _$TransactionsStateCopyWith<$Res> implements $TransactionsStateCopyWith<$Res> {
  factory _$TransactionsStateCopyWith(_TransactionsState value, $Res Function(_TransactionsState) _then) = __$TransactionsStateCopyWithImpl;
@override @useResult
$Res call({
 List<TransactionModel> items, String? nextCursor, bool loadingMore, Object? loadMoreError
});




}
/// @nodoc
class __$TransactionsStateCopyWithImpl<$Res>
    implements _$TransactionsStateCopyWith<$Res> {
  __$TransactionsStateCopyWithImpl(this._self, this._then);

  final _TransactionsState _self;
  final $Res Function(_TransactionsState) _then;

/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? loadingMore = null,Object? loadMoreError = freezed,}) {
  return _then(_TransactionsState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TransactionModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError ,
  ));
}


}

// dart format on
