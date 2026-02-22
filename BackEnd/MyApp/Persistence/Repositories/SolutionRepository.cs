using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories;

public class SolutionRepository
{
    private readonly AppDbContext _context;

    public SolutionRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<TreatmentSolution>> GetAllSolutionsAsync()
    {
        return await _context.TreatmentSolutions
            .Include(s => s.Illness)
            .Include(s => s.TreeStage)
            .Include(s => s.SolutionConditions)
            .OrderBy(s => s.Priority)
            .ThenBy(s => s.SolutionName)
            .ToListAsync();
    }

    public async Task<TreatmentSolution?> GetSolutionByIdAsync(int solutionId)
    {
        return await _context.TreatmentSolutions
            .Include(s => s.Illness)
            .Include(s => s.TreeStage)
            .Include(s => s.SolutionConditions)
            .FirstOrDefaultAsync(s => s.SolutionId == solutionId);
    }

    public async Task<List<TreatmentSolution>> GetSolutionsByIllnessIdAsync(int illnessId)
    {
        return await _context.TreatmentSolutions
            .Include(s => s.TreeStage)
            .Include(s => s.SolutionConditions)
            .Where(s => s.IllnessId == illnessId)
            .OrderBy(s => s.Priority)
            .ToListAsync();
    }

    public async Task<List<TreatmentSolution>> GetSolutionsByPredictionIdAsync(int predictionId)
    {
        // Get prediction with illness info
        var prediction = await _context.Predictions
            .Include(p => p.Illness)
            .FirstOrDefaultAsync(p => p.PredictionId == predictionId);

        if (prediction == null || prediction.IllnessId == null)
            return new List<TreatmentSolution>();

        // Get solutions for the illness, filtered by confidence
        var solutions = await _context.TreatmentSolutions
            .Include(s => s.TreeStage)
            .Include(s => s.SolutionConditions)
            .Where(s => s.IllnessId == prediction.IllnessId)
            .Where(s => s.MinConfidence == null || s.MinConfidence <= prediction.ConfidenceScore)
            .OrderBy(s => s.Priority)
            .ToListAsync();

        return solutions;
    }

    public async Task<TreatmentSolution> CreateSolutionAsync(TreatmentSolution solution)
    {
        _context.TreatmentSolutions.Add(solution);
        await _context.SaveChangesAsync();
        return solution;
    }

    public async Task<bool> UpdateSolutionAsync(TreatmentSolution solution)
    {
        var existing = await _context.TreatmentSolutions.FindAsync(solution.SolutionId);
        if (existing == null) return false;

        existing.SolutionName = solution.SolutionName;
        existing.SolutionType = solution.SolutionType;
        existing.Description = solution.Description;
        existing.Priority = solution.Priority;
        existing.MinConfidence = solution.MinConfidence;
        existing.TreeStageId = solution.TreeStageId;
        existing.IllnessId = solution.IllnessId;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteSolutionAsync(int solutionId)
    {
        var solution = await _context.TreatmentSolutions.FindAsync(solutionId);
        if (solution == null) return false;

        _context.TreatmentSolutions.Remove(solution);
        await _context.SaveChangesAsync();
        return true;
    }
}
