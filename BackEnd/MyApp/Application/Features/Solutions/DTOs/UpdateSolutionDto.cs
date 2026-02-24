namespace MyApp.Application.Features.Solutions.DTOs;

public class UpdateSolutionDto
{
    public int SolutionId { get; set; }
    public int IllnessId { get; set; }
    public int TreeStageId { get; set; }
    public string SolutionName { get; set; } = null!;
    public string? SolutionType { get; set; }
    public string? Description { get; set; }
    public int Priority { get; set; }
    public decimal? MinConfidence { get; set; }
}
