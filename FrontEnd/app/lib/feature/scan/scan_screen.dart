import 'package:flutter/material.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/app_scaffold.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uploads = <_ScanItem>[
      _ScanItem(name: 'Oak_leaf.png', status: 'Completed', time: '2m ago'),
      _ScanItem(name: 'Pine_branch.jpg', status: 'Processing', time: '8m ago'),
      _ScanItem(name: 'Maple_spot.jpeg', status: 'Queued', time: '15m ago'),
    ];

    return AppScaffold(
      centerContent: false,
      title: 'Scan',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New scan', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 6),
            Text(
              'Upload or capture to run the model.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _UploadCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _HistoryCard(uploads: uploads)),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UploadCard(),
                    const SizedBox(height: 16),
                    _HistoryCard(uploads: uploads),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload image', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Drop image here or browse',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'PNG, JPG up to 10MB',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Upload files',
                  icon: Icons.folder_open,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Use camera',
                  variant: AppButtonVariant.outlined,
                  icon: Icons.photo_camera_outlined,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: ensure leaves are in focus and well-lit.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.uploads});
  final List<_ScanItem> uploads;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent scans', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...uploads.map((item) => _ScanTile(item: item)),
          const SizedBox(height: 12),
          AppButton(
            label: 'View full history',
            variant: AppButtonVariant.ghost,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ScanItem {
  const _ScanItem({
    required this.name,
    required this.status,
    required this.time,
  });
  final String name;
  final String status;
  final String time;
}

class _ScanTile extends StatelessWidget {
  const _ScanTile({required this.item});
  final _ScanItem item;

  Color _statusColor() {
    switch (item.status.toLowerCase()) {
      case 'completed':
        return AppColors.accent;
      case 'processing':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.image_outlined, color: _statusColor()),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleMedium),
                Text(item.status, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Text(item.time, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
