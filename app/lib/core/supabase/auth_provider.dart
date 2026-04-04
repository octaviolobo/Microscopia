import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:microlaudo/core/purchases/purchase_service.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.whenOrNull(
    data: (state) {
      if (state.event == AuthChangeEvent.signedIn && state.session?.user != null) {
        PurchaseService.login(state.session!.user.id);
      }
      return state.session?.user;
    },
  );
  return user ?? Supabase.instance.client.auth.currentUser;
});
