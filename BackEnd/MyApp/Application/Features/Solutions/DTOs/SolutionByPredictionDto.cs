namespace MyApp.Application.Features.Solutions.DTOs;

public class SolutionByPredictionDto
{
    public int PredictionId { get; set; }
    public List<SolutionItemDto> Solutions { get; set; } = new();
}

public class SolutionItemDto
{
    public int SolutionId { get; set; }
    public string SolutionName { get; set; } = null!;
    public string? SolutionType { get; set; }
    public string? Description { get; set; }
    public int Priority { get; set; }
}
