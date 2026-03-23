using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Features.ModelManagement.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Persistence.Context;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
    public class ReviewService : IReviewService
    {
        private readonly AppDbContext _context;
        private readonly ModelRepository _modelRepository;
        private readonly ILogger<ReviewService> _logger;

        public ReviewService(
            AppDbContext context,
            ModelRepository modelRepository,
            ILogger<ReviewService> logger)
        {
            _context         = context;
            _modelRepository = modelRepository;
            _logger          = logger;
        }


        public async Task<List<TreatmentReviewDto>> GetAllTreatmentsAsync()
        {
            _logger.LogInformation("Fetching all treatment solutions for review.");
            var solutions = await _context.TreatmentSolutions
                .Include(s => s.Illness)
                .Include(s => s.TreeStage)
                .OrderBy(s => s.IllnessId)
                .ThenBy(s => s.Priority)
                .ToListAsync();

            return solutions.Select(MapToReviewDto).ToList();
        }

        public async Task<TreatmentReviewDto?> GetTreatmentByIdAsync(int solutionId)
        {
            var s = await _context.TreatmentSolutions
                .Include(s => s.Illness)
                .Include(s => s.TreeStage)
                .FirstOrDefaultAsync(s => s.SolutionId == solutionId);
            return s == null ? null : MapToReviewDto(s);
        }

        public async Task<TreatmentReviewDto?> UpdateTreatmentAsync(int solutionId, UpdateTreatmentDto dto)
        {
            var solution = await _context.TreatmentSolutions
                .Include(s => s.Illness)
                .Include(s => s.TreeStage)
                .FirstOrDefaultAsync(s => s.SolutionId == solutionId);

            if (solution == null) return null;

            if (dto.SolutionName  != null) solution.SolutionName  = dto.SolutionName;
            if (dto.SolutionType  != null) solution.SolutionType  = dto.SolutionType;
            if (dto.Description   != null) solution.Description   = dto.Description;
            if (dto.MinConfidence != null) solution.MinConfidence  = dto.MinConfidence;
            if (dto.Priority      != null) solution.Priority       = dto.Priority;

            await _context.SaveChangesAsync();
            _logger.LogInformation("Treatment solution Id={Id} updated.", solutionId);
            return MapToReviewDto(solution);
        }

        public async Task<bool> DeleteTreatmentAsync(int solutionId)
        {
            var solution = await _context.TreatmentSolutions.FindAsync(solutionId);
            if (solution == null) return false;

            _context.TreatmentSolutions.Remove(solution);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Treatment solution Id={Id} deleted.", solutionId);
            return true;
        }


        public async Task<List<ModelVersionDto>> GetAllModelsAsync()
        {
            var models = await _modelRepository.GetAllAsync();
            return models.Select(m => new ModelVersionDto
            {
                ModelVersionId = m.ModelVersionId,
                ModelName      = m.ModelName,
                Version        = m.Version,
                ModelType      = m.ModelType,
                Description    = m.Description,
                IsActive       = m.IsActive,
                IsDefault      = m.IsDefault,
                CreatedAt      = m.CreatedAt,
                FilePath       = m.FilePath
            }).ToList();
        }

        public async Task<ModelVersionDto?> ActivateModelAsync(int modelVersionId)
        {
            var model = await _modelRepository.GetByIdAsync(modelVersionId);
            if (model == null) return null;

            var others = await _modelRepository.GetAllDefaultsExceptAsync(modelVersionId);
            foreach (var m in others) { m.IsActive = false; m.IsDefault = false; }
            if (others.Count > 0)
                await _modelRepository.UpdateRangeAsync(others);

            model.IsActive  = true;
            model.IsDefault = true;
            await _modelRepository.UpdateAsync(model);

            _logger.LogInformation(
                "Model Id={Id} ({Name} v{Version}) activated.", model.ModelVersionId, model.ModelName, model.Version);

            return new ModelVersionDto
            {
                ModelVersionId = model.ModelVersionId,
                ModelName      = model.ModelName,
                Version        = model.Version,
                ModelType      = model.ModelType,
                IsActive       = model.IsActive,
                IsDefault      = model.IsDefault,
                CreatedAt      = model.CreatedAt,
                FilePath       = model.FilePath
            };
        }

        public async Task<bool> DeactivateModelAsync(int modelVersionId)
        {
            var model = await _modelRepository.GetByIdAsync(modelVersionId);
            if (model == null) return false;

            model.IsActive  = false;
            model.IsDefault = false;
            await _modelRepository.UpdateAsync(model);

            _logger.LogInformation("Model Id={Id} deactivated.", modelVersionId);
            return true;
        }


        private static TreatmentReviewDto MapToReviewDto(Domain.Entities.TreatmentSolution s) => new()
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
