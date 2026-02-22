using Microsoft.Extensions.Logging;
using MyApp.Application.Features.Trees.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services;

public class TreeService : ITreeService
{
    private readonly TreeDataRepository _repository;
    private readonly ILogger<TreeService> _logger;

    public TreeService(TreeDataRepository repository, ILogger<TreeService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<List<TreeDto>> GetAllTreesAsync()
    {
        try
        {
            var trees = await _repository.GetAllTreesAsync();
            
            return trees.Select(t => new TreeDto
            {
                TreeId = t.TreeId,
                TreeName = t.TreeName ?? "Unknown",
                ScientificName = t.ScientificName,
                Description = t.Description,
                ImagePath = t.ImagePath,
                CreatedAt = t.CreatedAt,
                Illnesses = t.TreeIllnessRelationships?.Select(r => new TreeIllnessDto
                {
                    IllnessId = r.Illness.IllnessId,
                    IllnessName = r.Illness.IllnessName ?? "Unknown",
                    Severity = r.Illness.Severity
                }).ToList()
            }).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all trees");
            throw;
        }
    }

    public async Task<TreeDto?> GetTreeByIdAsync(int treeId)
    {
        try
        {
            var tree = await _repository.GetTreeByIdAsync(treeId);
            
            if (tree == null)
                return null;

            return new TreeDto
            {
                TreeId = tree.TreeId,
                TreeName = tree.TreeName ?? "Unknown",
                ScientificName = tree.ScientificName,
                Description = tree.Description,
                ImagePath = tree.ImagePath,
                CreatedAt = tree.CreatedAt,
                Illnesses = tree.TreeIllnessRelationships?.Select(r => new TreeIllnessDto
                {
                    IllnessId = r.Illness.IllnessId,
                    IllnessName = r.Illness.IllnessName ?? "Unknown",
                    Severity = r.Illness.Severity
                }).ToList()
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting tree by ID: {TreeId}", treeId);
            throw;
        }
    }

    public async Task<TreeDto> CreateTreeAsync(CreateTreeDto createDto)
    {
        try
        {
            var tree = new Tree
            {
                TreeName = createDto.TreeName,
                ScientificName = createDto.ScientificName,
                Description = createDto.Description,
                ImagePath = createDto.ImagePath,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            var created = await _repository.CreateTreeAsync(tree);
            
            _logger.LogInformation("Tree created successfully: {TreeId}", created.TreeId);

            return new TreeDto
            {
                TreeId = created.TreeId,
                TreeName = created.TreeName ?? "Unknown",
                ScientificName = created.ScientificName,
                Description = created.Description,
                ImagePath = created.ImagePath,
                CreatedAt = created.CreatedAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating tree");
            throw;
        }
    }

    public async Task<bool> UpdateTreeAsync(int treeId, UpdateTreeDto updateDto)
    {
        try
        {
            var tree = new Tree
            {
                TreeId = treeId,
                TreeName = updateDto.TreeName,
                ScientificName = updateDto.ScientificName,
                Description = updateDto.Description,
                ImagePath = updateDto.ImagePath
            };

            var result = await _repository.UpdateTreeAsync(tree);
            
            if (result)
                _logger.LogInformation("Tree updated successfully: {TreeId}", treeId);
            else
                _logger.LogWarning("Tree not found for update: {TreeId}", treeId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating tree: {TreeId}", treeId);
            throw;
        }
    }

    public async Task<bool> DeleteTreeAsync(int treeId)
    {
        try
        {
            var result = await _repository.DeleteTreeAsync(treeId);
            
            if (result)
                _logger.LogInformation("Tree deleted successfully: {TreeId}", treeId);
            else
                _logger.LogWarning("Tree not found for deletion: {TreeId}", treeId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting tree: {TreeId}", treeId);
            throw;
        }
    }
}
