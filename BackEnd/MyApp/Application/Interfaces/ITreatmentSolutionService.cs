using MyApp.Application.Features.Users.DTOs;
using MyApp.Domain.Entities;

namespace MyApp.Application.Interfaces
{
    public interface ITreatmentSolutionService
    {
        Task<List<TreatmentSolutionResponseDto>> GetSolutionByIllnessIdAsync(
            int illnessId,
            decimal? confidenceScore = null);
        Task<TreatmentSolutionResponseDto?> GetSolutionByIdAsync(int solutionId);
        Task<List<TreatmentSolutionResponseDto>> GetSolutionsByPredictionIdAsync(int predictionId);
        Task<List<TreatmentSolutionResponseDto>> GetAllSolutionsAsync();
    }
}
