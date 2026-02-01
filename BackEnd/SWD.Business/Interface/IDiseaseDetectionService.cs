using SWD.Business.DTOs;

namespace SWD.Business.Interface;

/// <summary>
/// Interface for disease detection service using ResNet18
/// </summary>
public interface IDiseaseDetectionService
{
    /// <summary>
    /// Predict disease from image bytes
    /// </summary>
    Task<DiseasePredictionResponseDTO> PredictDiseaseAsync(byte[] imageBytes);
    
    /// <summary>
    /// Predict disease from base64 encoded image
    /// </summary>
    Task<DiseasePredictionResponseDTO> PredictDiseaseFromBase64Async(string base64Image);
    
    /// <summary>
    /// Check if the model is loaded and ready
    /// </summary>
    bool IsModelReady();
}
