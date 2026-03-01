namespace MyApp.Application.Features.Prediction
{
    public class PredictionHistoryDto
    {
        public int PredictionId { get; set; }
        public int UploadId { get; set; }
        public string? ImageUrl { get; set; }
        public string? OriginalFilename { get; set; }
        public string? PredictedClass { get; set; }
        public decimal? ConfidenceScore { get; set; }
        public int? ProcessingTimeMs { get; set; }
        public DateTime? CreatedAt { get; set; }
        public string? IllnessName { get; set; }
        public string? IllnessSeverity { get; set; }
        public string? TreeName { get; set; }
    }
}
