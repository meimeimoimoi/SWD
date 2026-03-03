namespace MyApp.Application.Features.TreeStages.DTOs
{
    public class TreeStageResponseDto
    {
        public int StageId { get; set; }
        public string? StageName { get; set; }
        public string? Description { get; set; }
        public DateTime? CreatedAt { get; set; }
        
        // Statistics
        public int TreatmentSolutionCount { get; set; }
    }
}
