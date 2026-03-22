import 'dart:convert';

import 'package:flutter/material.dart';

import '../../share/constants/api_config.dart';
import '../../share/services/dashboard_service.dart';
import '../../share/services/prediction_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/admin_app_bar_actions.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/admin_pop_scope.dart';
import '../../share/widgets/app_card.dart';

class AdminServerManagementScreen extends StatefulWidget {
  const AdminServerManagementScreen({super.key});

  @override
  State<AdminServerManagementScreen> createState() =>
      _AdminServerManagementScreenState();
}

class _AdminServerManagementScreenState
    extends State<AdminServerManagementScreen> {
  final DashboardService _api = DashboardService();
  final PredictionService _prediction = PredictionService();
  Map<String, dynamic> _snapshot = {};
  bool _predictionHealthy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _api.getHealthChecks();
    final predOk = await _prediction.isPredictionServiceHealthy();
    if (mounted) {
      setState(() {
        _snapshot = snap;
        _predictionHealthy = predOk;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return AdminPopScope(
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Server management',
          style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
        ),
        actions: [
          ...adminSecondaryAppBarActions(context),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  children: [
                    Text(
                      'Health endpoints',
                      style: theme.textTheme.titleMedium?.copyWith(color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uses /health, /health/live, and /health/ready (no auth).',
                      style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: 16),
                    _HealthCard(
                      title: '/health/live',
                      code: _snapshot['liveCode'],
                      error: _snapshot['liveError'],
                      body: _snapshot['live'],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 12),
                    _HealthCard(
                      title: '/health/ready',
                      code: _snapshot['readyCode'],
                      error: _snapshot['readyError'],
                      body: _snapshot['ready'],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 12),
                    _HealthCard(
                      title: '/health',
                      code: _snapshot['rootCode'],
                      error: _snapshot['rootError'],
                      body: _snapshot['root'],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ML prediction API',
                      style: theme.textTheme.titleMedium?.copyWith(color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    _HealthCard(
                      title: ApiPaths.predictionHealth,
                      code: _predictionHealthy ? 200 : null,
                      error: _predictionHealthy ? null : 'No 200 response',
                      body: _predictionHealthy ? const {'ok': true} : null,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.title,
    required this.code,
    required this.error,
    required this.body,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String title;
  final Object? code;
  final Object? error;
  final Object? body;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                error == null ? Icons.dns : Icons.error_outline,
                color: error == null ? AppColors.primary : Colors.red,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (code != null)
                Chip(
                  label: Text('$code', style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text('$error', style: TextStyle(color: Colors.red[700], fontSize: 12)),
          ],
          if (body != null && error == null) ...[
            const SizedBox(height: 8),
            SelectableText(
              _prettyBody(body),
              style: theme.textTheme.bodySmall?.copyWith(
                color: textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _prettyBody(Object? body) {
    if (body == null) return '—';
    if (body is Map || body is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(body);
      } catch (_) {
        return body.toString();
      }
    }
    return body.toString();
  }
}
