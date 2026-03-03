namespace MyApp.Application.Features.TreeIllnesses.DTOs
{
    /// <summary>
    /// Response DTO for Tree Illness
    /// </summary>
    public class TreeIllnessResponseDto
    {
        public int IllnessId { get; set; }
        public string? IllnessName { get; set; }
        public string? ScientificName { get; set; }
        public string? Description { get; set; }
        public string? Symptoms { get; set; }
        public string? Causes { get; set; }
        public string? Severity { get; set; }
        public DateTime? CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Additional statistics (optional)
        public int TreatmentSolutionCount { get; set; }
        public int PredictionCount { get; set; }
    }
}
