import 'package:flutter/material.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool notifyEmail = true;
  bool notifyPush = true;
  bool weeklyDigest = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      centerContent: false,
      title: 'Profile',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: theme.textTheme.displayMedium),
            const SizedBox(height: 6),
            Text(
              'Manage your account, preferences, and alerts.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ProfileCard(theme: theme)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _PreferencesCard(
                          notifyEmail: notifyEmail,
                          notifyPush: notifyPush,
                          weeklyDigest: weeklyDigest,
                          onChangedEmail: (v) =>
                              setState(() => notifyEmail = v),
                          onChangedPush: (v) => setState(() => notifyPush = v),
                          onChangedDigest: (v) =>
                              setState(() => weeklyDigest = v),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileCard(theme: theme),
                    const SizedBox(height: 16),
                    _PreferencesCard(
                      notifyEmail: notifyEmail,
                      notifyPush: notifyPush,
                      weeklyDigest: weeklyDigest,
                      onChangedEmail: (v) => setState(() => notifyEmail = v),
                      onChangedPush: (v) => setState(() => notifyPush = v),
                      onChangedDigest: (v) => setState(() => weeklyDigest = v),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Security', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Change password'),
                    subtitle: const Text(
                      'Update your password for account safety',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {},
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active sessions'),
                    subtitle: const Text('Review where you are signed in'),
                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Save changes',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Log out',
                          variant: AppButtonVariant.outlined,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 34,
            child: Text(
              'TA',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tran Anh', style: theme.textTheme.titleLarge),
                Text('Forestry Analyst', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('anh.tran@example.com', style: theme.textTheme.bodyLarge),
                Text('+84 912 345 678', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: [
                    Chip(
                      label: Text('Admin', style: theme.textTheme.bodyMedium),
                    ),
                    Chip(
                      label: Text(
                        'AI Access',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.notifyEmail,
    required this.notifyPush,
    required this.weeklyDigest,
    required this.onChangedEmail,
    required this.onChangedPush,
    required this.onChangedDigest,
  });

  final bool notifyEmail;
  final bool notifyPush;
  final bool weeklyDigest;
  final ValueChanged<bool> onChangedEmail;
  final ValueChanged<bool> onChangedPush;
  final ValueChanged<bool> onChangedDigest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferences', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          SwitchListTile(
            value: notifyEmail,
            title: const Text('Email notifications'),
            subtitle: const Text('Critical alerts and weekly updates'),
            onChanged: onChangedEmail,
          ),
          SwitchListTile(
            value: notifyPush,
            title: const Text('Push notifications'),
            subtitle: const Text('Mobile and desktop push for new alerts'),
            onChanged: onChangedPush,
          ),
          SwitchListTile(
            value: weeklyDigest,
            title: const Text('Weekly digest'),
            subtitle: const Text('Summary of scans and model changes'),
            onChanged: onChangedDigest,
          ),
        ],
      ),
    );
  }
}
