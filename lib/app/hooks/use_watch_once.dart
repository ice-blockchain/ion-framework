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
      final subscription = ref.listenManual<T>(provider, (_, next) {
        if (!hasValue.value && (!notNull || next != null)) {
          value.value = next;
          hasValue.value = true;
        }
      });
      return subscription.close;
    },
    [provider, notNull],
  );

  return value.value;
}
