namespace MyApp.Application.Features.Treatment.DTOs
{
    public class DiseaseDetailDto
    {
        public int IllnessId { get; set; }
        public string? IllnessName { get; set; }
        public string? ScientificName { get; set; }
        public string? Description { get; set; }
        public string? Symptoms { get; set; }
        public string? Causes { get; set; }
        public string? Severity { get; set; }
        public List<TreatmentSolutionDto> TreatmentSolutions { get; set; } = new();
    }

    public class TreatmentSolutionDto
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
        public List<SolutionConditionDto> Conditions { get; set; } = new();
    }

    public class SolutionConditionDto
    {
        public int ConditionId { get; set; }
        public decimal? MinConfidence { get; set; }
        public string? WeatherCondition { get; set; }
        public string? Note { get; set; }
    }
}
