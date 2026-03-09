import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../share/services/prediction_service.dart';
import '../../share/utils/disease_mapper.dart';

/// Model for prediction result data
class PredictionResult {
  static const String _imageBaseUrl = 'http://10.0.2.2:5299';
  static const String _imagePathPrefix = '/uploads/images/';

  final String diseaseName;
  final String vietnameseName;
  final String scientificName;
  final String imageUrl;
  final double confidence;
  final String description;
  final String cause;
  final String impact;
  final List<TreatmentProduct> treatments;
  final bool isHealthy;

  const PredictionResult({
    required this.diseaseName,
    required this.vietnameseName,
    required this.scientificName,
    required this.imageUrl,
    required this.confidence,
    required this.description,
    required this.cause,
    required this.impact,
    required this.treatments,
    required this.isHealthy,
  });

  /// Create PredictionResult from API response
  static PredictionResult fromApiResponse(PredictionData data) {
    final englishName = data.diseaseName;
    final vietnameseName = DiseaseMapper.toVietnamese(englishName);
    final isHealthy = DiseaseMapper.isHealthy(englishName);
    final scientificName = DiseaseMapper.getScientificName(englishName);
    final imageUrl = _buildImageUrl(data.imageUrl);

    return PredictionResult(
      diseaseName: englishName,
      vietnameseName: vietnameseName,
      scientificName: scientificName,
      imageUrl: imageUrl,
      confidence: data.confidence,
      description: data.symptoms ?? 'Chưa có dữ liệu mô tả.',
      cause: data.causes ?? 'Chưa có thông tin.',
      impact: 'Chưa có thông tin tác động.',
      treatments: [], // Will be populated based on diagnosis
      isHealthy: isHealthy,
    );
  }

  static String _buildImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return imageUrl;
    final trimmed = imageUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final normalizedPath = trimmed.startsWith('/')
        ? trimmed.substring(1)
        : trimmed;
    return '$_imageBaseUrl$_imagePathPrefix$normalizedPath';
  }
}

/// Model for treatment product
class TreatmentProduct {
  final String name;
  final String imageUrl;
  final String badge;
  final String instruction;
  final String price;
  final bool isPrimary;

