import '../../share/services/history_service.dart';
import '../../share/utils/disease_mapper.dart';

enum TreeHealthLevel { healthy, low, medium, high }

class UserTreeSummary {
  const UserTreeSummary({
    required this.treeId,
    required this.displayName,
    required this.scientificName,
    required this.heroImageUrl,
    required this.health,
    required this.predictions,
  });

  final int? treeId;
  final String displayName;
  final String? scientificName;
  final String heroImageUrl;
  final TreeHealthLevel health;
  final List<HistoryItem> predictions;

  DateTime get latestScan {
    final dates = predictions.map((e) => e.createdAt);
    return dates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  int get scanCount => predictions.length;

  Set<int> get illnessIds => predictions
      .map((e) => e.illnessId)
      .whereType<int>()
      .toSet();

  static List<UserTreeSummary> fromHistory(List<HistoryItem> items) {
    if (items.isEmpty) return [];
    final groups = <String, List<HistoryItem>>{};
    for (final h in items) {
      final key = h.treeId != null ? 'id:${h.treeId}' : 'unassigned';
      groups.putIfAbsent(key, () => []).add(h);
    }
    final list = groups.values.map(_fromGroup).toList()
      ..sort((a, b) => b.latestScan.compareTo(a.latestScan));
    return list;
  }

  static UserTreeSummary _fromGroup(List<HistoryItem> raw) {
    final sorted = [...raw]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = sorted.first;
    final treeId = latest.treeId;
    String name = latest.treeName?.trim() ?? '';
    if (name.isEmpty) {
      name = treeId == null ? 'Unassigned plant' : 'Plant #$treeId';
    }
    final sci = latest.treeScientificName?.trim().isNotEmpty == true
        ? latest.treeScientificName
        : null;

    String hero = latest.treeImageUrl?.trim() ?? '';
    if (hero.isEmpty) {
      hero = latest.imageUrl;
    }

    return UserTreeSummary(
      treeId: treeId,
      displayName: name,
      scientificName: sci,
      heroImageUrl: hero,
      health: _healthForGroup(sorted),
      predictions: sorted,
    );
  }

  static bool _isHighRiskDisease(String diseaseName) {
    if (DiseaseMapper.isHealthy(diseaseName)) return false;
    switch (diseaseName) {
      case 'Leaf Blast':
      case 'Bacterial Leaf Blight':
        return true;
      default:
        return false;
    }
  }

  static TreeHealthLevel _healthForGroup(List<HistoryItem> sorted) {
    for (final p in sorted) {
      if (DiseaseMapper.isHealthy(p.diseaseName)) continue;
      final sev = (p.illnessSeverity ?? '').toLowerCase();
      if (sev.contains('cao') ||
          sev.contains('high') ||
          sev.contains('nặng') ||
          sev.contains('severe') ||
          _isHighRiskDisease(p.diseaseName)) {
        return TreeHealthLevel.high;
      }
    }
    for (final p in sorted) {
      if (DiseaseMapper.isHealthy(p.diseaseName)) continue;
      final sev = (p.illnessSeverity ?? '').toLowerCase();
      if (sev.contains('trung') || sev.contains('medium') || sev.contains('moderate')) {
        return TreeHealthLevel.medium;
      }
    }
    for (final p in sorted) {
      if (!DiseaseMapper.isHealthy(p.diseaseName)) {
        return TreeHealthLevel.low;
      }
    }
    return TreeHealthLevel.healthy;
  }

  bool get hasConcern =>
      predictions.any((p) => !DiseaseMapper.isHealthy(p.diseaseName));

  bool matchesFilter(TreeListFilter f) {
    switch (f) {
      case TreeListFilter.all:
        return true;
      case TreeListFilter.concern:
        return hasConcern;
      case TreeListFilter.healthy:
        return !hasConcern;
    }
  }
}

enum TreeListFilter { all, concern, healthy }

extension TreeListFilterLabel on TreeListFilter {
  String get label {
    switch (this) {
      case TreeListFilter.all:
        return 'All';
      case TreeListFilter.concern:
        return 'Needs attention';
      case TreeListFilter.healthy:
        return 'Healthy';
    }
  }
}
