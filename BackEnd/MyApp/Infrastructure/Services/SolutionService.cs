using Microsoft.Extensions.Logging;
using MyApp.Application.Features.Solutions.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services;

public class SolutionService : ISolutionService
{
    private readonly SolutionRepository _repository;
    private readonly ILogger<SolutionService> _logger;

    public SolutionService(SolutionRepository repository, ILogger<SolutionService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<List<SolutionDto>> GetAllSolutionsAsync()
    {
        try
        {
            var solutions = await _repository.GetAllSolutionsAsync();
            return MapToDto(solutions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all solutions");
            throw;
        }
    }

    public async Task<SolutionDto?> GetSolutionByIdAsync(int solutionId)
    {
        try
        {
            var solution = await _repository.GetSolutionByIdAsync(solutionId);
            
            if (solution == null)
                return null;

            return MapToDto(solution);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting solution by ID: {SolutionId}", solutionId);
            throw;
        }
    }

    public async Task<List<SolutionDto>> GetSolutionsByPredictionIdAsync(int predictionId)
    {
        try
        {
            var solutions = await _repository.GetSolutionsByPredictionIdAsync(predictionId);
            return MapToDto(solutions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting solutions by prediction ID: {PredictionId}", predictionId);
            throw;
        }
    }

    public async Task<List<SolutionDto>> GetSolutionsByIllnessIdAsync(int illnessId)
    {
        try
        {
            var solutions = await _repository.GetSolutionsByIllnessIdAsync(illnessId);
            return MapToDto(solutions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting solutions by illness ID: {IllnessId}", illnessId);
            throw;
        }
    }

    public async Task<SolutionDto> CreateSolutionAsync(CreateSolutionDto createDto)
    {
        try
        {
            var solution = new TreatmentSolution
            {
                SolutionName = createDto.SolutionName,
                SolutionType = createDto.SolutionType,
                Description = createDto.Description,
                IllnessId = createDto.IllnessId,
                TreeStageId = createDto.TreeStageId,
                Priority = createDto.Priority,
                MinConfidence = createDto.MinConfidence,
                CreatedAt = DateTime.UtcNow
            };

            var created = await _repository.CreateSolutionAsync(solution);
            
            _logger.LogInformation("Solution created successfully: {SolutionId}", created.SolutionId);

            return MapToDto(created);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating solution");
            throw;
        }
    }

    public async Task<bool> UpdateSolutionAsync(int solutionId, UpdateSolutionDto updateDto)
    {
        try
        {
            var solution = new TreatmentSolution
            {
                SolutionId = solutionId,
                SolutionName = updateDto.SolutionName,
                SolutionType = updateDto.SolutionType,
                Description = updateDto.Description,
                IllnessId = updateDto.IllnessId,
                TreeStageId = updateDto.TreeStageId,
                Priority = updateDto.Priority,
                MinConfidence = updateDto.MinConfidence
            };

            var result = await _repository.UpdateSolutionAsync(solution);
            
            if (result)
                _logger.LogInformation("Solution updated successfully: {SolutionId}", solutionId);
            else
                _logger.LogWarning("Solution not found for update: {SolutionId}", solutionId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating solution: {SolutionId}", solutionId);
            throw;
        }
    }

    public async Task<bool> DeleteSolutionAsync(int solutionId)
    {
        try
        {
            var result = await _repository.DeleteSolutionAsync(solutionId);
            
            if (result)
                _logger.LogInformation("Solution deleted successfully: {SolutionId}", solutionId);
            else
                _logger.LogWarning("Solution not found for deletion: {SolutionId}", solutionId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting solution: {SolutionId}", solutionId);
            throw;
        }
    }

    #region Private Helpers

    private SolutionDto MapToDto(TreatmentSolution solution)
    {
        return new SolutionDto
        {
            SolutionId = solution.SolutionId,
            SolutionName = solution.SolutionName ?? "Unknown",
            SolutionType = solution.SolutionType,
            Description = solution.Description,
            Priority = solution.Priority,
            MinConfidence = solution.MinConfidence,
            Illness = solution.Illness != null ? new IllnessInfoDto
            {
                IllnessId = solution.Illness.IllnessId,
                IllnessName = solution.Illness.IllnessName ?? "Unknown"
            } : null,
            TreeStage = solution.TreeStage != null ? new TreeStageInfoDto
            {
                StageId = solution.TreeStage.StageId,
                StageName = solution.TreeStage.StageName ?? "Unknown"
            } : null
        };
    }

    private List<SolutionDto> MapToDto(List<TreatmentSolution> solutions)
    {
        return solutions.Select(MapToDto).ToList();
    }

    #endregion
}
