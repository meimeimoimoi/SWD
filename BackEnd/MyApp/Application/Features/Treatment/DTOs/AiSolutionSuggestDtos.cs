using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Treatment.DTOs;

public class AiSolutionSuggestRequest
{
    public int? IllnessId { get; set; }

    [MaxLength(255)]
    public string? DiseaseName { get; set; }

    public double? Confidence { get; set; }

    public int? PredictionId { get; set; }
}

public class AiSolutionSuggestResponse
{
    public string Source { get; set; } = "heuristic";

    public string Summary { get; set; } = string.Empty;

    public List<string> ActionSteps { get; set; } = new();

    public string Disclaimer { get; set; } = string.Empty;
}
