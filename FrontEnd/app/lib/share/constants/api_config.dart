import 'dart:io';

/// Base URL and path constants aligned with [FrontEnd/.api/api.json].
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

/// OpenAPI paths (no trailing slashes).
abstract final class ApiPaths {
  // Auth
  static const authLogin = '/api/Auth/login';
  static const authRegister = '/api/Auth/register';
  static const authRefresh = '/api/Auth/refresh';
  static const authLogout = '/api/Auth/logout';

  // User
  static const userProfile = '/api/User/profile';
  static const userNotifications = '/api/User/notifications';
  static const userActivities = '/api/User/activities';

  // Admin
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

  // Dashboard (lowercase admin)
  static const adminStats = '/api/admin/stats';
  static String adminPredictionStats({int days = 7}) =>
      '/api/admin/predictions/stats?days=$days';
  static const adminModelsAccuracy = '/api/admin/models/accuracy';
  static String adminRatings({int page = 1, int pageSize = 20}) =>
      '/api/admin/ratings?page=$page&pageSize=$pageSize';
  static String adminActivityLogs({int count = 50}) =>
      '/api/admin/activity-logs?count=$count';

  // Models
  static const adminModels = '/api/admin/models';
  static String adminModelActive(int id) => '/api/admin/models/$id/active';

  // Data management
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

  // Image upload
  static const imageUpload = '/api/ImageUpload/upload';
  static String imageUploadById(int uploadId) => '/api/ImageUpload/$uploadId';
  static const imageUploadMyImages = '/api/ImageUpload/my-images';

  // Prediction
  static const predictionPredict = '/api/Prediction/predict';
  static const predictionClasses = '/api/Prediction/classes';
  static const predictionHealth = '/api/Prediction/health';

  // Rating
  static String ratingPrediction(int predictionId) =>
      '/api/rating/prediction/$predictionId';
  static const ratingAll = '/api/rating/all';

  // Review
  static const reviewTreatments = '/api/admin/review/treatments';
  static String reviewTreatment(int id) => '/api/admin/review/treatments/$id';
  static const reviewModels = '/api/admin/review/models';
  static String reviewModelActivate(int id) =>
      '/api/admin/review/models/$id/activate';
  static String reviewModelDeactivate(int id) =>
      '/api/admin/review/models/$id/deactivate';

  // Settings
  static const adminSettings = '/api/admin/settings';
  static String adminSettingKey(String key) =>
      '/api/admin/settings/${Uri.encodeComponent(key)}';

  // Technician
  static const technicianIllnesses = '/api/technician/illnesses';
  static String technicianIllness(int id) => '/api/technician/illnesses/$id';
  static String technicianIllnessAssignTree(int id) =>
      '/api/technician/illnesses/$id/assign-tree';
  static const technicianStages = '/api/technician/stages';
  static String technicianStage(int id) => '/api/technician/stages/$id';

  // Treatment / diseases
  static String diseaseDetail(int id) => '/api/diseases/$id/detail';
  static const treatments = '/api/treatments';
  static String treatmentAssign(int id) => '/api/treatments/$id/assign';

  // User-facing treatments & history
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
  static const predictionsHistory = '/api/predictions/history';
  static String predictionsHistoryItem(int id) => '/api/predictions/history/$id';
}
