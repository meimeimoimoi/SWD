import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/dashboard_provider.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/admin_bottom_nav.dart';

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchFeedbackList();
    });
  }

  Color _getScoreColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 4) return Colors.green;
    if (score == 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<DashboardProvider>();
    final feedbackList = provider.feedbackList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phản hồi từ người dùng'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: provider.isLoading && feedbackList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : feedbackList.isEmpty
                ? const Center(child: Text('Chưa có phản hồi nào'))
                : RefreshIndicator(
                    onRefresh: provider.fetchFeedbackList,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: feedbackList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final feedback = feedbackList[index];
                        final score = feedback['score'] as int?;
                        final scoreLabel = feedback['scoreLabel'] ?? 'N/A';
                        final comment = feedback['comment'] ?? 'Không có nhận xét';
                        final userEmail = feedback['userEmail'] ?? 'User';
                        final userName = feedback['userName'] ?? '';
                        final predictedClass = feedback['predictedClass'] ?? 'Unknown';
                        final confidence = feedback['confidencePercentage'] ?? '0%';
                        final illnessName = feedback['illnessName'] ?? '';
                        
                        DateTime? createdAt;
                        if (feedback['createdAt'] != null) {
                          createdAt = DateTime.tryParse(feedback['createdAt']);
                        }
                        final dateStr = createdAt != null 
                            ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
                            : 'Unknown Date';

                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userEmail,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (userName.isNotEmpty)
                                          Text(
                                            userName,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(score).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      scoreLabel,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: _getScoreColor(score),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                comment,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: comment == 'Không có nhận xét' ? FontStyle.italic : null,
                                  color: comment == 'Không có nhận xét' ? Colors.grey : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.psychology_outlined, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Kết quả: $predictedClass ($confidence)',
                                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    if (illnessName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.medical_services_outlined, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Bệnh: $illnessName',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateStr,
                                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2), // Adjust index as needed
    );
  }
}
