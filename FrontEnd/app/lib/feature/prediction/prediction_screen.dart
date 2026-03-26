import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/app_router.dart';
import '../../share/constants/api_config.dart';
import '../../share/services/history_service.dart';
import '../../share/services/prediction_service.dart';
import '../../share/services/storage_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/services/cart_api_service.dart';
import '../../share/utils/disease_mapper.dart';
import '../../share/widgets/user_bottom_nav_bar.dart';
import 'prediction_solutions_sheet.dart';

class PredictionResult {
  final int predictionId;
  final int? illnessId;
  final String diseaseName;
  final String displayName;
  final String scientificName;
  final String imageUrl;
  final double confidence;
  final String description;
  final String cause;
  final String symptoms;
  final String impact;
  final List<TreatmentProduct> treatments;
  final List<TreatmentProduct> medicines;
  final bool isHealthy;

  const PredictionResult({
    required this.predictionId,
    this.illnessId,
    required this.diseaseName,
    required this.displayName,
    required this.scientificName,
    required this.imageUrl,
    required this.confidence,
    required this.description,
    required this.cause,
    required this.symptoms,
    required this.impact,
    required this.treatments,
    required this.medicines,
    required this.isHealthy,
  });

  static PredictionResult fromApiResponse(PredictionData data) {
    final englishName = data.diseaseName;
    final displayName = DiseaseMapper.toDisplayName(englishName);
    final isHealthy = DiseaseMapper.isHealthy(englishName);
    final scientificName = DiseaseMapper.getScientificName(englishName);
    final imageUrl = _buildImageUrl(data.imageUrl);

    return PredictionResult(
      predictionId: data.predictionId,
      illnessId: data.illnessId,
      diseaseName: englishName,
      displayName: displayName,
      scientificName: scientificName,
      imageUrl: imageUrl,
      confidence: data.confidence,
      description: data.symptoms ?? 'Chưa có mô tả.',
      cause: data.causes ?? 'Chưa có thông tin.',
      symptoms: data.symptoms ?? 'Chưa có thông tin triệu chứng.',
      impact: DiseaseMapper.getImpact(englishName),
      treatments: _mapTreatments(data.treatments),
      medicines: _mapTreatments(data.medicines),
      isHealthy: isHealthy,
    );
  }

  static PredictionResult fromHistoryItem(HistoryItem item) {
    final d = item.diseaseName;
    final sci = item.scientificName?.trim();
    return PredictionResult(
      predictionId: item.predictionId,
      illnessId: item.illnessId,
      diseaseName: d,
      displayName: DiseaseMapper.toDisplayName(d),
      scientificName: (sci != null && sci.isNotEmpty)
          ? sci
          : DiseaseMapper.getScientificName(d),
      imageUrl: item.imageUrl,
      confidence: item.confidence,
      description:
          _nonEmpty(item.illnessDescription) ??
          _nonEmpty(item.symptoms) ??
          'Chưa có mô tả.',
      cause: _nonEmpty(item.causes) ?? 'Chưa có thông tin.',
      symptoms: _nonEmpty(item.symptoms) ?? 'Chưa có thông tin triệu chứng.',
      impact: DiseaseMapper.getImpact(d),
      treatments: _mapTreatments(item.treatments),
      medicines: _mapTreatments(item.medicines),
      isHealthy: DiseaseMapper.isHealthy(d),
    );
  }

