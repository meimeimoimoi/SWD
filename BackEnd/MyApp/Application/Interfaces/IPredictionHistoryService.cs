using MyApp.Application.Features.Prediction;

namespace MyApp.Application.Interfaces
{
    public interface IPredictionHistoryService
    {
        Task<List<PredictionHistoryDto>> GetUserHistoryAsync(int userId);
        Task<PredictionHistoryDto?> GetPredictionByIdAsync(int predictionId, int userId);
        Task<List<PredictionHistoryDto>> GetAllHistoryAsync();
    }
}
