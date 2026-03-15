using Microsoft.Extensions.Logging;
using MyApp.Application.Features.TreeIllnesses.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
  
    public class TreeIllnessService : ITreeIllnessService
    {
        private readonly TreeIllnessRepository _repository;
        private readonly ILogger<TreeIllnessService> _logger;

        public TreeIllnessService(
            TreeIllnessRepository repository,
            ILogger<TreeIllnessService> logger)
        {
            _repository = repository;
            _logger = logger;
        }

        public async Task<(List<TreeIllnessResponseDto> illnesses, PaginationMetadata pagination)> GetAllIllnessesAsync(
            TreeIllnessListRequestDto request)
        {
            try
            {
                _logger.LogInformation(
                    "Getting illnesses - Page: {Page}, PageSize: {PageSize}, Search: {Search}, Severity: {Severity}, CreatedFrom: {CreatedFrom}, CreatedTo: {CreatedTo}",
                    request.Page, request.PageSize, request.Search, request.Severity, request.CreatedFrom, request.CreatedTo);

                // Get data from repository
                var (illnesses, totalCount) = await _repository.GetAllIllnessesAsync(
                    request.Search,
                    request.Severity,
                    request.CreatedFrom,
                    request.CreatedTo,
                    request.UpdatedFrom,
                    request.UpdatedTo,
                    request.Page,
                    request.PageSize,
                    request.SortBy,
                    request.SortOrder);

                // Map to DTOs
                var illnessDtos = illnesses.Select(MapToDto).ToList();

                // Create pagination metadata
                var pagination = new PaginationMetadata
                {
                    CurrentPage = request.Page,
                    PageSize = request.PageSize,
                    TotalItems = totalCount,
                    TotalPages = (int)Math.Ceiling(totalCount / (double)request.PageSize)
                };

                _logger.LogInformation(
                    "Retrieved {Count} illnesses out of {Total} total",
                    illnessDtos.Count, totalCount);

                return (illnessDtos, pagination);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting illnesses list");
                throw;
            }
        }

    
        public async Task<TreeIllnessResponseDto?> GetIllnessByIdAsync(int illnessId)
        {
            try
            {
                _logger.LogInformation("Getting illness with ID: {IllnessId}", illnessId);

                var illness = await _repository.GetIllnessByIdAsync(illnessId);

                if (illness == null)
                {
                    _logger.LogWarning("Illness with ID {IllnessId} not found", illnessId);
                    return null;
                }

                return MapToDto(illness);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting illness {IllnessId}", illnessId);
                throw;
            }
        }

        public async Task<Dictionary<string, int>> GetSeverityStatisticsAsync()
        {
            try
            {
                _logger.LogInformation("Getting severity statistics");

                var stats = await _repository.GetCountBySeverityAsync();

                _logger.LogInformation("Retrieved statistics for {Count} severity levels", stats.Count);

                return stats;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting severity statistics");
                throw;
            }
        }

      
        public async Task<TreeIllnessResponseDto> CreateIllnessAsync(CreateTreeIllnessDto dto)
        {
            try
            {
                _logger.LogInformation("Creating new illness: {IllnessName}", dto.IllnessName);

                // Check if illness name already exists
                var exists = await _repository.ExistsByNameAsync(dto.IllnessName);
                if (exists)
                {
                    _logger.LogWarning("Illness name '{IllnessName}' already exists", dto.IllnessName);
                    throw new InvalidOperationException($"Illness with name '{dto.IllnessName}' already exists");
                }

                // Validate severity value (already validated by DataAnnotations, but double-check)
                var validSeverities = new[] { "Low", "Medium", "High", "Critical" };
                if (!validSeverities.Contains(dto.Severity))
                {
                    _logger.LogWarning("Invalid severity value: {Severity}", dto.Severity);
                    throw new ArgumentException($"Severity must be one of: {string.Join(", ", validSeverities)}");
                }

                // Map DTO to entity
                var illness = new TreeIllness
                {
                    IllnessName = dto.IllnessName.Trim(),
                    ScientificName = dto.ScientificName?.Trim(),
                    Description = dto.Description?.Trim(),
                    Symptoms = dto.Symptoms?.Trim(),
                    Causes = dto.Causes?.Trim(),
                    Severity = dto.Severity
                };

                // Create illness
                var createdIllness = await _repository.CreateIllnessAsync(illness);

                _logger.LogInformation(
                    "Successfully created illness with ID: {IllnessId}, Name: {IllnessName}",
                    createdIllness.IllnessId, createdIllness.IllnessName);

                return MapToDto(createdIllness);
            }
            catch (InvalidOperationException)
            {
                // Re-throw duplicate name exception
                throw;
            }
            catch (ArgumentException)
            {
                // Re-throw validation exception
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating illness: {IllnessName}", dto.IllnessName);
                throw;
            }
        }

        public async Task<TreeIllnessResponseDto> UpdateIllnessAsync(int illnessId, UpdateTreeIllnessDto dto)
        {
            try
            {
                _logger.LogInformation("Updating illness with ID: {IllnessId}", illnessId);

                // Get existing illness
                var illness = await _repository.GetIllnessByIdAsync(illnessId);
                if (illness == null)
                {
                    _logger.LogWarning("Illness with ID {IllnessId} not found", illnessId);
                    throw new KeyNotFoundException($"Illness with ID {illnessId} not found");
                }

                // Check if illness name is being changed and if new name already exists
                if (!string.IsNullOrWhiteSpace(dto.IllnessName) && 
                    dto.IllnessName.Trim() != illness.IllnessName)
                {
                    var nameExists = await _repository.ExistsByNameExcludingIdAsync(dto.IllnessName, illnessId);
                    if (nameExists)
                    {
                        _logger.LogWarning(
                            "Cannot update illness {IllnessId}: name '{IllnessName}' already exists",
                            illnessId, dto.IllnessName);
                        throw new InvalidOperationException($"Illness with name '{dto.IllnessName}' already exists");
                    }
                }

                // Validate severity if provided
                if (!string.IsNullOrWhiteSpace(dto.Severity))
                {
                    var validSeverities = new[] { "Low", "Medium", "High", "Critical" };
                    if (!validSeverities.Contains(dto.Severity))
                    {
                        _logger.LogWarning("Invalid severity value: {Severity}", dto.Severity);
                        throw new ArgumentException($"Severity must be one of: {string.Join(", ", validSeverities)}");
                    }
                }

                var updatedFields = new List<string>();

                if (!string.IsNullOrWhiteSpace(dto.IllnessName))
                {
                    illness.IllnessName = dto.IllnessName.Trim();
                    updatedFields.Add("IllnessName");
                }

                if (dto.ScientificName != null)
                {
                    illness.ScientificName = string.IsNullOrWhiteSpace(dto.ScientificName) 
                        ? null 
                        : dto.ScientificName.Trim();
                    updatedFields.Add("ScientificName");
                }

                if (dto.Description != null)
                {
                    illness.Description = string.IsNullOrWhiteSpace(dto.Description) 
                        ? null 
                        : dto.Description.Trim();
                    updatedFields.Add("Description");
                }

                if (dto.Symptoms != null)
                {
                    illness.Symptoms = string.IsNullOrWhiteSpace(dto.Symptoms) 
                        ? null 
                        : dto.Symptoms.Trim();
                    updatedFields.Add("Symptoms");
                }

                if (dto.Causes != null)
                {
                    illness.Causes = string.IsNullOrWhiteSpace(dto.Causes) 
                        ? null 
                        : dto.Causes.Trim();
                    updatedFields.Add("Causes");
                }

                if (!string.IsNullOrWhiteSpace(dto.Severity))
                {
                    illness.Severity = dto.Severity;
                    updatedFields.Add("Severity");
                }

                // Check if any fields were actually updated
                if (!updatedFields.Any())
                {
                    _logger.LogInformation("No fields to update for illness {IllnessId}", illnessId);
                    return MapToDto(illness);
                }

                // Update illness
                var updatedIllness = await _repository.UpdateIllnessAsync(illness);

                _logger.LogInformation(
                    "Successfully updated illness {IllnessId}. Updated fields: {UpdatedFields}",
                    illnessId, string.Join(", ", updatedFields));

                return MapToDto(updatedIllness);
            }
            catch (KeyNotFoundException)
            {
                throw;
            }
            catch (InvalidOperationException)
            {
                // Re-throw duplicate name exception
                throw;
            }
            catch (ArgumentException)
            {
                // Re-throw validation exception
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating illness {IllnessId}", illnessId);
                throw;
            }
        }

    
        private TreeIllnessResponseDto MapToDto(TreeIllness illness)
        {
            return new TreeIllnessResponseDto
            {
                IllnessId = illness.IllnessId,
                IllnessName = illness.IllnessName,
                ScientificName = illness.ScientificName,
                Description = illness.Description,
                Symptoms = illness.Symptoms,
                Causes = illness.Causes,
                Severity = illness.Severity,
                CreatedAt = illness.CreatedAt,
                UpdatedAt = illness.UpdatedAt,
                TreatmentSolutionCount = illness.TreatmentSolutions?.Count ?? 0,
                PredictionCount = illness.Predictions?.Count ?? 0
            };
        }
    }
}
