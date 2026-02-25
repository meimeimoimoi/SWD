using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories
{
    public class TreatmentSolutionRepository
    {
        private readonly AppDbContext _context;

        public TreatmentSolutionRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<List<TreatmentSolution>> GetSolutionByIllnessIdAsync(
            int illnessId,
            decimal? confidenceScore = null)
        {
            var query = _context.TreatmentSolutions
                .Include(ts => ts.Illness)
                .Include(ts => ts.TreeStage)
                .Include(ts => ts.SolutionConditions)
                .Where(ts => ts.IllnessId == illnessId);

            //Filter by confidence score if provided
            if (confidenceScore.HasValue)
            {
                query = query.Where(ts =>
                ts.MinConfidence == null ||
                ts.MinConfidence <= confidenceScore.Value);
            }

            return await query
                .OrderBy(ts => ts.Priority)
                .ToListAsync();
        }

        public async Task<TreatmentSolution?> GetSolutionByIdAsync(int solutionId)
        {
            return await _context.TreatmentSolutions
                .Include(ts => ts.Illness)
                .Include(ts => ts.TreeStage)
                .Include(ts => ts.SolutionConditions)
                .FirstOrDefaultAsync(ts => ts.SolutionId == solutionId);
        }

        public async Task<List<TreatmentSolution?>> GetAllSolutionsAsync()
        {
            return await _context.TreatmentSolutions
              .Include(ts => ts.Illness)
              .Include(ts => ts.TreeStage)
              .Include(ts => ts.SolutionConditions)
              .OrderBy(ts => ts.IllnessId)
              .ThenBy(ts => ts.Priority)
              .ToListAsync();
        }
    }
}
