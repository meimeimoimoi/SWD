namespace MyApp.Application.Features.Treatment.DTOs
{
    public class TreatmentRecommendationDto
    {
        public int SolutionId { get; set; }
        public string? SolutionName { get; set; }
        public string? SolutionType { get; set; }
        public string? Description { get; set; }
        public int? IllnessStageId { get; set; }
        public int TreeStageId { get; set; }
        public string? TreeStageName { get; set; }
        public decimal? MinConfidence { get; set; }
        public int? Priority { get; set; }
        public string? IllnessName { get; set; }
        public List<SolutionConditionDto> Conditions { get; set; } = new();
    }
}
