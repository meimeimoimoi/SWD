namespace MyApp.Application.Features.Predictions.DTOs;

public class PredictionHistoryDto
{
    public int PredictionId { get; set; }
    public string TreeName { get; set; } = null!;
    public string IllnessName { get; set; } = null!;
    public decimal ConfidenceScore { get; set; }
    public DateTime CreatedAt { get; set; }
    
    // Additional useful info
    public string? ImagePath { get; set; }
    public string? ModelName { get; set; }
}
