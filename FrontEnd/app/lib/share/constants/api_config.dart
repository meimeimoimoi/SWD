import 'dart:io';

class ApiConfig {
  static const String envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final c = envBaseUrl.trim();
    if (c.isNotEmpty) {
      return c.endsWith('/') ? c.substring(0, c.length - 1) : c;
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5299';
    }
    return 'http://localhost:5299';
  }
}

abstract final class ApiPaths {
  static const authLogin = '/api/Auth/login';
  static const authRegister = '/api/Auth/register';
  static const authRefresh = '/api/Auth/refresh';
  static const authLogout = '/api/Auth/logout';

  static const userProfile = '/api/User/profile';
  static const userNotifications = '/api/User/notifications';
  static const userActivities = '/api/User/activities';
  static const userTrees = '/api/User/trees';
  static String predictionsHistoryAssignTree(int predictionId) =>
      '/api/predictions/history/$predictionId/tree';

  static const adminUsersRoot = '/api/Admin/users';

  static String adminUsersList({
    String? search,
    String? role,
    String sortBy = 'email',
    String sortOrder = 'asc',
  }) {
    final q = <String>[
      'sortBy=${Uri.encodeQueryComponent(sortBy)}',
      'sortOrder=${Uri.encodeQueryComponent(sortOrder)}',
    ];
    if (search != null && search.isNotEmpty) {
      q.add('search=${Uri.encodeQueryComponent(search)}');
    }
    if (role != null && role.isNotEmpty) {
      q.add('role=${Uri.encodeQueryComponent(role)}');
    }
    return '$adminUsersRoot?${q.join('&')}';
  }

  static String adminUser(int userId) => '$adminUsersRoot/$userId';
  static const adminUsersStaff = '/api/Admin/users/staff';
  static const adminPredictions = '/api/Admin/predictions';

  static const adminStats = '/api/admin/stats';
  static String adminPredictionStats({int days = 7}) =>
      '/api/admin/predictions/stats?days=$days';
  static const adminModelsAccuracy = '/api/admin/models/accuracy';
  static String adminRatings({int page = 1, int pageSize = 20}) =>
      '/api/admin/ratings?page=$page&pageSize=$pageSize';
  static String adminActivityLogs({int count = 50}) =>
      '/api/admin/activity-logs?count=$count';

  static const adminModels = '/api/admin/models';
  static String adminModelActive(int id) => '/api/admin/models/$id/active';

  static const adminDataStages = '/api/admin/data/stages';
  static String adminDataStage(int id) => '/api/admin/data/stages/$id';
  static String adminDataRelationships({int? treeId, int? illnessId}) {
    final q = <String>[];
    if (treeId != null) q.add('treeId=$treeId');
    if (illnessId != null) q.add('illnessId=$illnessId');
    if (q.isEmpty) return '/api/admin/data/relationships';
    return '/api/admin/data/relationships?${q.join('&')}';
  }

  static String adminDataRelationship(int id) =>
      '/api/admin/data/relationships/$id';

  static const imageUpload = '/api/ImageUpload/upload';
  static String imageUploadById(int uploadId) => '/api/ImageUpload/$uploadId';
  static const imageUploadMyImages = '/api/ImageUpload/my-images';

  static const predictionPredict = '/api/Prediction/predict';
  static const predictionModels = '/api/Prediction/models';
  static const predictionClasses = '/api/Prediction/classes';
  static const predictionHealth = '/api/Prediction/health';
  static String predictionCommonThreats({int take = 5}) =>
      '/api/Prediction/common-threats?take=$take';

  static String ratingPrediction(int predictionId) =>
      '/api/rating/prediction/$predictionId';
  static const ratingAll = '/api/rating/all';

  static const reviewTreatments = '/api/admin/review/treatments';
  static String reviewTreatment(int id) => '/api/admin/review/treatments/$id';
  static const reviewModels = '/api/admin/review/models';
  static String reviewModelActivate(int id) =>
      '/api/admin/review/models/$id/activate';
  static String reviewModelDeactivate(int id) =>
      '/api/admin/review/models/$id/deactivate';

  static const adminSettings = '/api/admin/settings';
  static String adminSettingKey(String key) =>
      '/api/admin/settings/${Uri.encodeComponent(key)}';

  static const technicianIllnesses = '/api/technician/illnesses';
  static String technicianIllness(int id) => '/api/technician/illnesses/$id';
  static String technicianIllnessAssignTree(int id) =>
      '/api/technician/illnesses/$id/assign-tree';
  static const technicianStages = '/api/technician/stages';
  static String technicianStage(int id) => '/api/technician/stages/$id';

  static String diseaseDetail(int id) => '/api/diseases/$id/detail';
  static const treatments = '/api/treatments';
  static String treatmentAssign(int id) => '/api/treatments/$id/assign';

  static const treatmentsRecommendationsPath = '/api/treatments/recommendations';

  static String treatmentsRecommendations({
    int? illnessId,
    int? illnessStageId,
    int? treeStageId,
  }) {
    final q = <String>[];
    if (illnessId != null) q.add('illnessId=$illnessId');
    if (illnessStageId != null) q.add('illnessStageId=$illnessStageId');
    if (treeStageId != null) q.add('treeStageId=$treeStageId');
    if (q.isEmpty) return treatmentsRecommendationsPath;
    return '$treatmentsRecommendationsPath?${q.join('&')}';
  }

  static String treatmentSolution(int id) => '/api/treatments/solutions/$id';
  static const treatmentsAiSuggest = '/api/treatments/ai-suggest';
  static const predictionsHistory = '/api/predictions/history';
  static String predictionsHistoryItem(int id) => '/api/predictions/history/$id';
}
