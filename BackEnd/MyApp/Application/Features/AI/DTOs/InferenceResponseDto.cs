namespace MyApp.Application.Features.AI.DTOs;

public class InferenceResponseDto
{
    public int PredictionId { get; set; }
    public int UploadId { get; set; }
    public int ModelVersionId { get; set; }
    public string ModelName { get; set; } = null!;
    public string ModelVersion { get; set; } = null!;
    public string? PredictedClass { get; set; }
    public decimal? ConfidenceScore { get; set; }
    public List<PredictionResult>? TopNPredictions { get; set; }
    public int? ProcessingTimeMs { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class PredictionResult
{
    public string ClassName { get; set; } = null!;
    public decimal Confidence { get; set; }
    public int? TreeId { get; set; }
    public int? IllnessId { get; set; }
}
