using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories;

public class TreeDataRepository
{
    private readonly AppDbContext _context;

    public TreeDataRepository(AppDbContext context)
    {
        _context = context;
    }

    #region Trees

    public async Task<List<Tree>> GetAllTreesAsync()
    {
        return await _context.Trees
            .Include(t => t.TreeIllnessRelationships)
                .ThenInclude(r => r.Illness)
            .OrderBy(t => t.TreeName)
            .ToListAsync();
    }

    public async Task<Tree?> GetTreeByIdAsync(int treeId)
    {
        return await _context.Trees
            .Include(t => t.TreeIllnessRelationships)
                .ThenInclude(r => r.Illness)
            .FirstOrDefaultAsync(t => t.TreeId == treeId);
    }

    public async Task<Tree> CreateTreeAsync(Tree tree)
    {
        _context.Trees.Add(tree);
        await _context.SaveChangesAsync();
        return tree;
    }

    public async Task<bool> UpdateTreeAsync(Tree tree)
    {
        var existing = await _context.Trees.FindAsync(tree.TreeId);
        if (existing == null) return false;

        existing.TreeName = tree.TreeName;
        existing.ScientificName = tree.ScientificName;
        existing.Description = tree.Description;
        existing.ImagePath = tree.ImagePath;
        existing.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteTreeAsync(int treeId)
    {
        var tree = await _context.Trees.FindAsync(treeId);
        if (tree == null) return false;

        _context.Trees.Remove(tree);
        await _context.SaveChangesAsync();
        return true;
    }

    #endregion

    #region Tree Illnesses

    public async Task<List<TreeIllness>> GetAllIllnessesAsync()
    {
        return await _context.TreeIllnesses
            .Include(i => i.TreeIllnessRelationships)
                .ThenInclude(r => r.Tree)
            .OrderBy(i => i.IllnessName)
            .ToListAsync();
    }

    public async Task<TreeIllness?> GetIllnessByIdAsync(int illnessId)
    {
        return await _context.TreeIllnesses
            .Include(i => i.TreeIllnessRelationships)
                .ThenInclude(r => r.Tree)
            .FirstOrDefaultAsync(i => i.IllnessId == illnessId);
    }

    public async Task<TreeIllness> CreateIllnessAsync(TreeIllness illness)
    {
        _context.TreeIllnesses.Add(illness);
        await _context.SaveChangesAsync();
        return illness;
    }

    public async Task<bool> UpdateIllnessAsync(TreeIllness illness)
    {
        var existing = await _context.TreeIllnesses.FindAsync(illness.IllnessId);
        if (existing == null) return false;

        existing.IllnessName = illness.IllnessName;
        existing.ScientificName = illness.ScientificName;
        existing.Description = illness.Description;
        existing.Symptoms = illness.Symptoms;
        existing.Causes = illness.Causes;
        existing.Severity = illness.Severity;
        existing.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteIllnessAsync(int illnessId)
    {
        var illness = await _context.TreeIllnesses.FindAsync(illnessId);
        if (illness == null) return false;

        _context.TreeIllnesses.Remove(illness);
        await _context.SaveChangesAsync();
        return true;
    }

    #endregion

    #region Tree-Illness Relationships

    public async Task<TreeIllnessRelationship?> MapTreeIllnessAsync(int treeId, int illnessId)
    {
        // Check if mapping already exists
        var existing = await _context.TreeIllnessRelationships
            .FirstOrDefaultAsync(r => r.TreeId == treeId && r.IllnessId == illnessId);

        if (existing != null)
            return existing;

        // Verify tree and illness exist
        var treeExists = await _context.Trees.AnyAsync(t => t.TreeId == treeId);
        var illnessExists = await _context.TreeIllnesses.AnyAsync(i => i.IllnessId == illnessId);

        if (!treeExists || !illnessExists)
            return null;

        var relationship = new TreeIllnessRelationship
        {
            TreeId = treeId,
            IllnessId = illnessId
        };

        _context.TreeIllnessRelationships.Add(relationship);
        await _context.SaveChangesAsync();

        return relationship;
    }

    public async Task<bool> UnmapTreeIllnessAsync(int treeId, int illnessId)
    {
        var relationship = await _context.TreeIllnessRelationships
            .FirstOrDefaultAsync(r => r.TreeId == treeId && r.IllnessId == illnessId);

        if (relationship == null) return false;

        _context.TreeIllnessRelationships.Remove(relationship);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<List<TreeIllnessRelationship>> GetTreeIllnessRelationshipsAsync(int treeId)
    {
        return await _context.TreeIllnessRelationships
            .Include(r => r.Illness)
            .Where(r => r.TreeId == treeId)
            .ToListAsync();
    }

    #endregion

    #region Tree Stages

    public async Task<List<TreeStage>> GetAllTreeStagesAsync()
    {
        return await _context.TreeStages
            .OrderBy(s => s.StageName)
            .ToListAsync();
    }

    public async Task<TreeStage?> GetTreeStageByIdAsync(int stageId)
    {
        return await _context.TreeStages.FindAsync(stageId);
    }

    #endregion
}
