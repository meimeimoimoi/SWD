namespace MyApp.Application.Features.Predictions.DTOs;

public class PredictionResponseDto
{
    public int PredictionId { get; set; }
    public TreeDto Tree { get; set; } = null!;
    public IllnessDto Illness { get; set; } = null!;
    public decimal ConfidenceScore { get; set; }
    public int ProcessingTimeMs { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class TreeDto
{
    public int TreeId { get; set; }
    public string TreeName { get; set; } = null!;
}

public class IllnessDto
{
    public int IllnessId { get; set; }
    public string IllnessName { get; set; } = null!;
}
