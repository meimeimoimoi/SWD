using MyApp.Application.Features.Illnesses.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;
using Microsoft.EntityFrameworkCore;

namespace MyApp.Infrastructure.Services;

public class IllnessService : IIllnessService
{
    private readonly AppDbContext _context;

    public IllnessService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<IllnessDto>> GetAllIllnessesAsync()
    {
        return await _context.TreeIllnesses
            .Select(i => new IllnessDto
            {
                IllnessId = i.IllnessId,
                IllnessName = i.IllnessName ?? "",
                ScientificName = i.ScientificName,
                Severity = i.Severity,
                Description = i.Description
            })
            .ToListAsync();
    }

    public async Task<int> CreateIllnessAsync(CreateIllnessDto dto)
    {
        var illness = new TreeIllness
        {
            IllnessName = dto.IllnessName,
            ScientificName = dto.ScientificName,
            Description = dto.Description,
            Symptoms = dto.Symptoms,
            Causes = dto.Causes,
            Severity = dto.Severity,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.TreeIllnesses.Add(illness);
        await _context.SaveChangesAsync();
        return illness.IllnessId;
    }

    public async Task<bool> UpdateIllnessAsync(int id, UpdateIllnessDto dto)
    {
        var illness = await _context.TreeIllnesses.FindAsync(id);
        if (illness == null) return false;

        illness.IllnessName = dto.IllnessName;
        illness.ScientificName = dto.ScientificName;
        illness.Description = dto.Description;
        illness.Symptoms = dto.Symptoms;
        illness.Causes = dto.Causes;
        illness.Severity = dto.Severity;
        illness.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteIllnessAsync(int id)
    {
        var illness = await _context.TreeIllnesses.FindAsync(id);
        if (illness == null) return false;

        _context.TreeIllnesses.Remove(illness);
        await _context.SaveChangesAsync();
        return true;
    }
}
