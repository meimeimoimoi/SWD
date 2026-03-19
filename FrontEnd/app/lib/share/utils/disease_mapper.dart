/// Utility class to map disease names between English and Vietnamese
class DiseaseMapper {
  static const Map<String, String> _englishToVietnamese = {
    'Leaf Blast': 'Đạo ôn (cháy lá do nấm)',
    'Bacterial Leaf Blight': 'Bạc lá (cháy bìa lá do vi khuẩn)',
    'Brown Spot': 'Đốm nâu',
    'Healthy Rice Leaf': 'Lá gạo khỏe',
  };

  static const Map<String, String> _impactMapping = {
    'Leaf Blast':
        'Làm giảm năng suất ~10–30%, bùng phát nặng có thể 40–50% Làm giảm năng suất ~20–50%, nặng có thể hơn 70%',
    'Bacterial Leaf Blight': ' Làm giảm năng suất ~20–50%, nặng có thể hơn 70%',
    'Brown Spot': 'Thường giảm năng suất ~5–20%.',
    'Healthy Rice Leaf': 'Không ảnh hưởng, năng suất bình thường',
  };

  /// Convert English disease name to Vietnamese
  static String toVietnamese(String englishName) {
    return _englishToVietnamese[englishName] ?? englishName;
  }

  /// Check if it's a healthy condition
  static bool isHealthy(String diseaseName) {
    return diseaseName.toLowerCase().contains('healthy');
  }

  /// Get scientific name based on disease name
  static String getScientificName(String englishDiseaseName) {
    const Map<String, String> scientificNames = {
      'Leaf Blast': 'Magnaporthe oryzae',
      'Bacterial Leaf Blight': 'Xanthomonas oryzae pv. oryzae',
      'Brown Spot': 'Bipolaris oryzae',
      'Healthy Rice Leaf': 'N/A',
    };
    return scientificNames[englishDiseaseName] ?? 'Unknown';
  }

  static String getImpact(String englishDiseaseName) {
    const Map<String, String> _impactMapping = {
      'Leaf Blast': 'Làm giảm năng suất ~10–30%, bùng phát nặng có thể 40–50% ',
      'Bacterial Leaf Blight':
          ' Làm giảm năng suất ~20–50%, nặng có thể hơn 70%',
      'Brown Spot': 'Thường giảm năng suất ~5–20%.',
      'Healthy Rice Leaf': 'Không ảnh hưởng, năng suất bình thường',
    };
    return _impactMapping[englishDiseaseName] ?? 'Unknown';
  }
}
