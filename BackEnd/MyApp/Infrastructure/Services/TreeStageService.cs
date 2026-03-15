using Microsoft.Extensions.Logging;
using MyApp.Application.Features.TreeStages.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
    public class TreeStageService : ITreeStageService
    {
        private readonly TreeStageRepository _repository;
        private readonly ILogger<TreeStageService> _logger;

        public TreeStageService(
            TreeStageRepository repository,
            ILogger<TreeStageService> logger)
        {
            _repository = repository;
            _logger = logger;
        }

        public async Task<List<TreeStageResponseDto>> GetAllStagesAsync()
        {
            try
            {
                _logger.LogInformation("Getting all tree stages");

                var stages = await _repository.GetAllStagesAsync();

                var stageDtos = stages.Select(MapToDto).ToList();

                _logger.LogInformation("Retrieved {Count} tree stages", stageDtos.Count);

                return stageDtos;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting tree stages");
                throw;
            }
        }

        public async Task<TreeStageResponseDto?> GetStageByIdAsync(int stageId)
        {
            try
            {
                _logger.LogInformation("Getting tree stage {StageId}", stageId);

                var stage = await _repository.GetStageByIdAsync(stageId);

                if (stage == null)
                {
                    _logger.LogWarning("Tree stage {StageId} not found", stageId);
                    return null;
                }

                return MapToDto(stage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting tree stage {StageId}", stageId);
                throw;
            }
        }

        public async Task<TreeStageResponseDto> CreateStageAsync(CreateTreeStageDto dto)
        {
            try
            {
                _logger.LogInformation("Creating tree stage: {StageName}", dto.StageName);

                // Check if stage name already exists
                var exists = await _repository.ExistsByNameAsync(dto.StageName);
                if (exists)
                {
                    _logger.LogWarning("Tree stage name '{StageName}' already exists", dto.StageName);
                    throw new InvalidOperationException($"Tree stage with name '{dto.StageName}' already exists");
                }

                // Create stage
                var stage = new TreeStage
                {
                    StageName = dto.StageName.Trim(),
                    Description = dto.Description?.Trim()
                };

                var createdStage = await _repository.CreateStageAsync(stage);

                // Reload with navigation properties
                var loadedStage = await _repository.GetStageByIdAsync(createdStage.StageId);

                _logger.LogInformation(
                    "Successfully created tree stage {StageId}: {StageName}",
                    createdStage.StageId, createdStage.StageName);

                return MapToDto(loadedStage!);
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating tree stage: {StageName}", dto.StageName);
                throw;
            }
        }

        public async Task<TreeStageResponseDto> UpdateStageAsync(int stageId, UpdateTreeStageDto dto)
        {
            try
            {
                _logger.LogInformation("Updating tree stage {StageId}", stageId);

                // Get existing stage
                var stage = await _repository.GetStageByIdAsync(stageId);
                if (stage == null)
                {
                    _logger.LogWarning("Tree stage {StageId} not found", stageId);
                    throw new KeyNotFoundException($"Tree stage with ID {stageId} not found");
                }

                // Check if stage name is being changed and if new name already exists
                if (!string.IsNullOrWhiteSpace(dto.StageName) &&
                    dto.StageName.Trim() != stage.StageName)
                {
                    var nameExists = await _repository.ExistsByNameExcludingIdAsync(dto.StageName, stageId);
                    if (nameExists)
                    {
                        _logger.LogWarning(
                            "Cannot update stage {StageId}: name '{StageName}' already exists",
                            stageId, dto.StageName);
                        throw new InvalidOperationException($"Tree stage with name '{dto.StageName}' already exists");
                    }
                }

                // Track updated fields
                var updatedFields = new List<string>();

                // Update only provided fields
                if (!string.IsNullOrWhiteSpace(dto.StageName))
                {
                    stage.StageName = dto.StageName.Trim();
                    updatedFields.Add("StageName");
                }

                if (dto.Description != null)
                {
                    stage.Description = string.IsNullOrWhiteSpace(dto.Description)
                        ? null
                        : dto.Description.Trim();
                    updatedFields.Add("Description");
                }

                // Check if any fields were actually updated
                if (!updatedFields.Any())
                {
                    _logger.LogInformation("No fields to update for tree stage {StageId}", stageId);
                    return MapToDto(stage);
                }

                // Update stage
                var updatedStage = await _repository.UpdateStageAsync(stage);

                _logger.LogInformation(
                    "Successfully updated tree stage {StageId}. Updated fields: {UpdatedFields}",
                    stageId, string.Join(", ", updatedFields));

                return MapToDto(updatedStage);
            }
            catch (KeyNotFoundException)
            {
                throw;
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating tree stage {StageId}", stageId);
                throw;
            }
        }

        public async Task DeleteStageAsync(int stageId)
        {
            try
            {
                _logger.LogInformation("Deleting tree stage {StageId}", stageId);

                var stage = await _repository.GetStageByIdAsync(stageId);
                if (stage == null)
                {
                    _logger.LogWarning("Tree stage {StageId} not found", stageId);
                    throw new KeyNotFoundException($"Tree stage with ID {stageId} not found");
                }

                // Check if stage has treatment solutions
                var hasTreatments = await _repository.HasTreatmentSolutionsAsync(stageId);
                if (hasTreatments)
                {
                    _logger.LogWarning(
                        "Cannot delete tree stage {StageId}: has associated treatment solutions",
                        stageId);
                    throw new InvalidOperationException(
                        "Cannot delete this tree stage because it has associated treatment solutions");
                }

                await _repository.DeleteStageAsync(stage);

                _logger.LogInformation("Successfully deleted tree stage {StageId}", stageId);
            }
            catch (KeyNotFoundException)
            {
                throw;
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting tree stage {StageId}", stageId);
                throw;
            }
        }

        private TreeStageResponseDto MapToDto(TreeStage stage)
        {
            return new TreeStageResponseDto
            {
                StageId = stage.StageId,
                StageName = stage.StageName,
                Description = stage.Description,
                CreatedAt = stage.CreatedAt,
                TreatmentSolutionCount = stage.TreatmentSolutions?.Count ?? 0
            };
        }
    }
}
