using MyApp.Application.Features.Trees.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;
using Microsoft.EntityFrameworkCore;

namespace MyApp.Infrastructure.Services;

public class TreeService : ITreeService
{
    private readonly AppDbContext _context;

    public TreeService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<TreeDto>> GetAllTreesAsync()
    {
        return await _context.Trees
            .Select(t => new TreeDto
            {
                TreeId = t.TreeId,
                TreeName = t.TreeName ?? "",
                ScientificName = t.ScientificName,
                Description = t.Description
            })
            .ToListAsync();
    }

    public async Task<int> CreateTreeAsync(CreateTreeDto dto)
    {
        var tree = new Tree
        {
            TreeName = dto.TreeName,
            ScientificName = dto.ScientificName,
            Description = dto.Description,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Trees.Add(tree);
        await _context.SaveChangesAsync();
        return tree.TreeId;
    }

    public async Task<bool> UpdateTreeAsync(int id, UpdateTreeDto dto)
    {
        var tree = await _context.Trees.FindAsync(id);
        if (tree == null) return false;

        tree.TreeName = dto.TreeName;
        tree.ScientificName = dto.ScientificName;
        tree.Description = dto.Description;
        tree.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteTreeAsync(int id)
    {
        var tree = await _context.Trees.FindAsync(id);
        if (tree == null) return false;

        _context.Trees.Remove(tree);
        await _context.SaveChangesAsync();
        return true;
    }
}
