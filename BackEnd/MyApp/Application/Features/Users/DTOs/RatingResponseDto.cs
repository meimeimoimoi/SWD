namespace MyApp.Application.Features.Users.DTOs
{
    public class RatingResponseDto
    {
        public int RatingId { get; set; }
        public int PredictionId { get; set; }

        public int? Score { get; set; }

        public string? ScoreLabel { get; set; }

        public string? Comment { get; set; }
        public DateTime? CreatedAt { get; set; }

        public string? PredictedClass { get; set; }
        public decimal? ConfidenceScore { get; set; }
        public string? ConfidencePercentage { get; set; }
        public string? IllnessName { get; set; }

        public string? UserEmail { get; set; }
        public string? UserName { get; set; }

        public int? UserId { get; set; }

        public string? ImageUrl { get; set; }
    }
}
