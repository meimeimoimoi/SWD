using Microsoft.Extensions.Logging;
using MyApp.Application.Interfaces;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services;

public class TreeIllnessService : ITreeIllnessService
{
    private readonly TreeDataRepository _repository;
    private readonly ILogger<TreeIllnessService> _logger;

    public TreeIllnessService(TreeDataRepository repository, ILogger<TreeIllnessService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<bool> MapTreeIllnessAsync(int treeId, int illnessId)
    {
        try
        {
            var result = await _repository.MapTreeIllnessAsync(treeId, illnessId);
            
            if (result != null)
            {
                _logger.LogInformation("Tree-Illness mapping created: TreeId={TreeId}, IllnessId={IllnessId}", treeId, illnessId);
                return true;
            }

            _logger.LogWarning("Failed to create Tree-Illness mapping: TreeId={TreeId}, IllnessId={IllnessId}", treeId, illnessId);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error mapping tree-illness: TreeId={TreeId}, IllnessId={IllnessId}", treeId, illnessId);
            throw;
        }
    }

    public async Task<bool> UnmapTreeIllnessAsync(int treeId, int illnessId)
    {
        try
        {
            var result = await _repository.UnmapTreeIllnessAsync(treeId, illnessId);
            
            if (result)
                _logger.LogInformation("Tree-Illness mapping removed: TreeId={TreeId}, IllnessId={IllnessId}", treeId, illnessId);
            else
                _logger.LogWarning("Tree-Illness mapping not found: TreeId={TreeId}, IllnessId={IllnessId}", treeId, illnessId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error unmapping tree-illness: TreeId={TreeId}, IllnessId={IllnessId}", treeId, illnessId);
            throw;
        }
    }
}
