namespace MyApp.Application.Features.Solutions.DTOs;

public class SolutionDto
{
    public int SolutionId { get; set; }
    public string SolutionName { get; set; } = null!;
    public string? SolutionType { get; set; }
    public string? Description { get; set; }
    public int? Priority { get; set; }
    public decimal? MinConfidence { get; set; }
    public IllnessInfoDto? Illness { get; set; }
    public TreeStageInfoDto? TreeStage { get; set; }
}

public class IllnessInfoDto
{
    public int IllnessId { get; set; }
    public string IllnessName { get; set; } = null!;
}

public class TreeStageInfoDto
{
    public int StageId { get; set; }
    public string StageName { get; set; } = null!;
}