  const TreatmentProduct({
    required this.name,
    required this.imageUrl,
    required this.badge,
    required this.instruction,
    required this.price,
    this.isPrimary = false,
  });
}

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key, this.result});

  final PredictionResult? result;

  // Sample data for demonstration
  static const _sampleResult = PredictionResult(
    diseaseName: 'Leaf Blast',
    vietnameseName: 'Đạo ôn (cháy lá do nấm)',
    scientificName: 'Magnaporthe oryzae',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuA998KIbzaAWHJSTjnx-DfsJtgPMFNyeETxvOnpYgoua7rzPHly7c4NTeriJVTVkEJH_CjMXLxDMjzZxHXzgQKmmv-E_NzGBnWIPOn8_kVsF5a2eQ34JF-a-ZsFk9EU4DS78O1ZIp9y85lKfIPp6snaGQ_rpTjBuKD6_ngh-DPVUeIynJXCTN07eXgLJgGzepqSgf07FPym-d3zP_EGCU8_skAI4DWlvzYEaj8RIvEuwTiBRwv2XaNc0GdSayp2myoLHrmXx2YXzdY',
    confidence: 0.98,
    description:
        'Bệnh đốm lá do nấm gây ra, thường xuất hiện dưới dạng các đốm nhỏ màu nâu hoặc xám trên bề mặt lá. Nếu không được điều trị, các đốm này có thể lan rộng và làm héo lá, ảnh hưởng nghiêm trọng đến khả năng quang hợp của cây.',
    cause: 'Độ ẩm cao, nấm bào tử',
    impact: 'Giảm năng suất 15-30%',
    treatments: [],
    isHealthy: false,
  );

  @override
  Widget build(BuildContext context) {
    final data = result ?? _sampleResult;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF18181b)
          : const Color(0xFFF4F4F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroImage(context, data, isDark),
                    const SizedBox(height: 20),
                    _buildConfidenceCard(context, data, isDark),
                    const SizedBox(height: 20),
                    _buildDescriptionSection(context, data, isDark),
                    const SizedBox(height: 20),
                    _buildTreatmentSection(context, data, isDark),
                    const SizedBox(height: 16),
                    _buildActionButtons(context, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272a) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).maybePop(),
            isDark: isDark,
          ),
          Text(
            'Kết quả chẩn đoán',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          _buildCircleButton(
            icon: Icons.more_vert,
            onTap: () => _showOptionsMenu(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(
    BuildContext context,
    PredictionResult data,
    bool isDark,
  ) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with grayscale filter
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: Image.network(
              data.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: isDark
                      ? const Color(0xFF3F3F46)
                      : const Color(0xFFE5E7EB),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: isDark
                      ? const Color(0xFF3F3F46)
                      : const Color(0xFFE5E7EB),
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                );
              },
            ),
          ),
          // Brightness overlay
          Container(color: Colors.black.withOpacity(0.25)),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.vietnameseName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.scientificName,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(
    BuildContext context,
    PredictionResult data,
    bool isDark,
  ) {
    final confidencePercent = (data.confidence * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272a) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Độ tin cậy của AI',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '$confidencePercent%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: data.confidence,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFA1A1AA)
                      : const Color(0xFF52525B),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: isDark
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Độ chính xác rất cao dựa trên dữ liệu hiện có.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(
    BuildContext context,
    PredictionResult data,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description,
              color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF3F3F46),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Mô tả bệnh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          data.description,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: 'Nguyên nhân',
                content: data.cause,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                title: 'Ảnh hưởng',
                content: data.impact,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF27272a).withOpacity(0.5)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3F3F46).withOpacity(0.5)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentSection(
    BuildContext context,
    PredictionResult data,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.medical_services,
              color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF3F3F46),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Thuốc điều trị đề xuất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...data.treatments.map(
          (treatment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTreatmentCard(context, treatment, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentCard(
    BuildContext context,
    TreatmentProduct treatment,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272a) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: Image.network(
                treatment.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.medication,
                    size: 32,
                    color: isDark ? Colors.white38 : Colors.black26,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treatment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  treatment.badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: treatment.isPrimary
                        ? (isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF16A34A))
                        : (isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"${treatment.instruction}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      treatment.price,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    _buildDetailButton(
                      onTap: () => _showProductDetails(context, treatment),
                      isPrimary: treatment.isPrimary,
                      isDark: isDark,
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

  Widget _buildDetailButton({
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isDark,
  }) {
    return Material(
      color: isPrimary
          ? (isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A))
          : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'Chi tiết',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPrimary
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.save,
            label: 'Lưu lại',
            onTap: () => _onSave(context),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.feedback,
            label: 'Phản hồi',
            onTap: () => _onFeedback(context),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF27272a) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isDark
                    ? const Color(0xFFA1A1AA)
                    : const Color(0xFF52525B),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272a) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Trang chủ',
            onTap: () => _navigateToHome(context),
            isDark: isDark,
          ),
          // Camera button
          Transform.translate(
            offset: const Offset(0, -20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFE4E4E7)
                        : const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF18181b)
                          : const Color(0xFFF4F4F5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _navigateToScan(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Icon(
                        Icons.camera_alt,
                        color: isDark ? Colors.black : Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chụp ảnh',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF27272A),
                  ),
                ),
              ],
            ),
          ),
          _buildNavItem(
            icon: Icons.history,
            label: 'Lịch sử',
            onTap: () => _navigateToHistory(context),
            isDark: isDark,
          ),
          _buildNavItem(
            icon: Icons.person,
            label: 'Cá nhân',
            onTap: () => _navigateToProfile(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? (isDark ? Colors.white : const Color(0xFF27272A))
                    : (isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF)),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? (isDark ? Colors.white : const Color(0xFF27272A))
                      : (isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToHome(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  void _navigateToScan(BuildContext context) {
    Navigator.of(context).pushNamed('/scan');
  }

  void _navigateToHistory(BuildContext context) {
    // TODO: Implement history navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng lịch sử đang phát triển')),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).pushNamed('/profile');
  }

  // Action methods
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Chia sẻ kết quả'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Tải xuống báo cáo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement download
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Trợ giúp'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement help
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, TreatmentProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272a) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3F3F46)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isPrimary
                      ? (isDark
                            ? const Color(0xFF166534).withOpacity(0.3)
                            : const Color(0xFFDCFCE7))
                      : (isDark
                            ? const Color(0xFF3F3F46)
                            : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.badge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: product.isPrimary
                        ? (isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF16A34A))
                        : (isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hướng dẫn sử dụng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.instruction,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF4B5563),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giá tham khảo',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          product.price,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã thêm vào danh sách mua'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFFE4E4E7)
                          : const Color(0xFF27272A),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Mua ngay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSave(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu kết quả chẩn đoán'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onFeedback(BuildContext context) {
    Navigator.of(context).pushNamed(AppRouter.feedback);
  }

  Widget _buildFeedbackOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
