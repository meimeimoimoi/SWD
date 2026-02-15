using MyApp.Application.Features.Predictions.DTOs;

namespace MyApp.Application.Interfaces;

public interface IPredictionService
{
    Task<RunPredictionResponseDto> RunPredictionAsync(RunPredictionRequestDto request);
    Task<PredictionDetailDto?> GetPredictionByIdAsync(int predictionId);
    Task<List<PredictionHistoryDto>> GetPredictionHistoryAsync(int? userId = null, DateTime? fromDate = null, DateTime? toDate = null);
}
