namespace MyApp.Application.Features.Predictions.DTOs;

public class PredictionDetailDto
{
    public int PredictionId { get; set; }
    public string PredictedClass { get; set; } = null!;
    public decimal ConfidenceScore { get; set; }
    public List<TopPredictionDto> TopNPredictions { get; set; } = new();
    public int ProcessingTimeMs { get; set; }
    public DateTime CreatedAt { get; set; }
    
    // Additional info
    public TreeInfoDto? Tree { get; set; }
    public IllnessInfoDto? Illness { get; set; }
    public ModelInfoDto? Model { get; set; }
}

public class TopPredictionDto
{
    public string Class { get; set; } = null!;
    public decimal Score { get; set; }
}

public class TreeInfoDto
{
    public int TreeId { get; set; }
    public string TreeName { get; set; } = null!;
}

public class IllnessInfoDto
{
    public int IllnessId { get; set; }
    public string IllnessName { get; set; } = null!;
}

public class ModelInfoDto
{
    public int ModelVersionId { get; set; }
    public string ModelName { get; set; } = null!;
    public string Version { get; set; } = null!;
}
