import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/firestore_transactions_repository.dart'; // backend:firebase
import 'package:emiliano_cesare_flutter_template/repositories/transactions/i_transactions_repository.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/mock_transactions_repository.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/rest_transactions_repository.dart'; // backend:rest
import 'package:emiliano_cesare_flutter_template/repositories/transactions/supabase_transactions_repository.dart'; // backend:supabase
import 'package:emiliano_cesare_flutter_template/services/api/api_client.dart'; // backend:rest
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transactions_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ITransactionsRepository transactionsRepository(Ref ref) => switch (AppConfig.backend) {
  Backend.mock => MockTransactionsRepository(),
  Backend.rest => RestTransactionsRepository(ref.watch(apiClientProvider)), // backend:rest
  Backend.firebase => FirestoreTransactionsRepository(), // backend:firebase
  Backend.supabase => SupabaseTransactionsRepository(), // backend:supabase
  // tool/setup.dart enables this fallback when it removes a backend.
  // backend:fallback _ => MockTransactionsRepository(),
};
