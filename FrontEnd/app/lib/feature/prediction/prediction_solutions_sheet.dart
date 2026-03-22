import 'package:flutter/material.dart';

import '../../share/services/treatment_api_service.dart';
import '../../share/theme/app_colors.dart';

/// Bottom sheet: load master-data recommendations or request AI/heuristic suggestion.
Future<void> showPredictionSolutionsSheet({
  required BuildContext context,
  required String displayName,
  required String diseaseName,
  required double confidence,
  required int predictionId,
  int? illnessId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PredictionSolutionsSheetContent(
      displayName: displayName,
      diseaseName: diseaseName,
      confidence: confidence,
      predictionId: predictionId,
      illnessId: illnessId,
    ),
  );
}

class _PredictionSolutionsSheetContent extends StatefulWidget {
  const _PredictionSolutionsSheetContent({
    required this.displayName,
    required this.diseaseName,
    required this.confidence,
    required this.predictionId,
    required this.illnessId,
  });

  final String displayName;
  final String diseaseName;
  final double confidence;
  final int predictionId;
  final int? illnessId;

  @override
  State<_PredictionSolutionsSheetContent> createState() =>
      _PredictionSolutionsSheetContentState();
}

class _PredictionSolutionsSheetContentState
    extends State<_PredictionSolutionsSheetContent> {
  final TreatmentApiService _api = TreatmentApiService();

  List<TreatmentRecommendationItem>? _catalog;
  bool _catalogLoading = false;
  String? _catalogError;

  bool _aiLoading = false;
  String? _aiError;
  AiSuggestResult? _aiResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkMuted : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Solutions for ${widget.displayName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.illnessId != null
                      ? 'Load rows from the treatment catalog, or generate an AI-assisted plan (uses an LLM on the server when configured).'
                      : 'This scan is not linked to a catalog illness id — AI can still use the disease name; catalog sync may be limited.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _catalogLoading ? null : _loadCatalog,
                        icon: _catalogLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.storage_outlined, size: 20),
                        label: Text(
                          _catalogLoading ? 'Loading…' : 'From master data',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _aiLoading ? null : _runAi,
                        icon: _aiLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 20),
                        label: Text(_aiLoading ? 'Analyzing…' : 'AI suggest'),
                      ),
                    ),
                  ],
                ),
              ),
              if (_catalogError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    _catalogError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              if (_aiError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    _aiError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (_catalog != null && _catalog!.isNotEmpty) ...[
                      Text(
                        'Catalog',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._catalog!.map(
                        (e) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              e.solutionName ?? 'Solution',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              [
                                if (e.solutionType != null &&
                                    e.solutionType!.isNotEmpty)
                                  e.solutionType!,
                                if (e.description != null &&
                                    e.description!.isNotEmpty)
                                  e.description!,
                              ].join('\n'),
                              style: theme.textTheme.bodySmall,
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      ),
                    ] else if (_catalog != null && _catalog!.isEmpty)
                      Text(
                        'No treatment rows in the database for this illness.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (_aiResult != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _aiResult!.source == 'openai'
                            ? 'AI-generated plan'
                            : 'Suggested plan (server heuristic)',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aiResult!.summary,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      ..._aiResult!.actionSteps.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF2D7B31),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  s,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _aiResult!.disclaimer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadCatalog() async {
    final id = widget.illnessId;
    if (id == null) {
      setState(() {
        _catalog = null;
        _catalogError =
            'No illness id on this prediction — try "AI suggest" or ensure the disease exists in the master list.';
      });
      return;
    }
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    final list = await _api.getRecommendationsForIllness(id);
    if (!mounted) return;
    setState(() {
      _catalogLoading = false;
      _catalog = list;
    });
  }

  Future<void> _runAi() async {
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    final res = await _api.requestAiSolutionSuggestion(
      illnessId: widget.illnessId,
      diseaseName: widget.diseaseName,
      confidence: widget.confidence,
      predictionId: widget.predictionId > 0 ? widget.predictionId : null,
    );
    if (!mounted) return;
    setState(() {
      _aiLoading = false;
      if (res == null) {
        _aiError =
            'Could not get a suggestion. Check your connection or sign in again.';
        _aiResult = null;
      } else {
        _aiResult = res;
      }
    });
  }
}
