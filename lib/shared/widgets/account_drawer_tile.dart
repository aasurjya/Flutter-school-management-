import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';

/// A reusable drawer tile that navigates to the Account screen.
/// Displays the logged-in user's email as a subtitle when available.
class AccountDrawerTile extends ConsumerWidget {
  const AccountDrawerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return ListTile(
      leading: const Icon(Icons.account_circle_outlined),
      title: const Text('Account'),
      subtitle: user != null ? Text(user.email) : null,
      onTap: () => context.go('/account'),
    );
  }
}
