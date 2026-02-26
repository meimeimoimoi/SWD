using MyApp.Application.Features.Prediction;

namespace MyApp.Application.Interfaces
{
    public interface IPredictionService
    {
        Task<PredictionResponseDto> PredictAsync(Stream request);
        Task<bool> IsModelLoaded();
    }
}
