using MyApp.Application.Features.Users.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IPredictionService
    {
        Task<PredictionResponseDto?> GetPredictionByUploadIdAsync(int uploadId);
        Task<PredictionResponseDto?> GetPredictionByIdAsync(int predictionId);
        Task<List<PredictionResponseDto>> GetUserPredictionsAsync(int userId);
        Task<PredictionResponseDto> CreatePredictionAsync(int uploadId, int illnessId, decimal confidenceScore, string? topNPredictions = null);
    }
}
