using MyApp.Application.Features.Models.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Persistence.Context;
using Microsoft.EntityFrameworkCore;

namespace MyApp.Infrastructure.Services;

public class ModelVersionService : IModelVersionService
{
    private readonly AppDbContext _context;

    public ModelVersionService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<ModelVersionDto>> GetAllModelsAsync()
    {
        return await _context.ModelVersions
            .Select(m => new ModelVersionDto
            {
                ModelVersionId = m.ModelVersionId,
                ModelName = m.ModelName,
                Version = m.Version,
                IsActive = m.IsActive ?? false,
                IsDefault = m.IsDefault ?? false
            })
            .ToListAsync();
    }

    public async Task<bool> ActivateModelAsync(int modelId, bool isActive)
    {
        var model = await _context.ModelVersions.FindAsync(modelId);
        if (model == null) return false;

        model.IsActive = isActive;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SetDefaultModelAsync(int modelId)
    {
        var model = await _context.ModelVersions.FindAsync(modelId);
        if (model == null) return false;

        // Reset all defaults
        await _context.ModelVersions
            .Where(m => m.IsDefault == true)
            .ExecuteUpdateAsync(m => m.SetProperty(x => x.IsDefault, false));

        // Set new default
        model.IsDefault = true;
        model.IsActive = true;
        await _context.SaveChangesAsync();
        return true;
    }
}
