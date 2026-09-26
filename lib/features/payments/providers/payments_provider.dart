import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/auth_notifier.dart';
import 'package:emiliano_cesare_flutter_template/repositories/payments/payments_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payments_provider.g.dart';

/// Customer info (null when payments aren't available), kept in sync with the
/// signed-in user. Watched by `App` so it lives as long as the app.
@Riverpod(keepAlive: true)
class PaymentsNotifier extends _$PaymentsNotifier {
  @override
  Stream<CustomerInfo?> build() async* {
    final repo = ref.watch(paymentsRepositoryProvider);
    if (!repo.isAvailable) {
      yield null;
      return;
    }
    // Only the user id matters: profile edits must not re-login RevenueCat.
    await repo.identify(await ref.watch(authProvider.selectAsync((u) => u?.id)));
    yield* repo.customerInfo();
  }

  Future<void> purchase(Package package) => ref.read(paymentsRepositoryProvider).purchase(package);

  Future<void> restore() => ref.read(paymentsRepositoryProvider).restore();
}

@riverpod
bool paymentsAvailable(Ref ref) => ref.watch(paymentsRepositoryProvider).isAvailable;

@riverpod
bool isPremium(Ref ref) =>
    ref.watch(paymentsProvider).value?.entitlements.active.containsKey(AppConfig.revenueCatEntitlement) ?? false;

@riverpod
Future<Offering?> currentOffering(Ref ref) {
  final repo = ref.watch(paymentsRepositoryProvider);
  return repo.isAvailable ? repo.currentOffering() : Future.value();
}