  static String? _nonEmpty(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  static List<String> _parseIngredients(dynamic v) {
    if (v == null) return [];
    if (v is String) {
      return v
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  static List<TreatmentProduct> _mapTreatments(List<dynamic> items) {
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      final type = ((map['type'] ?? '') as String).toLowerCase();
      final isMedicine = type == 'medicine';
      final ingredients = _parseIngredients(
        map['ingredients'] ?? map['composition'] ?? map['components'],
      );
      final rawUrl =
          map['shopeeUrl'] ??
          map['shopee_url'] ??
          map['shopeeLink'] ??
          map['shopee_link'] ??
          map['link'] ??
          map['url'];
      String? shopeeUrl;
      if (rawUrl != null) {
        final s = rawUrl.toString().trim();
        if (s.isNotEmpty) shopeeUrl = s;
      }
      // Collect images: prefer explicit images list, else fallback to single imageUrl
      List<String> imagesList = [];
      try {
        if (map['images'] is List && (map['images'] as List).isNotEmpty) {
          for (final it in (map['images'] as List)) {
            if (it is Map) {
              final f = it['imageUrl'] ?? it['ImageUrl'];
              if (f != null) imagesList.add(_buildImageUrl(f.toString()));
            } else if (it is String) {
              imagesList.add(_buildImageUrl(it));
            }
          }
        } else {
          final direct = map['imageUrl'] ?? map['ImageUrl'];
          if (direct != null && direct.toString().trim().isNotEmpty) {
            imagesList.add(_buildImageUrl(direct.toString()));
          }
        }
      } catch (_) {}

      final firstImage = imagesList.isNotEmpty ? imagesList.first : '';

      return TreatmentProduct(
        solutionId:
            (map['solutionId'] as num?)?.toInt() ??
            (map['id'] as num?)?.toInt(),
        name: (map['name'] ?? '') as String,
        imageUrl: firstImage,
        badge: isMedicine ? 'Medicine' : 'Care',
        instruction: (map['description'] ?? '') as String,
        price: (map['price'] ?? '') as String,
        isPrimary: isMedicine,
        shopeeUrl: shopeeUrl,
        ingredients: ingredients,
        images: imagesList,
      );
    }).toList();
  }

  static String _buildImageUrl(String imageUrl) =>
      ApiConfig.resolveMediaUrl(imageUrl);
}

class TreatmentProduct {
  final int? solutionId;
  final String name;
  final String imageUrl;
  final List<String> images;
  final String badge;
  final String instruction;
  final String price;
  final bool isPrimary;
  final String? shopeeUrl;
  final List<String> ingredients;

