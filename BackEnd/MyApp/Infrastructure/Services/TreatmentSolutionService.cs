using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
    public class TreatmentSolutionService : ITreatmentSolutionService
    {
        private readonly TreatmentSolutionRepository _treatmentSolutionRepository;
        private readonly PredictionRepository _predictionRepository;
        private readonly ILogger<TreatmentSolutionService> _logger;

        public TreatmentSolutionService(
            TreatmentSolutionRepository treatmentSolutionRepository,
            PredictionRepository predictionRepository,
            ILogger<TreatmentSolutionService> logger)
        {
            _treatmentSolutionRepository = treatmentSolutionRepository;
            _predictionRepository = predictionRepository;
            _logger = logger;
        }

        public async Task<List<TreatmentSolutionResponseDto>> GetAllSolutionsAsync()
        {
            try
            {
                _logger.LogInformation("Getting all treatment solutions");

                var solutions = await _treatmentSolutionRepository.GetAllSolutionsAsync();

                if (solutions == null || !solutions.Any())
                {
                    _logger.LogWarning("No treatment solutions found in database");
                    return new List<TreatmentSolutionResponseDto>();
                }

                var result = solutions.Select(MapToDto).ToList();

                _logger.LogInformation("Retrieved {Count} treatment solutions", result.Count);

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all treatment solutions");
                throw;
            }
        }

        public async Task<TreatmentSolutionResponseDto?> GetSolutionByIdAsync(int solutionId)
        {
            try
            {
                _logger.LogInformation("Getting treatment solution {SolutionId}", solutionId);
                var solution = await _treatmentSolutionRepository.GetSolutionByIdAsync(solutionId);

                if (solution == null)
                {
                    _logger.LogWarning("Treatment solution {SolutionId} not found", solutionId);
                    return null;
                }
                return MapToDto(solution);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting treatment solution {SolutionId}", solutionId);
                throw;
            }
        }

        public async Task<List<TreatmentSolutionResponseDto>> GetSolutionByIllnessIdAsync(
            int illnessId,
            decimal? confidenceScore = null)
        {
            try
            {
                _logger.LogInformation("Getting treatment soultions fo illness {IllnessId} with confidence {Confidence}",
                    illnessId, confidenceScore);

                var solutions = await _treatmentSolutionRepository.GetSolutionByIllnessIdAsync(illnessId, confidenceScore);

                if (solutions == null || !solutions.Any())
                {
                    _logger.LogWarning("No treatment solution found for illness {Illness}", illnessId);
                    return new List<TreatmentSolutionResponseDto>();
                }

                var result = solutions.Select(MapToDto).ToList();
                _logger.LogInformation("Found {Count} treatment solutions for illness {IllnessId}", result.Count, illnessId);

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting treatment solutions for illness {IllnessId}", illnessId);
                throw;
            }
        }

        public async Task<List<TreatmentSolutionResponseDto>> GetSolutionsByPredictionIdAsync(int predictionId)
        {
            try
            {
                _logger.LogInformation("Getting treatment solutions for prediction {PredictionId}", predictionId);

                //Get prediction first
                var prediction = await _predictionRepository.GetPredictionByIdAsync(predictionId);

                if (prediction == null)
                {
                    _logger.LogWarning("Prediction {PredictionId} not found", predictionId);
                    throw new KeyNotFoundException($"Prediction with ID {predictionId} not found");
                }

                if (!prediction.IllnessId.HasValue)
                {
                    _logger.LogWarning("Prediction {PredictionId} does not have an illness associated", predictionId);
                    return new List<TreatmentSolutionResponseDto>();
                }

                //Get solutions based on illness and confidence score
                return await GetSolutionByIllnessIdAsync(
                    prediction.IllnessId.Value,
                     prediction.ConfidenceScore);
            }
            catch (KeyNotFoundException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting treatment solutions for prediction {PredictionId}", predictionId);
                throw;
            }
        }

        private TreatmentSolutionResponseDto MapToDto(TreatmentSolution solution)
        {
            var dto = new TreatmentSolutionResponseDto
            {
                SolutionId = solution.SolutionId,
                SolutionName = solution.SolutionName,
                SolutionType = solution.SolutionType,
                Description = solution.Description,
                Priority = solution.Priority,
                MinConfidence = solution.MinConfidence,
                CreatedAt = solution.CreatedAt,

                // Illness Information
                IllnessId = solution.IllnessId,
                IllnessName = solution.Illness?.IllnessName,
                IllnessSeverity = solution.Illness?.Severity,

                // Tree Stage
                TreeStageId = solution.TreeStageId,
                TreeStageName = solution.TreeStage?.StageName,

                // Conditions
                Conditions = solution.SolutionConditions?.Select(sc => new SolutionConditionDto
                {
                    ConditionId = sc.ConditionId,
                    MinConfidence = sc.MinConfidence,
                    WeatherCondition = sc.WeatherCondition,
                    Note = sc.Note
                }).ToList() ?? new List<SolutionConditionDto>()
            };

            return dto;
        }
    }
}
