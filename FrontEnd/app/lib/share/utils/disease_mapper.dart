class DiseaseMapper {
  static const Map<String, String> _displayNames = {
    'Leaf Blast': 'Leaf blast',
    'Bacterial Leaf Blight': 'Bacterial leaf blight',
    'Brown Spot': 'Brown spot',
    'Healthy Rice Leaf': 'Healthy rice leaf',
  };

  static String toDisplayName(String englishName) {
    return _displayNames[englishName] ?? englishName;
  }

  static bool isHealthy(String diseaseName) {
    return diseaseName.toLowerCase().contains('healthy');
  }

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
    const Map<String, String> impact = {
      'Leaf Blast':
          'Can reduce yield ~10–30%; severe outbreaks may reach 40–50%.',
      'Bacterial Leaf Blight':
          'Can reduce yield ~20–50%; severe cases may exceed 70%.',
      'Brown Spot': 'Often reduces yield ~5–20%.',
      'Healthy Rice Leaf': 'No negative impact; normal yield expected.',
    };
    return impact[englishDiseaseName] ?? 'Unknown';
  }
}
