namespace MyApp.Application.Features.Predictions.DTOs;

public class PredictionDetailDto
{
    public int PredictionId { get; set; }
    public string PredictedClass { get; set; } = null!;
    public decimal ConfidenceScore { get; set; }
    public List<TopPredictionDto> TopNPredictions { get; set; } = new();
}

public class TopPredictionDto
{
    public string Class { get; set; } = null!;
    public decimal Score { get; set; }
}
