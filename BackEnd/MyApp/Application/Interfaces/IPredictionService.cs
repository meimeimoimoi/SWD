using MyApp.Application.Features.Predictions.DTOs;

namespace MyApp.Application.Interfaces;

public interface IPredictionService
{
    Task<PredictionResponseDto> RunPredictionAsync(PredictionRequestDto request);
    Task<PredictionDetailDto?> GetPredictionByIdAsync(int id);
    Task<List<PredictionHistoryDto>> GetPredictionHistoryAsync();
}
