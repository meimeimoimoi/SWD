using MyApp.Application.Features.Solutions.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;
using Microsoft.EntityFrameworkCore;

namespace MyApp.Infrastructure.Services;

public class SolutionService : ISolutionService
{
    private readonly AppDbContext _context;

    public SolutionService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<SolutionByPredictionDto?> GetSolutionsByPredictionAsync(int predictionId)
    {
        var prediction = await _context.Predictions
            .Include(p => p.Illness)
            .ThenInclude(i => i!.TreatmentSolutions)
            .FirstOrDefaultAsync(p => p.PredictionId == predictionId);

        if (prediction?.IllnessId == null) return null;

        var solutions = await _context.TreatmentSolutions
            .Where(s => s.IllnessId == prediction.IllnessId)
            .OrderBy(s => s.Priority)
            .Select(s => new SolutionItemDto
            {
                SolutionId = s.SolutionId,
                SolutionName = s.SolutionName ?? "",
                SolutionType = s.SolutionType,
                Description = s.Description,
                Priority = s.Priority ?? 0
            })
            .ToListAsync();

        return new SolutionByPredictionDto
        {
            PredictionId = predictionId,
            Solutions = solutions
        };
    }

    public async Task<SolutionByIllnessDto?> GetSolutionsByIllnessAsync(int illnessId)
    {
        var illness = await _context.TreeIllnesses
            .Include(i => i.TreatmentSolutions)
            .FirstOrDefaultAsync(i => i.IllnessId == illnessId);

        if (illness == null) return null;

        var solutions = await _context.TreatmentSolutions
            .Where(s => s.IllnessId == illnessId)
            .OrderBy(s => s.Priority)
            .Select(s => new SolutionItemDto
            {
                SolutionId = s.SolutionId,
                SolutionName = s.SolutionName ?? "",
                SolutionType = s.SolutionType,
                Description = s.Description,
                Priority = s.Priority ?? 0
            })
            .ToListAsync();

        return new SolutionByIllnessDto
        {
            IllnessId = illnessId,
            IllnessName = illness.IllnessName ?? "",
            Solutions = solutions
        };
    }

    public async Task<int> CreateSolutionAsync(CreateSolutionDto dto)
    {
        // Validate
        if (dto.Priority < 1)
            throw new ArgumentException("Priority must be >= 1");

        if (!await _context.TreeIllnesses.AnyAsync(i => i.IllnessId == dto.IllnessId))
            throw new ArgumentException("Illness not found");

        if (!await _context.TreeStages.AnyAsync(t => t.StageId == dto.TreeStageId))
            throw new ArgumentException("TreeStage not found");

        var solution = new TreatmentSolution
        {
            IllnessId = dto.IllnessId,
            TreeStageId = dto.TreeStageId,
            SolutionName = dto.SolutionName,
            SolutionType = dto.SolutionType,
            Description = dto.Description,
            Priority = dto.Priority,
            MinConfidence = dto.MinConfidence,
            CreatedAt = DateTime.UtcNow
        };

        _context.TreatmentSolutions.Add(solution);
        await _context.SaveChangesAsync();

        return solution.SolutionId;
    }

    public async Task<bool> UpdateSolutionAsync(int id, UpdateSolutionDto dto)
    {
        var solution = await _context.TreatmentSolutions.FindAsync(id);
        if (solution == null) return false;

        // Validate
        if (dto.Priority < 1)
            throw new ArgumentException("Priority must be >= 1");

        if (!await _context.TreeIllnesses.AnyAsync(i => i.IllnessId == dto.IllnessId))
            throw new ArgumentException("Illness not found");

        if (!await _context.TreeStages.AnyAsync(t => t.StageId == dto.TreeStageId))
            throw new ArgumentException("TreeStage not found");

        solution.IllnessId = dto.IllnessId;
        solution.TreeStageId = dto.TreeStageId;
        solution.SolutionName = dto.SolutionName;
        solution.SolutionType = dto.SolutionType;
        solution.Description = dto.Description;
        solution.Priority = dto.Priority;
        solution.MinConfidence = dto.MinConfidence;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteSolutionAsync(int id)
    {
        var solution = await _context.TreatmentSolutions.FindAsync(id);
        if (solution == null) return false;

        _context.TreatmentSolutions.Remove(solution);
        await _context.SaveChangesAsync();
        return true;
    }
}
