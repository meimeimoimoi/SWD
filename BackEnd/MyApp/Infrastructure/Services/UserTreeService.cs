using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services;

public class UserTreeService : IUserTreeService
{
    private readonly AppDbContext _context;
    private readonly ILogger<UserTreeService> _logger;

    public UserTreeService(AppDbContext context, ILogger<UserTreeService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<List<UserTreeListItemDto>> GetTreesForUserAsync(int userId)
    {
        var treeIds = await _context.Predictions
            .AsNoTracking()
            .Where(p => p.Upload.UserId == userId && p.TreeId != null)
            .Select(p => p.TreeId!.Value)
            .Distinct()
            .ToListAsync();

        if (treeIds.Count == 0)
            return new List<UserTreeListItemDto>();

        var trees = await _context.Trees
            .AsNoTracking()
            .Where(t => treeIds.Contains(t.TreeId))
            .OrderBy(t => t.TreeName)
            .Select(t => new UserTreeListItemDto
            {
                TreeId = t.TreeId,
                TreeName = t.TreeName,
                ScientificName = t.ScientificName,
                ImagePath = t.ImagePath,
            })
            .ToListAsync();

        return trees;
    }

    public async Task<UserTreeListItemDto> CreateTreeAsync(CreateUserTreeDto dto)
    {
        var now = DateTime.UtcNow;
        var tree = new Tree
        {
            TreeName = dto.TreeName.Trim(),
            ScientificName = string.IsNullOrWhiteSpace(dto.ScientificName)
                ? null
                : dto.ScientificName.Trim(),
            Description = string.IsNullOrWhiteSpace(dto.Description)
                ? null
                : dto.Description.Trim(),
            CreatedAt = now,
            UpdatedAt = now,
        };

        _context.Trees.Add(tree);
        await _context.SaveChangesAsync();

        _logger.LogInformation("User tree created TreeId={TreeId}", tree.TreeId);

        return new UserTreeListItemDto
        {
            TreeId = tree.TreeId,
            TreeName = tree.TreeName,
            ScientificName = tree.ScientificName,
            ImagePath = tree.ImagePath,
        };
    }

    public async Task<(bool Success, string Message)> AssignPredictionToTreeAsync(
        int userId,
        int predictionId,
        int treeId)
    {
        var prediction = await _context.Predictions
            .Include(p => p.Upload)
            .FirstOrDefaultAsync(p => p.PredictionId == predictionId && p.Upload.UserId == userId);

        if (prediction == null)
            return (false, "Prediction not found or access denied.");

        var treeExists = await _context.Trees.AnyAsync(t => t.TreeId == treeId);
        if (!treeExists)
            return (false, $"Tree with ID {treeId} was not found.");

        prediction.TreeId = treeId;

        if (prediction.IllnessId is { } illnessId)
        {
            var relExists = await _context.TreeIllnessRelationships
                .AnyAsync(r => r.IllnessId == illnessId && r.TreeId == treeId);
            if (!relExists)
            {
                _context.TreeIllnessRelationships.Add(new TreeIllnessRelationship
                {
                    IllnessId = illnessId,
                    TreeId = treeId,
                });
            }
        }

        await _context.SaveChangesAsync();
        _logger.LogInformation(
            "Prediction {PredictionId} assigned to tree {TreeId} for user {UserId}",
            predictionId, treeId, userId);

        return (true, "Scan assigned to tree successfully.");
    }
}
