using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
    public class PredictionService : IPredictionService
    {
        private readonly PredictionRepository _predictionRepository;
        private readonly ILogger<PredictionService> _logger;

        public PredictionService(PredictionRepository predictionRepository, ILogger<PredictionService> logger)
        {
            _predictionRepository = predictionRepository;
            _logger = logger;
        }

        public async Task<PredictionResponseDto> CreatePredictionAsync(
            int uploadId, 
            int illnessId,
            decimal confidenceScore, 
            string? topNPredictions = null)
        {
            try
            {
                var prediction = new Prediction
                {
                    UploadId = uploadId,
                    IllnessId = illnessId,
                    ConfidenceScore = confidenceScore,
                    TopNPredictions = topNPredictions,
                    CreatedAt = DateTime.Now
                };

                var savePrediction = await _predictionRepository.AddPredictionAsync(prediction);

                _logger.LogInformation("Prediction created: PredictionId={PredictionId}, UploadId={UploadId}",
                    savePrediction.PredictionId, uploadId);

                return MapToDto(savePrediction);
            }catch(Exception ex)
            {
                _logger.LogError(ex, "Error creating prediction for upload {UploadId}", uploadId);
                throw;
            }
        }

        public async Task<PredictionResponseDto?> GetPredictionByIdAsync(int predictionId)
        {
            try
            {
                var prediction = await _predictionRepository.GetPredictionByIdAsync(predictionId);
                return prediction != null ? MapToDto(prediction) : null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting prediction {PredictionId}", predictionId);
                throw;
            }
        }

        public async Task<PredictionResponseDto?> GetPredictionByUploadIdAsync(int uploadId)
        {
            try
            {
                var prediction = await _predictionRepository.GetPredictionByUploadIdAsync(uploadId);
                return prediction != null ? MapToDto(prediction) : null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting prediction for upload {UploadId}", uploadId);
                throw;
            }
        }

        public async Task<List<PredictionResponseDto>> GetUserPredictionsAsync(int userId)
        {
            try
            {
                var predictions = await _predictionRepository.GetPredictionsByUserIdAsync(userId);
                return predictions.Select(MapToDto).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting predictions for user {UserId}", userId);
                throw;
            }
        }

        private PredictionResponseDto MapToDto(Prediction prediction)
        {
            var dto = new PredictionResponseDto
            {
                PredictionId = prediction.PredictionId,
                UploadId = prediction.UploadId,
                IllnessId = prediction.IllnessId,
                IllnessName = prediction.Illness?.IllnessName,
                IllnessScientificName = prediction.Illness?.ScientificName,
                IllnessSeverity = prediction.Illness?.Severity,
                IllnessDescription = prediction.Illness?.Description,
                Symptoms = prediction.Illness?.Symptoms,
                Causes = prediction.Illness?.Causes,
                TreeId = prediction.TreeId,
                TreeName = prediction.Tree?.TreeName,
                PredictedClass = prediction.PredictedClass,
                ConfidenceScore = prediction.ConfidenceScore,
                ConfidencePercentage = prediction.ConfidenceScore.HasValue
                ? $"{(prediction.ConfidenceScore.Value * 100):F2}%"
                : null,
                TopNPredictions = prediction.TopNPredictions,
                ModelVersionId = prediction.ModelVersionId,
                ModelName = prediction.ModelVersion?.ModelName,
                ModelVersion = prediction.ModelVersion?.Version,
                ProcessingTimeMs = prediction.ProcessingTimeMs,
                CreatedAt = prediction.CreatedAt
            };
            return dto;
        }
    }
}
