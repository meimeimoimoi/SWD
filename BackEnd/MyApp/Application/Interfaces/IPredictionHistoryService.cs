using MyApp.Application.Features.Prediction;

namespace MyApp.Application.Interfaces
{
    public interface IPredictionHistoryService
    {
        Task<List<PredictionHistoryDto>> GetUserHistoryAsync(int userId);
    }
}
