import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../share/services/history_service.dart';
import '../../share/services/prediction_service.dart';
import '../../share/services/storage_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/utils/disease_mapper.dart';
import '../../share/widgets/user_bottom_nav_bar.dart';

class PredictionResult {
  static const String _imageBaseUrl = 'http://10.0.2.2:5299';
  static const String _imagePathPrefix = '/uploads/images/';

  final int predictionId;
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
      diseaseName: englishName,
      displayName: displayName,
      scientificName: scientificName,
      imageUrl: imageUrl,
      confidence: data.confidence,
      description: data.symptoms ?? 'No description available.',
      cause: data.causes ?? 'No information available.',
      symptoms: data.symptoms ?? 'No symptom information available.',
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
      diseaseName: d,
      displayName: DiseaseMapper.toDisplayName(d),
      scientificName:
          (sci != null && sci.isNotEmpty) ? sci : DiseaseMapper.getScientificName(d),
      imageUrl: item.imageUrl,
      confidence: item.confidence,
      description: _nonEmpty(item.illnessDescription) ??
          _nonEmpty(item.symptoms) ??
          'No description available.',
      cause: _nonEmpty(item.causes) ?? 'No information available.',
      symptoms: _nonEmpty(item.symptoms) ?? 'No symptom information available.',
      impact: DiseaseMapper.getImpact(d),
      treatments: const [],
      medicines: const [],
      isHealthy: DiseaseMapper.isHealthy(d),
    );
  }

  static String? _nonEmpty(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  static List<TreatmentProduct> _mapTreatments(List<dynamic> items) {
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      final type = (map['type'] ?? '') as String;
      final isMedicine = type == 'medicine';
      return TreatmentProduct(
        name: (map['name'] ?? '') as String,
        imageUrl: '',
        badge: isMedicine ? 'Medicine' : 'Care',
        instruction: (map['description'] ?? '') as String,
        price: '',
        isPrimary: isMedicine,
      );
    }).toList();
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

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key, this.result});

  final PredictionResult? result;

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  int _selectedTab = 0;
  bool _showAiConfidence = false;

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
    diseaseName: 'Leaf Blast',
    displayName: 'Rice blast (fungal leaf blight)',
    scientificName: 'Magnaporthe oryzae',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuA998KIbzaAWHJSTjnx-DfsJtgPMFNyeETxvOnpYgoua7rzPHly7c4NTeriJVTVkEJH_CjMXLxDMjzZxHXzgQKmmv-E_NzGBnWIPOn8_kVsF5a2eQ34JF-a-ZsFk9EU4DS78O1ZIp9y85lKfIPp6snaGQ_rpTjBuKD6_ngh-DPVUeIynJXCTN07eXgLJgGzepqSgf07FPym-d3zP_EGCU8_skAI4DWlvzYEaj8RIvEuwTiBRwv2XaNc0GdSayp2myoLHrmXx2YXzdY',
    confidence: 0.98,
    description:
        'A fungal leaf spot disease that appears as small brown or gray spots on leaf surfaces. Without treatment, spots can spread, wilt leaves, and seriously reduce photosynthesis.',
    cause: 'High humidity, fungal spores',
    symptoms: 'Leaf spots, wilting, yield loss',
    impact: 'Yield reduction 15–30%',
    treatments: [],
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
      bottomNavigationBar:
          const UserBottomNavBar(selectedIndexOverride: 1),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
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
            'Diagnosis result',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF111827),
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
      color: isDark ? AppColors.darkControlFill : const Color(0xFFF3F4F6),
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
                'AI confidence',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '$confidencePercent%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkControlFill : const Color(0xFFE5E7EB),
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
                  'Very high accuracy based on current data.',
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
              'Disease description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF111827),
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
                title: 'Cause',
                content: data.cause,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                title: 'Impact',
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
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF6B7280),
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
              'Treatment suggestions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF111827),
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
              _buildTabItem(title: 'Care', index: 0, isDark: isDark),
              const SizedBox(width: 4),
              _buildTabItem(title: 'Medicine', index: 1, isDark: isDark),
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
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                        ? 'No care suggestions yet.'
                        : 'No medicine suggestions yet.',
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
              color: isDark ? AppColors.darkControlFill : const Color(0xFFF3F4F6),
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
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF111827),
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
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF111827),
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
            'Details',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPrimary
                  ? (isDark ? Colors.black : AppColors.onPrimary)
                  : (isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937)),
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
                    const SnackBar(content: Text('Scan linked to plant.')),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2D7B31).withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.park_outlined, color: Color(0xFF2D7B31)),
                    const SizedBox(width: 8),
                    Text(
                      'ASSIGN TO PLANT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark
                            ? const Color(0xFFA4F69C)
                            : const Color(0xFF2D7B31),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.save,
                label: 'Save',
                onTap: () => _onSave(context),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.feedback,
                label: 'Feedback',
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
              color: isDark ? AppColors.darkControlFill : const Color(0xFFE5E7EB),
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
              title: const Text('Share result'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download report'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help'),
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
                              product.badge,
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
                            'Description',
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

                          if (product.isPrimary) ...[
                            const SizedBox(height: 24),

                            Text(
                              'Ingredients',
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
                              'Detailed ingredients for this product are not available yet.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFFE4E4E7)
                            : const Color(0xFF27272A),
                        foregroundColor:
                            isDark ? Colors.black : AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
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
        content: Text('Diagnosis result saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onFeedback(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRouter.feedback,
      arguments: widget.result ?? _sampleResult,
    );
  }
}
