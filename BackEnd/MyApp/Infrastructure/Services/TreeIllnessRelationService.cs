using MyApp.Application.Features.TreeIllnessRelations.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;
using Microsoft.EntityFrameworkCore;

namespace MyApp.Infrastructure.Services;

public class TreeIllnessRelationService : ITreeIllnessRelationService
{
    private readonly AppDbContext _context;

    public TreeIllnessRelationService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<bool> MapTreeIllnessAsync(MapTreeIllnessDto dto)
    {
        // Validate tree exists
        if (!await _context.Trees.AnyAsync(t => t.TreeId == dto.TreeId))
            throw new ArgumentException("Tree not found");

        // Validate illness exists
        if (!await _context.TreeIllnesses.AnyAsync(i => i.IllnessId == dto.IllnessId))
            throw new ArgumentException("Illness not found");

        // Check duplicate
        var exists = await _context.TreeIllnessRelationships
            .AnyAsync(r => r.TreeId == dto.TreeId && r.IllnessId == dto.IllnessId);

        if (exists)
            throw new InvalidOperationException("Mapping already exists");

        var relation = new TreeIllnessRelationship
        {
            TreeId = dto.TreeId,
            IllnessId = dto.IllnessId
        };

        _context.TreeIllnessRelationships.Add(relation);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UnmapTreeIllnessAsync(MapTreeIllnessDto dto)
    {
        var relation = await _context.TreeIllnessRelationships
            .FirstOrDefaultAsync(r => r.TreeId == dto.TreeId && r.IllnessId == dto.IllnessId);

        if (relation == null) return false;

        _context.TreeIllnessRelationships.Remove(relation);
        await _context.SaveChangesAsync();
        return true;
    }
}
