using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories
{
    public class TreeStageRepository
    {
        private readonly AppDbContext _context;

        public TreeStageRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<List<TreeStage>> GetAllStagesAsync()
        {
            return await _context.TreeStages
                .Include(s => s.TreatmentSolutions)
                .OrderBy(s => s.StageName)
                .ToListAsync();
        }

        public async Task<TreeStage?> GetStageByIdAsync(int stageId)
        {
            return await _context.TreeStages
                .Include(s => s.TreatmentSolutions)
                .FirstOrDefaultAsync(s => s.StageId == stageId);
        }

        public async Task<TreeStage> CreateStageAsync(TreeStage stage)
        {
            stage.CreatedAt = DateTime.UtcNow;

            _context.TreeStages.Add(stage);
            await _context.SaveChangesAsync();

            return stage;
        }

        public async Task<TreeStage> UpdateStageAsync(TreeStage stage)
        {
            _context.TreeStages.Update(stage);
            await _context.SaveChangesAsync();

            return stage;
        }

        public async Task DeleteStageAsync(TreeStage stage)
        {
            _context.TreeStages.Remove(stage);
            await _context.SaveChangesAsync();
        }

        public async Task<bool> ExistsByNameAsync(string stageName)
        {
            return await _context.TreeStages
                .AnyAsync(s => s.StageName != null &&
                              s.StageName.ToLower() == stageName.ToLower());
        }


        public async Task<bool> ExistsByNameExcludingIdAsync(string stageName, int excludeStageId)
        {
            return await _context.TreeStages
                .AnyAsync(s => s.StageId != excludeStageId &&
                              s.StageName != null &&
                              s.StageName.ToLower() == stageName.ToLower());
        }

        public async Task<bool> HasTreatmentSolutionsAsync(int stageId)
        {
            return await _context.TreatmentSolutions
                .AnyAsync(ts => ts.TreeStageId == stageId);
        }
    }
}
