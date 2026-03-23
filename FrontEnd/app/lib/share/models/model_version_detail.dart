class PredictedClassCount {
  final String className;
  final int count;

  PredictedClassCount({required this.className, required this.count});

  factory PredictedClassCount.fromJson(Map<String, dynamic> json) {
    return PredictedClassCount(
      className: json['className']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ModelVersionDetail {
  final int modelVersionId;
  final String modelName;
  final String version;
  final String? modelType;
  final String? description;
  final bool? isActive;
  final bool? isDefault;
  final DateTime? createdAt;
  final String? relativeFilePath;

  final int totalPredictions;
  final int predictionsToday;
  final int predictionsLast7Days;
  final double averageConfidence;
  final int totalRatings;
  final int positiveRatings;
  final double positiveRatingRate;
  final List<PredictedClassCount> topPredictedClasses;

  final bool fileExists;
  final String? absolutePath;
  final int? fileSizeBytes;
  final DateTime? fileLastModifiedUtc;

  final String? onnxProducerName;
  final String? onnxGraphName;
  final String? onnxDomain;
  final int? onnxModelVersion;
  final List<String> onnxInputNames;
  final List<String> onnxOutputNames;
  final Map<String, String> onnxInputShapeDescriptions;
  final Map<String, String> onnxOutputShapeDescriptions;
  final int? onnxClassLabelCount;
  final List<String> onnxClassLabelsSample;
  final String? onnxMetadataError;
  final String? onnxClassLabelsError;

  final bool isCurrentInferenceModel;
  final int? currentlyLoadedModelVersionId;

  ModelVersionDetail({
    required this.modelVersionId,
    required this.modelName,
    required this.version,
    this.modelType,
    this.description,
    this.isActive,
    this.isDefault,
    this.createdAt,
    this.relativeFilePath,
    required this.totalPredictions,
    required this.predictionsToday,
    required this.predictionsLast7Days,
    required this.averageConfidence,
    required this.totalRatings,
    required this.positiveRatings,
    required this.positiveRatingRate,
    required this.topPredictedClasses,
    required this.fileExists,
    this.absolutePath,
    this.fileSizeBytes,
    this.fileLastModifiedUtc,
    this.onnxProducerName,
    this.onnxGraphName,
    this.onnxDomain,
    this.onnxModelVersion,
    required this.onnxInputNames,
    required this.onnxOutputNames,
    required this.onnxInputShapeDescriptions,
    required this.onnxOutputShapeDescriptions,
    this.onnxClassLabelCount,
    required this.onnxClassLabelsSample,
    this.onnxMetadataError,
    this.onnxClassLabelsError,
    required this.isCurrentInferenceModel,
    this.currentlyLoadedModelVersionId,
  });

  static Map<String, String> _stringMap(dynamic v) {
    if (v == null) return {};
    if (v is! Map) return {};
    return v.map((k, e) => MapEntry('$k', '${e ?? ''}'));
  }

  static List<String> _stringList(dynamic v) {
    if (v == null) return [];
    if (v is! List) return [];
    return v.map((e) => e.toString()).toList();
  }

  factory ModelVersionDetail.fromJson(Map<String, dynamic> json) {
    final top = json['topPredictedClasses'];
    final classes = top is List
        ? top
            .whereType<Map>()
            .map((e) => PredictedClassCount.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PredictedClassCount>[];

    return ModelVersionDetail(
      modelVersionId: (json['modelVersionId'] as num?)?.toInt() ?? 0,
      modelName: json['modelName']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      modelType: json['modelType']?.toString(),
      description: json['description']?.toString(),
      isActive: json['isActive'] as bool?,
      isDefault: json['isDefault'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      relativeFilePath: json['relativeFilePath']?.toString(),
      totalPredictions: (json['totalPredictions'] as num?)?.toInt() ?? 0,
      predictionsToday: (json['predictionsToday'] as num?)?.toInt() ?? 0,
      predictionsLast7Days:
          (json['predictionsLast7Days'] as num?)?.toInt() ?? 0,
      averageConfidence:
          (json['averageConfidence'] as num?)?.toDouble() ?? 0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      positiveRatings: (json['positiveRatings'] as num?)?.toInt() ?? 0,
      positiveRatingRate:
          (json['positiveRatingRate'] as num?)?.toDouble() ?? 0,
      topPredictedClasses: classes,
      fileExists: json['fileExists'] == true,
      absolutePath: json['absolutePath']?.toString(),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      fileLastModifiedUtc: json['fileLastModifiedUtc'] != null
          ? DateTime.tryParse(json['fileLastModifiedUtc'].toString())
          : null,
      onnxProducerName: json['onnxProducerName']?.toString(),
      onnxGraphName: json['onnxGraphName']?.toString(),
      onnxDomain: json['onnxDomain']?.toString(),
      onnxModelVersion: (json['onnxModelVersion'] as num?)?.toInt(),
      onnxInputNames: _stringList(json['onnxInputNames']),
      onnxOutputNames: _stringList(json['onnxOutputNames']),
      onnxInputShapeDescriptions:
          _stringMap(json['onnxInputShapeDescriptions']),
      onnxOutputShapeDescriptions:
          _stringMap(json['onnxOutputShapeDescriptions']),
      onnxClassLabelCount: (json['onnxClassLabelCount'] as num?)?.toInt(),
      onnxClassLabelsSample: _stringList(json['onnxClassLabelsSample']),
      onnxMetadataError: json['onnxMetadataError']?.toString(),
      onnxClassLabelsError: json['onnxClassLabelsError']?.toString(),
      isCurrentInferenceModel: json['isCurrentInferenceModel'] == true,
      currentlyLoadedModelVersionId:
          (json['currentlyLoadedModelVersionId'] as num?)?.toInt(),
    );
  }

  String get fileSizeHuman {
    final b = fileSizeBytes;
    if (b == null) return '—';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
