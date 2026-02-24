using MyApp.Application.Features.Solutions.DTOs;

namespace MyApp.Application.Interfaces;

public interface ISolutionService
{
    Task<SolutionByPredictionDto?> GetSolutionsByPredictionAsync(int predictionId);
    Task<SolutionByIllnessDto?> GetSolutionsByIllnessAsync(int illnessId);
    Task<int> CreateSolutionAsync(CreateSolutionDto dto);
    Task<bool> UpdateSolutionAsync(int id, UpdateSolutionDto dto);
    Task<bool> DeleteSolutionAsync(int id);
}
