namespace MyApp.Application.Features.Predictions.DTOs;

public class RunPredictionResponseDto
{
    public int PredictionId { get; set; }
    public TreeInfoDto Tree { get; set; } = null!;
    public IllnessInfoDto Illness { get; set; } = null!;
    public decimal ConfidenceScore { get; set; }
    public int ProcessingTimeMs { get; set; }
    public DateTime CreatedAt { get; set; }
}
