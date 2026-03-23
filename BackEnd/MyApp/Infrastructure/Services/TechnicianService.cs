using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Features.Technician.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services
{
    public class TechnicianService : ITechnicianService
    {
        private readonly AppDbContext _context;
        private readonly ILogger<TechnicianService> _logger;

        public TechnicianService(AppDbContext context, ILogger<TechnicianService> logger)
        {
            _context = context;
            _logger  = logger;
        }


        public async Task<List<IllnessDto>> GetAllIllnessesAsync()
        {
            _logger.LogInformation("Fetching all illnesses.");
            var illnesses = await _context.TreeIllnesses
                .OrderBy(i => i.IllnessId)
                .ToListAsync();
            return illnesses.Select(MapToIllnessDto).ToList();
        }

        public async Task<IllnessDto?> GetIllnessByIdAsync(int id)
        {
            var illness = await _context.TreeIllnesses.FindAsync(id);
            return illness == null ? null : MapToIllnessDto(illness);
        }

        public async Task<IllnessDto> CreateIllnessAsync(CreateIllnessDto dto)
        {
            var illness = new TreeIllness
            {
                IllnessName    = dto.IllnessName,
                ScientificName = dto.ScientificName,
                Description    = dto.Description,
                Symptoms       = dto.Symptoms,
                Causes         = dto.Causes,
                Severity       = dto.Severity,
                CreatedAt      = DateTime.UtcNow,
                UpdatedAt      = DateTime.UtcNow
            };
            _context.TreeIllnesses.Add(illness);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Illness created - Id={Id}, Name='{Name}'", illness.IllnessId, illness.IllnessName);
            return MapToIllnessDto(illness);
        }

        public async Task<IllnessDto?> UpdateIllnessAsync(int id, UpdateIllnessDto dto)
        {
            var illness = await _context.TreeIllnesses.FindAsync(id);
            if (illness == null) return null;

            if (dto.IllnessName    != null) illness.IllnessName    = dto.IllnessName;
            if (dto.ScientificName != null) illness.ScientificName = dto.ScientificName;
            if (dto.Description    != null) illness.Description    = dto.Description;
            if (dto.Symptoms       != null) illness.Symptoms       = dto.Symptoms;
            if (dto.Causes         != null) illness.Causes         = dto.Causes;
            if (dto.Severity       != null) illness.Severity       = dto.Severity;
            illness.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            _logger.LogInformation("Illness updated - Id={Id}", id);
            return MapToIllnessDto(illness);
        }

        public async Task<bool> DeleteIllnessAsync(int id)
        {
            var illness = await _context.TreeIllnesses.FindAsync(id);
            if (illness == null) return false;

            _context.TreeIllnesses.Remove(illness);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Illness deleted - Id={Id}", id);
            return true;
        }

        public async Task<(bool success, string message)> AssignIllnessToTreeAsync(int illnessId, int treeId)
        {
            var illnessExists = await _context.TreeIllnesses.AnyAsync(i => i.IllnessId == illnessId);
            if (!illnessExists)
                return (false, $"Illness with ID {illnessId} not found.");

            var treeExists = await _context.Trees.AnyAsync(t => t.TreeId == treeId);
            if (!treeExists)
                return (false, $"Tree with ID {treeId} not found.");

            var alreadyExists = await _context.TreeIllnessRelationships
                .AnyAsync(r => r.IllnessId == illnessId && r.TreeId == treeId);
            if (alreadyExists)
                return (false, $"Illness {illnessId} is already assigned to tree {treeId}.");

            _context.TreeIllnessRelationships.Add(new TreeIllnessRelationship
            {
                IllnessId = illnessId,
                TreeId    = treeId
            });
            await _context.SaveChangesAsync();
            _logger.LogInformation("Illness {IllnessId} assigned to tree {TreeId}.", illnessId, treeId);
            return (true, "Illness assigned to tree successfully.");
        }


        public async Task<List<TreeStageDto>> GetAllStagesAsync()
        {
            _logger.LogInformation("Fetching all tree stages.");
            var stages = await _context.TreeStages.OrderBy(s => s.StageId).ToListAsync();
            return stages.Select(MapToStageDto).ToList();
        }

        public async Task<TreeStageDto?> GetStageByIdAsync(int id)
        {
            var stage = await _context.TreeStages.FindAsync(id);
            return stage == null ? null : MapToStageDto(stage);
        }

        public async Task<TreeStageDto> CreateStageAsync(CreateTreeStageDto dto)
        {
            var stage = new TreeStage
            {
                StageName   = dto.StageName,
                Description = dto.Description,
                CreatedAt   = DateTime.UtcNow
            };
            _context.TreeStages.Add(stage);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Tree stage created - Id={Id}, Name='{Name}'", stage.StageId, stage.StageName);
            return MapToStageDto(stage);
        }

        public async Task<TreeStageDto?> UpdateStageAsync(int id, UpdateTreeStageDto dto)
        {
            var stage = await _context.TreeStages.FindAsync(id);
            if (stage == null) return null;

            if (dto.StageName   != null) stage.StageName   = dto.StageName;
            if (dto.Description != null) stage.Description = dto.Description;

            await _context.SaveChangesAsync();
            _logger.LogInformation("Tree stage updated - Id={Id}", id);
            return MapToStageDto(stage);
        }


        public async Task<List<TreatmentReviewDto>> GetAllTreatmentsAsync()
        {
            _logger.LogInformation("Fetching all treatment solutions.");
            var solutions = await _context.TreatmentSolutions
                .Include(s => s.Illness)
                .Include(s => s.TreeStage)
                .OrderBy(s => s.SolutionId)
                .ToListAsync();
            return solutions.Select(MapToTreatmentDto).ToList();
        }

        public async Task<TreatmentReviewDto> CreateTreatmentAsync(CreateTreatmentDto dto)
        {
            var solution = new TreatmentSolution
            {
                IllnessId     = dto.IllnessId,
                TreeStageId   = dto.TreeStageId,
                SolutionName  = dto.SolutionName,
                SolutionType  = dto.SolutionType,
                Description   = dto.Description,
                MinConfidence = dto.MinConfidence,
                Priority      = dto.Priority,
                CreatedAt     = DateTime.UtcNow
            };
            _context.TreatmentSolutions.Add(solution);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Treatment solution created - Id={Id}, Name='{Name}'", solution.SolutionId, solution.SolutionName);

            await _context.Entry(solution).Reference(s => s.Illness).LoadAsync();
            await _context.Entry(solution).Reference(s => s.TreeStage).LoadAsync();
            return MapToTreatmentDto(solution);
        }

        public async Task<(bool success, string message, TreatmentReviewDto? data)> AssignTreatmentToIllnessAsync(int solutionId, int illnessId)
        {
            var solution = await _context.TreatmentSolutions
                .Include(s => s.Illness)
                .Include(s => s.TreeStage)
                .FirstOrDefaultAsync(s => s.SolutionId == solutionId);

            if (solution == null)
                return (false, $"Treatment solution with ID {solutionId} not found.", null);

            var illnessExists = await _context.TreeIllnesses.AnyAsync(i => i.IllnessId == illnessId);
            if (!illnessExists)
                return (false, $"Illness with ID {illnessId} not found.", null);

            solution.IllnessId = illnessId;
            await _context.SaveChangesAsync();

            await _context.Entry(solution).Reference(s => s.Illness).LoadAsync();
            _logger.LogInformation("Treatment {SolutionId} assigned to illness {IllnessId}.", solutionId, illnessId);
            return (true, "Treatment assigned to illness successfully.", MapToTreatmentDto(solution));
        }


        private static IllnessDto MapToIllnessDto(TreeIllness i) => new()
        {
            IllnessId      = i.IllnessId,
            IllnessName    = i.IllnessName,
            ScientificName = i.ScientificName,
            Description    = i.Description,
            Symptoms       = i.Symptoms,
            Causes         = i.Causes,
            Severity       = i.Severity,
            CreatedAt      = i.CreatedAt,
            UpdatedAt      = i.UpdatedAt
        };

        private static TreeStageDto MapToStageDto(TreeStage s) => new()
        {
            StageId     = s.StageId,
            StageName   = s.StageName,
            Description = s.Description,
            CreatedAt   = s.CreatedAt
        };

        private static TreatmentReviewDto MapToTreatmentDto(TreatmentSolution s) => new()
        {
            SolutionId    = s.SolutionId,
            SolutionName  = s.SolutionName,
            SolutionType  = s.SolutionType,
            Description   = s.Description,
            IllnessId     = s.IllnessId,
            IllnessName   = s.Illness?.IllnessName,
            TreeStageId   = s.TreeStageId,
            TreeStageName = s.TreeStage?.StageName,
            MinConfidence = s.MinConfidence,
            Priority      = s.Priority,
            CreatedAt     = s.CreatedAt
        };
    }
}
