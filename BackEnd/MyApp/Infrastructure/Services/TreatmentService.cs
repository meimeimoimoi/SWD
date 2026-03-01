using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Treatment.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services
{
    public class TreatmentService : ITreatmentService
    {
        private readonly AppDbContext _context;
        private readonly ILogger<TreatmentService> _logger;

        public TreatmentService(AppDbContext context, ILogger<TreatmentService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<DiseaseDetailDto?> GetDiseaseDetailAsync(int illnessId)
        {
            var illness = await _context.TreeIllnesses
                .Include(i => i.TreatmentSolutions)
                    .ThenInclude(s => s.TreeStage)
                .Include(i => i.TreatmentSolutions)
                    .ThenInclude(s => s.SolutionConditions)
                .FirstOrDefaultAsync(i => i.IllnessId == illnessId);

            if (illness == null) return null;

            return new DiseaseDetailDto
            {
                IllnessId = illness.IllnessId,
                IllnessName = illness.IllnessName,
                ScientificName = illness.ScientificName,
                Description = illness.Description,
                Symptoms = illness.Symptoms,
                Causes = illness.Causes,
                Severity = illness.Severity,
                TreatmentSolutions = illness.TreatmentSolutions
                    .OrderBy(s => s.Priority)
                    .Select(MapToSolutionDto)
                    .ToList()
            };
        }

        public async Task<List<TreatmentRecommendationDto>> GetRecommendationsByIllnessAsync(int illnessId)
        {
            var solutions = await _context.TreatmentSolutions
                .Include(s => s.TreeStage)
                .Include(s => s.SolutionConditions)
                .Include(s => s.Illness)
                .Where(s => s.IllnessId == illnessId)
                .OrderBy(s => s.Priority)
                .ToListAsync();

            return solutions.Select(MapToRecommendationDto).ToList();
        }

        public async Task<List<TreatmentRecommendationDto>> GetRecommendationsByIllnessStageAsync(int illnessId, int illnessStageId)
        {
            var solutions = await _context.TreatmentSolutions
                .Include(s => s.TreeStage)
                .Include(s => s.SolutionConditions)
                .Include(s => s.Illness)
                .Where(s => s.IllnessId == illnessId && s.IllnessStageId == illnessStageId)
                .OrderBy(s => s.Priority)
                .ToListAsync();

            return solutions.Select(MapToRecommendationDto).ToList();
        }

        public async Task<List<TreatmentRecommendationDto>> GetRecommendationsByTreeStageAsync(int treeStageId)
        {
            var solutions = await _context.TreatmentSolutions
                .Include(s => s.TreeStage)
                .Include(s => s.SolutionConditions)
                .Include(s => s.Illness)
                .Where(s => s.TreeStageId == treeStageId)
                .OrderBy(s => s.Priority)
                .ToListAsync();

            return solutions.Select(MapToRecommendationDto).ToList();
        }

        public async Task<TreatmentSolutionDto?> GetSolutionDetailAsync(int solutionId)
        {
            var solution = await _context.TreatmentSolutions
                .Include(s => s.TreeStage)
                .Include(s => s.SolutionConditions)
                .FirstOrDefaultAsync(s => s.SolutionId == solutionId);

            if (solution == null) return null;

            return MapToSolutionDto(solution);
        }

        // ?? Private helpers ?????????????????????????????????????????????????????

        private static TreatmentSolutionDto MapToSolutionDto(Domain.Entities.TreatmentSolution s) => new()
        {
            SolutionId = s.SolutionId,
            SolutionName = s.SolutionName,
            SolutionType = s.SolutionType,
            Description = s.Description,
            IllnessStageId = s.IllnessStageId,
            TreeStageId = s.TreeStageId,
            TreeStageName = s.TreeStage?.StageName,
            MinConfidence = s.MinConfidence,
            Priority = s.Priority,
            Conditions = s.SolutionConditions.Select(c => new SolutionConditionDto
            {
                ConditionId = c.ConditionId,
                MinConfidence = c.MinConfidence,
                WeatherCondition = c.WeatherCondition,
                Note = c.Note
            }).ToList()
        };

        private static TreatmentRecommendationDto MapToRecommendationDto(Domain.Entities.TreatmentSolution s) => new()
        {
            SolutionId = s.SolutionId,
            SolutionName = s.SolutionName,
            SolutionType = s.SolutionType,
            Description = s.Description,
            IllnessStageId = s.IllnessStageId,
            TreeStageId = s.TreeStageId,
            TreeStageName = s.TreeStage?.StageName,
            MinConfidence = s.MinConfidence,
            Priority = s.Priority,
            IllnessName = s.Illness?.IllnessName,
            Conditions = s.SolutionConditions.Select(c => new SolutionConditionDto
            {
                ConditionId = c.ConditionId,
                MinConfidence = c.MinConfidence,
                WeatherCondition = c.WeatherCondition,
                Note = c.Note
            }).ToList()
        };
    }
}
