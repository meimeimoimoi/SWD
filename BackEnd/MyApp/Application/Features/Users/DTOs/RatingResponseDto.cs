namespace MyApp.Application.Features.Users.DTOs
{
    public class RatingResponseDto
    {
        public int RatingId { get; set; }
        public int PredictionId { get; set; }

        // Thang ?i?m 1-5
        public int? Score { get; set; }

        // Nhãn mô t?: "R?t không chính xác" ? "R?t chính xác"
        public string? ScoreLabel { get; set; }

        public string? Comment { get; set; }
        public DateTime? CreatedAt { get; set; }

        // Thông tin prediction liên quan
        public string? PredictedClass { get; set; }
        public decimal? ConfidenceScore { get; set; }
        public string? ConfidencePercentage { get; set; }
        public string? IllnessName { get; set; }
    }
}
