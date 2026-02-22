using MyApp.Application.Features.Solutions.DTOs;

namespace MyApp.Application.Interfaces;

public interface ISolutionService
{
    Task<List<SolutionDto>> GetAllSolutionsAsync();
    Task<SolutionDto?> GetSolutionByIdAsync(int solutionId);
    Task<List<SolutionDto>> GetSolutionsByPredictionIdAsync(int predictionId);
    Task<List<SolutionDto>> GetSolutionsByIllnessIdAsync(int illnessId);
    Task<SolutionDto> CreateSolutionAsync(CreateSolutionDto createDto);
    Task<bool> UpdateSolutionAsync(int solutionId, UpdateSolutionDto updateDto);
    Task<bool> DeleteSolutionAsync(int solutionId);
}
