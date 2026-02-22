using Microsoft.Extensions.Logging;
using MyApp.Application.Features.Illnesses.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services;

public class IllnessService : IIllnessService
{
    private readonly TreeDataRepository _repository;
    private readonly ILogger<IllnessService> _logger;

    public IllnessService(TreeDataRepository repository, ILogger<IllnessService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<List<IllnessDto>> GetAllIllnessesAsync()
    {
        try
        {
            var illnesses = await _repository.GetAllIllnessesAsync();
            
            return illnesses.Select(i => new IllnessDto
            {
                IllnessId = i.IllnessId,
                IllnessName = i.IllnessName ?? "Unknown",
                ScientificName = i.ScientificName,
                Description = i.Description,
                Symptoms = i.Symptoms,
                Causes = i.Causes,
                Severity = i.Severity,
                CreatedAt = i.CreatedAt,
                AffectedTrees = i.TreeIllnessRelationships?.Select(r => new TreeSimpleDto
                {
                    TreeId = r.Tree.TreeId,
                    TreeName = r.Tree.TreeName ?? "Unknown"
                }).ToList()
            }).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all illnesses");
            throw;
        }
    }

    public async Task<IllnessDto?> GetIllnessByIdAsync(int illnessId)
    {
        try
        {
            var illness = await _repository.GetIllnessByIdAsync(illnessId);
            
            if (illness == null)
                return null;

            return new IllnessDto
            {
                IllnessId = illness.IllnessId,
                IllnessName = illness.IllnessName ?? "Unknown",
                ScientificName = illness.ScientificName,
                Description = illness.Description,
                Symptoms = illness.Symptoms,
                Causes = illness.Causes,
                Severity = illness.Severity,
                CreatedAt = illness.CreatedAt,
                AffectedTrees = illness.TreeIllnessRelationships?.Select(r => new TreeSimpleDto
                {
                    TreeId = r.Tree.TreeId,
                    TreeName = r.Tree.TreeName ?? "Unknown"
                }).ToList()
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting illness by ID: {IllnessId}", illnessId);
            throw;
        }
    }

    public async Task<IllnessDto> CreateIllnessAsync(CreateIllnessDto createDto)
    {
        try
        {
            var illness = new TreeIllness
            {
                IllnessName = createDto.IllnessName,
                ScientificName = createDto.ScientificName,
                Description = createDto.Description,
                Symptoms = createDto.Symptoms,
                Causes = createDto.Causes,
                Severity = createDto.Severity,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            var created = await _repository.CreateIllnessAsync(illness);
            
            _logger.LogInformation("Illness created successfully: {IllnessId}", created.IllnessId);

            return new IllnessDto
            {
                IllnessId = created.IllnessId,
                IllnessName = created.IllnessName ?? "Unknown",
                ScientificName = created.ScientificName,
                Description = created.Description,
                Symptoms = created.Symptoms,
                Causes = created.Causes,
                Severity = created.Severity,
                CreatedAt = created.CreatedAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating illness");
            throw;
        }
    }

    public async Task<bool> UpdateIllnessAsync(int illnessId, UpdateIllnessDto updateDto)
    {
        try
        {
            var illness = new TreeIllness
            {
                IllnessId = illnessId,
                IllnessName = updateDto.IllnessName,
                ScientificName = updateDto.ScientificName,
                Description = updateDto.Description,
                Symptoms = updateDto.Symptoms,
                Causes = updateDto.Causes,
                Severity = updateDto.Severity
            };

            var result = await _repository.UpdateIllnessAsync(illness);
            
            if (result)
                _logger.LogInformation("Illness updated successfully: {IllnessId}", illnessId);
            else
                _logger.LogWarning("Illness not found for update: {IllnessId}", illnessId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating illness: {IllnessId}", illnessId);
            throw;
        }
    }

    public async Task<bool> DeleteIllnessAsync(int illnessId)
    {
        try
        {
            var result = await _repository.DeleteIllnessAsync(illnessId);
            
            if (result)
                _logger.LogInformation("Illness deleted successfully: {IllnessId}", illnessId);
            else
                _logger.LogWarning("Illness not found for deletion: {IllnessId}", illnessId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting illness: {IllnessId}", illnessId);
            throw;
        }
    }
}
