namespace SWD.Business.DTOs;

/// <summary>
/// DTO for disease prediction request
/// </summary>
public class DiseasePredictionRequestDTO
{
    /// <summary>
    /// Base64 encoded image or image file name
    /// </summary>
    public string? ImageData { get; set; }
    
    /// <summary>
    /// Optional: Image file extension (jpg, png, etc.)
    /// </summary>
    public string? FileExtension { get; set; }
}

/// <summary>
/// DTO for disease prediction response
/// </summary>
public class DiseasePredictionResponseDTO
{
    /// <summary>
    /// Predicted disease label
    /// </summary>
    public string PredictedDisease { get; set; } = string.Empty;
    
    /// <summary>
    /// Confidence score (0-100%)
    /// </summary>
    public float Confidence { get; set; }
    
    /// <summary>
    /// All predictions with confidence scores
    /// </summary>
    public List<DiseasePredictionItemDTO> AllPredictions { get; set; } = new();
    
    /// <summary>
    /// Processing time in milliseconds
    /// </summary>
    public long ProcessingTimeMs { get; set; }
    
    /// <summary>
    /// Prediction timestamp
    /// </summary>
    public DateTime PredictedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// Individual disease prediction item
/// </summary>
public class DiseasePredictionItemDTO
{
    /// <summary>
    /// Disease label
    /// </summary>
    public string Label { get; set; } = string.Empty;
    
    /// <summary>
    /// Confidence score (0-100%)
    /// </summary>
    public float Confidence { get; set; }
}