  const TreatmentProduct({
    this.solutionId,
    required this.name,
    required this.imageUrl,
    this.images = const [],
    required this.badge,
    required this.instruction,
    required this.price,
    this.isPrimary = false,
    this.shopeeUrl,
    this.ingredients = const [],
  });
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key, this.result});

  final PredictionResult? result;

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  int _selectedTab = 0;
  bool _showAiConfidence = false;
  final Map<int, int> _productImageIndex = {};

  @override
  void initState() {
    super.initState();
    StorageService.getRole().then((r) {
      if (!mounted) return;
      final role = r?.trim().toLowerCase() ?? '';
      final staff = role == 'admin' || role == 'technician';
      setState(() => _showAiConfidence = staff);
    });
  }

  static const _sampleResult = PredictionResult(
    predictionId: 0,
    illnessId: null,
    diseaseName: 'Bệnh cháy lá',
    displayName: 'Bệnh nấm lá lúa (Rice blast)',
    scientificName: 'Magnaporthe oryzae',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuA998KIbzaAWHJSTjnx-DfsJtgPMFNyeETxvOnpYgoua7rzPHly7c4NTeriJVTVkEJH_CjMXLxDMjzZxHXzgQKmmv-E_NzGBnWIPOn8_kVsF5a2eQ34JF-a-ZsFk9EU4DS78O1ZIp9y85lKfIPp6snaGQ_rpTjBuKD6_ngh-DPVUeIynJXCTN07eXgLJgGzepqSgf07FPym-d3zP_EGCU8_skAI4DWlvzYEaj8RIvEuwTiBRwv2XaNc0GdSayp2myoLHrmXx2YXzdY',
    confidence: 0.98,
    description:
        'Bệnh do nấm xuất hiện dưới dạng các đốm nâu hoặc xám nhỏ trên bề mặt lá. Nếu không điều trị, đốm có thể lan rộng, làm lá héo và giảm khả năng quang hợp.',
    cause: 'Độ ẩm cao, bào tử nấm',
    symptoms: 'Đốm lá, lá héo, giảm năng suất',
    impact: 'Giảm sản lượng 15–30%',
    treatments: [
      TreatmentProduct(
        name: 'Thuốc trừ nấm mẫu',
        imageUrl: 'https://cf.shopee.vn/file/sg-11134201-22100-2v7w7w7w7w7w7w',
        badge: 'Care',
        instruction: 'Phun đều lên lá theo hướng dẫn.',
        price: '120.000đ',
        isPrimary: false,
        shopeeUrl: 'https://vn.shp.ee/fbqWu29a',
      ),
    ],
    medicines: [],
    isHealthy: false,
  );

  @override
  Widget build(BuildContext context) {
    final data = widget.result ?? _sampleResult;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
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
                    if (_showAiConfidence) ...[
                      _buildConfidenceCard(context, data, isDark),
                      const SizedBox(height: 20),
                    ],
                    _buildDescriptionSection(context, data, isDark),
                    const SizedBox(height: 20),
                    _buildTreatmentSection(context, data, isDark),
                    const SizedBox(height: 16),
                    _buildActionButtons(context, data, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const UserBottomNavBar(selectedIndexOverride: 1),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    // This header is just a placeholder. Replace with your actual header widget.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
              size: 22,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
              size: 22,
            ),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
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
                      ? AppColors.darkControlFill
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
                      ? AppColors.darkControlFill
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
          Container(color: Colors.black.withOpacity(0.25)),
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
                  data.displayName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.diseaseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.onPrimary.withOpacity(0.75),
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
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkControlFill : const Color(0xFFE5E7EB),
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
                'Độ tin cậy AI',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '$confidencePercent%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkControlFill
                  : const Color(0xFFE5E7EB),
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
                  'Độ chính xác rất cao dựa trên dữ liệu hiện tại.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
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
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF111827),
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
                title: 'Tác động',
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
            ? AppColors.surfaceDark.withOpacity(0.5)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkControlFill.withOpacity(0.5)
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
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF6B7280),
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
              'Gợi ý điều trị',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : const Color(0xFFF3F4F6).withOpacity(0.6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _buildTabItem(title: 'Chăm sóc', index: 0, isDark: isDark),
              const SizedBox(width: 4),
              _buildTabItem(title: 'Thuốc', index: 1, isDark: isDark),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final items = _selectedTab == 0 ? data.treatments : data.medicines;
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkControlFill
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Center(
                  child: Text(
                    _selectedTab == 0
                        ? 'Chưa có gợi ý chăm sóc.'
                        : 'Chưa có gợi ý thuốc.',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: items
                  .map(
                    (treatment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTreatmentCard(context, treatment, isDark),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabItem({
    required String title,
    required int index,
    required bool isDark,
  }) {
    final bool isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFFE4E4E7) : AppColors.surfaceLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: Text(
              title,
              key: ValueKey(isSelected),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDark ? Colors.black : const Color(0xFF111827))
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF6B7280)),
              ),
            ),
          ),
        ),
      ),
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
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkControlFill : const Color(0xFFE5E7EB),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkControlFill
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Builder(
              builder: (context) {
                final images = treatment.images.isNotEmpty
                    ? treatment.images
                    : (treatment.imageUrl.isNotEmpty
                          ? [treatment.imageUrl]
                          : []);
                final keyId = (treatment.solutionId ?? treatment.name.hashCode)
                    .abs();
                final currentIndex = _productImageIndex[keyId] ?? 0;

                if (images.isEmpty) {
                  return Icon(
                    Icons.medication,
                    size: 32,
                    color: isDark ? Colors.white38 : Colors.black26,
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (idx) {
                        setState(() => _productImageIndex[keyId] = idx);
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.broken_image,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        );
                      },
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (i) {
                            final active = i == currentIndex;
                            return Container(
                              width: active ? 8 : 6,
                              height: active ? 8 : 6,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: active ? Colors.white : Colors.white54,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 16),
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
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),

                const SizedBox(height: 6),
                Text(
                  '"${treatment.instruction}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.textSecondaryDark
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
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF111827),
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
          : (isDark ? AppColors.darkControlFill : const Color(0xFFE5E7EB)),
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
                  ? (isDark ? Colors.black : AppColors.onPrimary)
                  : (isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF1F2937)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    PredictionResult data,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.predictionId > 0) ...[
          Material(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                final ok = await Navigator.pushNamed(
                  context,
                  AppRouter.predictionAssignTree,
                  arguments: data,
                );
                if (!context.mounted) return;
                if (ok == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gán vào cây.')),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.brandAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.park_outlined,
                      color: AppColors.brandAccentReadable(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GÁN VÀO CÂY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.brandAccentReadable(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Material(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              showPredictionSolutionsSheet(
                context: context,
                displayName: data.displayName,
                diseaseName: data.diseaseName,
                confidence: data.confidence,
                predictionId: data.predictionId,
                illnessId: data.illnessId,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brandAccent.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.healing_outlined,
                    color: isDark
                        ? AppColors.brandAccentOnDark
                        : AppColors.brandAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GỢI Ý GIẢI PHÁP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark
                          ? AppColors.brandAccentOnDark
                          : AppColors.brandAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.save,
                label: 'Lưu',
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
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.darkControlFill
                  : const Color(0xFFE5E7EB),
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Tải báo cáo'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Trợ giúp'),
              onTap: () {
                Navigator.pop(context);
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
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkControlFill
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product.imageUrl.isNotEmpty
                                ? Image.network(
                                    product.imageUrl,
                                    height: 220,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 220,
                                        color: isDark
                                            ? AppColors.darkControlFill
                                            : AppColors.surfaceLight,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 56,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black26,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 220,
                                    color: isDark
                                        ? AppColors.darkControlFill
                                        : AppColors.surfaceLight,
                                    child: Icon(
                                      Icons.image,
                                      size: 56,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black26,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : const Color(0xFF111827),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.isPrimary
                                  ? (isDark
                                        ? const Color(
                                            0xFF166534,
                                          ).withOpacity(0.3)
                                        : const Color(0xFFDCFCE7))
                                  : (isDark
                                        ? AppColors.darkControlFill
                                        : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.badge == 'Care'
                                  ? 'Chăm sóc'
                                  : (product.badge == 'Medicine'
                                        ? 'Thuốc'
                                        : product.badge),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: product.isPrimary
                                    ? (isDark
                                          ? const Color(0xFF4ADE80)
                                          : const Color(0xFF16A34A))
                                    : (isDark
                                          ? AppColors.textSecondaryDark
                                          : const Color(0xFF6B7280)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            'Mô tả',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : const Color(0xFF111827),
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

                          const SizedBox(height: 16),

                          Text(
                            'Thành phần',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : const Color(0xFF111827),
                            ),
                          ),

                          const SizedBox(height: 8),

                          if (product.ingredients.isNotEmpty) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: product.ingredients
                                  .map(
                                    (i) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              top: 6,
                                              right: 8,
                                            ),
                                            child: Icon(Icons.circle, size: 8),
                                          ),
                                          Expanded(
                                            child: Text(
                                              i,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark
                                                    ? const Color(0xFFD1D5DB)
                                                    : const Color(0xFF4B5563),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ] else ...[
                            Text(
                              'Không có thông tin thành phần',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFFD1D5DB)
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Cart icon button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            final solutionId = product.solutionId;
                            if (solutionId == null || solutionId == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Không có mã sản phẩm'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            final api = CartApiService();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang thêm vào giỏ...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            final ok = await api.addToCart(
                              solutionId: solutionId,
                              quantity: 1,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Đã thêm vào giỏ hàng'
                                      : 'Thêm vào giỏ thất bại',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFE4E4E7),
                            foregroundColor: isDark
                                ? Colors.white
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Icon(Icons.shopping_cart_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Buy button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              final url = product.shopeeUrl;
                              if (url == null || url.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Link mua hàng không có'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final uri = Uri.tryParse(url);
                              if (uri == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Link không hợp lệ'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              try {
                                final launched = await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                                if (!launched) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Không thể mở link'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lỗi khi mở link'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF22C55E,
                              ), // Green highlight
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Mua',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
    Navigator.of(
      context,
    ).pushNamed(AppRouter.feedback, arguments: widget.result ?? _sampleResult);
  }
}
