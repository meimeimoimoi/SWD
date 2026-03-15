namespace MyApp.Application.Features.Users.DTOs
{
    public class PredictionResponseDto
    {
        public int PredictionId { get; set; }
        public int UploadId { get; set; }

        // Thông tin bệnh
        public int? IllnessId { get; set; }
        public string? IllnessName { get; set; }
        public string? IllnessScientificName { get; set; }
        public string? IllnessSeverity { get; set; }
        public string? IllnessDescription { get; set; }
        public string? Symptoms { get; set; }
        public string? Causes { get; set; }

        // Thông tin cây
        public int? TreeId { get; set; }
        public string? TreeName { get; set; }

        // Kết quả dự đoán
        public string? PredictedClass { get; set; }
        public decimal? ConfidenceScore { get; set; }  // Độ tin cậy
        public string? ConfidencePercentage { get; set; }  // "95.5%"
        public string? TopNPredictions { get; set; }  // JSON với top dự đoán

        // Thông tin model
        public int? ModelVersionId { get; set; }
        public string? ModelName { get; set; }
        public string? ModelVersion { get; set; }

        // Performance
        public int? ProcessingTimeMs { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
