namespace MyApp.Application.Features.Prediction
{
    public class PredictionResponseDto
    {
        public int PredictionId { get; set; }
        public string ImageUrl { get; set; } = string.Empty; // Đường dẫn ảnh đã upload
        public string PredictedClass { get; set; } = string.Empty;
        public double Confidence { get; set; }
        public long ProcessingTimeMs { get; set; }

        // Thông tin bệnh từ DB
        public string? DiseaseName { get; set; }
        public string? Symptoms { get; set; }
        public string? Causes { get; set; }

        // Thông tin điều trị
        public List<TreatmentDto> Treatments { get; set; } = new List<TreatmentDto>();
    }
    public class TreatmentDto
    {
        public string Name { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
    }
}
