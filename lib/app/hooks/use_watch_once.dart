import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A hook that listens to a Riverpod provider and only takes the first emitted value.
///
/// If [notNull] is true, the hook will ignore null values and wait for the first non-null value.
T? useWatchOnce<T>(WidgetRef ref, ProviderListenable<T> provider, {bool notNull = true}) {
  final value = useState<T?>(null);
  final hasValue = useRef(false);

  useEffect(
    () {
      if (!hasValue.value) {
        final subscription = ref.listenManual<T>(provider, fireImmediately: true, (_, next) {
          if (!hasValue.value && (!notNull || next != null)) {
            value.value = next;
            hasValue.value = true;
          }
        });
        return subscription.close;
      }
      return null;
    },
    // We assume that we're using the same provider, hence we don't add it to dependencies.
    // Otherwise using family providers would lead to unnecessary useEffect triggers.
    [notNull, hasValue.value],
  );

  return value.value;
}
