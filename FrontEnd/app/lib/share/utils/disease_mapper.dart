/// Utility class to map disease names between English and Vietnamese
class DiseaseMapper {
  static const Map<String, String> _englishToVietnamese = {
    'Leaf Blast': 'Đạo ôn (cháy lá do nấm)',
    'Bacterial Leaf Blight': 'Bạc lá (cháy bìa lá do vi khuẩn)',
    'Brown Spot': 'Đốm nâu',
    'Healthy Rice Leaf': 'Lá gạo khỏe',
  };

  static const Map<String, String> _vietnameseToEnglish = {
    'Đạo ôn (cháy lá do nấm)': 'Leaf Blast',
    'Bạc lá (cháy bìa lá do vi khuẩn)': 'Bacterial Leaf Blight',
    'Đốm nâu': 'Brown Spot',
    'Lá gạo khỏe': 'Healthy Rice Leaf',
  };

  /// Convert English disease name to Vietnamese
  static String toVietnamese(String englishName) {
    return _englishToVietnamese[englishName] ?? englishName;
  }

  /// Convert Vietnamese disease name to English
  static String toEnglish(String vietnameseName) {
    return _vietnameseToEnglish[vietnameseName] ?? vietnameseName;
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
}
