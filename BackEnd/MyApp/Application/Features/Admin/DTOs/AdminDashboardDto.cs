using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Admin.DTOs
{
    // ── Dashboard stats ──────────────────

    public class DashboardStatsDto
    {
        public int TotalUsers { get; set; }
        public int ActiveUsers { get; set; }
        public int TotalPredictions { get; set; }
        public int TodayPredictions { get; set; }
        public int TotalModels { get; set; }
        public int ActiveModels { get; set; }
    }

    // ── System monitoring ──────────────────

    public class PredictionStatsDto
    {
        public int TotalPredictions { get; set; }
        public int TodayPredictions { get; set; }
        public double AverageConfidence { get; set; }
        public List<ClassDistributionDto> ClassDistribution { get; set; } = new();
        public List<DailyPredictionDto> DailyTrend { get; set; } = new();
    }

    public class ClassDistributionDto
    {
        public string ClassName { get; set; } = null!;
        public int Count { get; set; }
        public double Percentage { get; set; }
    }

    public class DailyPredictionDto
    {
        public string Date { get; set; } = null!;
        public int Count { get; set; }
    }

    public class ModelAccuracyDto
    {
        public int ModelVersionId { get; set; }
        public string ModelName { get; set; } = null!;
        public string Version { get; set; } = null!;
        public bool? IsActive { get; set; }
        public bool? IsDefault { get; set; }
        public int TotalPredictions { get; set; }
        public double AverageConfidence { get; set; }
        public double PositiveRatingRate { get; set; }
    }

    /// <summary>Top diseases by prediction volume for home dashboard &quot;Common threats&quot;.</summary>
    public class CommonThreatItemDto
    {
        public int? IllnessId { get; set; }
        public string Title { get; set; } = "";
        public string? ScientificName { get; set; }
        public int ReportCount { get; set; }
        /// <summary>Relative URL e.g. /uploads/images/file.jpg</summary>
        public string? ImageUrl { get; set; }
    }

    public class RatingDto
    {
        public int RatingId { get; set; }
        public int PredictionId { get; set; }
        public string? PredictedClass { get; set; }
        public decimal? ConfidenceScore { get; set; }
        public string? RatingValue { get; set; }
        public string? Comment { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    // ── Treatment review ──────────────────

    public class TreatmentReviewDto
    {
        public int SolutionId { get; set; }
        public string? SolutionName { get; set; }
        public string? SolutionType { get; set; }
        public string? Description { get; set; }
        public int IllnessId { get; set; }
        public string? IllnessName { get; set; }
        public int TreeStageId { get; set; }
        public string? TreeStageName { get; set; }
        public decimal? MinConfidence { get; set; }
        public int? Priority { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    public class UpdateTreatmentDto
    {
        [StringLength(200, MinimumLength = 1, ErrorMessage = "Solution name must be between 1 and 200 characters.")]
        public string? SolutionName { get; set; }

        [StringLength(50, ErrorMessage = "Solution type must not exceed 50 characters.")]
        public string? SolutionType { get; set; }

        [StringLength(1000, ErrorMessage = "Description must not exceed 1000 characters.")]
        public string? Description { get; set; }

        [Range(0, 1, ErrorMessage = "MinConfidence must be between 0 and 1.")]
        public decimal? MinConfidence { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Priority must be a positive integer.")]
        public int? Priority { get; set; }
    }
}
