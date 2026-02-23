using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories;

public class ModelRepository
{
    private readonly AppDbContext _context;

    public ModelRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<ModelVersion>> GetAllModelsAsync()
    {
        return await _context.ModelVersions
            .OrderByDescending(m => m.IsDefault)
            .ThenByDescending(m => m.CreatedAt)
            .ToListAsync();
    }

    public async Task<ModelVersion?> GetModelByIdAsync(int modelVersionId)
    {
        return await _context.ModelVersions
            .FirstOrDefaultAsync(m => m.ModelVersionId == modelVersionId);
    }

    public async Task<ModelVersion?> GetDefaultModelAsync()
    {
        return await _context.ModelVersions
            .Where(m => m.IsActive == true)
            .OrderByDescending(m => m.IsDefault)
            .ThenByDescending(m => m.CreatedAt)
            .FirstOrDefaultAsync();
    }

    public async Task<ModelVersion?> GetLatestActiveModelAsync()
    {
        return await _context.ModelVersions
            .Where(m => m.IsActive == true)
            .OrderByDescending(m => m.CreatedAt)
            .FirstOrDefaultAsync();
    }

    public async Task<ModelVersion?> GetLatestModelByNameAsync(string modelName)
    {
        return await _context.ModelVersions
            .Where(m => m.ModelName == modelName && m.IsActive == true)
            .OrderByDescending(m => m.CreatedAt)
            .FirstOrDefaultAsync();
    }

    public async Task<bool> ActivateModelAsync(int modelVersionId)
    {
        var model = await _context.ModelVersions.FindAsync(modelVersionId);
        if (model == null) return false;

        model.IsActive = true;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeactivateModelAsync(int modelVersionId)
    {
        var model = await _context.ModelVersions.FindAsync(modelVersionId);
        if (model == null) return false;

        // Don't allow deactivating the default model
        if (model.IsDefault == true)
            throw new InvalidOperationException("Cannot deactivate the default model. Set another model as default first.");

        model.IsActive = false;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<ModelThreshold?> GetThresholdByModelIdAsync(int modelVersionId)
    {
        return await _context.ModelThresholds
            .FirstOrDefaultAsync(t => t.ModelVersionId == modelVersionId);
    }

    public async Task<bool> UpdateThresholdAsync(int modelVersionId, decimal minConfidence)
    {
        var threshold = await GetThresholdByModelIdAsync(modelVersionId);
        
        if (threshold == null)
        {
            // Create new threshold
            threshold = new ModelThreshold
            {
                ModelVersionId = modelVersionId,
                MinConfidence = minConfidence,
                CreatedAt = DateTime.UtcNow
            };
            _context.ModelThresholds.Add(threshold);
        }
        else
        {
            // Update existing threshold
            threshold.MinConfidence = minConfidence;
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<ModelVersion?> CreateModelVersionAsync(ModelVersion model)
    {
        _context.ModelVersions.Add(model);
        await _context.SaveChangesAsync();
        return model;
    }

    public async Task<bool> SetDefaultModelAsync(int modelVersionId)
    {
        var model = await _context.ModelVersions.FindAsync(modelVersionId);
        if (model == null) return false;

        // Remove default from all other models
        var currentDefault = await _context.ModelVersions
            .Where(m => m.IsDefault == true)
            .ToListAsync();

        foreach (var m in currentDefault)
        {
            m.IsDefault = false;
        }

        // Set this model as default and active
        model.IsDefault = true;
        model.IsActive = true;

        await _context.SaveChangesAsync();
        return true;
    }
}
