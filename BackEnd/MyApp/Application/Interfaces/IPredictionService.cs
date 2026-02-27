using MyApp.Application.Features.Prediction;

namespace MyApp.Application.Interfaces
{
    public interface IPredictionService
    {
        Task<PredictionResponseDto> PredictAsync(int userId, IFormFile imageFile);
        Task<bool> IsModelLoaded();
    }
}
