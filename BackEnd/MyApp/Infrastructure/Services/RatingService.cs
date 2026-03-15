using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
    public class RatingService : IRatingService
    {
        private readonly RatingRepository _ratingRepository;
        private readonly PredictionRepository _predictionRepository;
        private readonly ILogger<RatingService> _logger;

        public RatingService(
            RatingRepository ratingRepository,
            PredictionRepository predictionRepository,
            ILogger<RatingService> logger)
        {
            _ratingRepository = ratingRepository;
            _predictionRepository = predictionRepository;
            _logger = logger;
        }

        public async Task<RatingResponseDto> CreateRatingAsync(
            int userId,
            int predictionId,
            RatingRequestDto dto)
        {
            try
            {
                _logger.LogInformation(
                    "User {UserId} creating rating for prediction {PredictionId}",
                    userId, predictionId);

                // Ki?m tra prediction t?n t?i
                var prediction = await _predictionRepository.GetPredictionByIdAsync(predictionId);
                if (prediction == null)
                {
                    _logger.LogWarning("Prediction {PredictionId} not found", predictionId);
                    throw new KeyNotFoundException($"Prediction with ID {predictionId} not found");
                }

                // Ki?m tra prediction thu?c v? user
                if (prediction.Upload.UserId != userId)
                {
                    _logger.LogWarning(
                        "User {UserId} attempted to rate prediction {PredictionId} owned by another user",
                        userId, predictionId);
                    throw new UnauthorizedAccessException(
                        "You are not authorized to rate this prediction");
                }

                // Ki?m tra prediction ?ã ???c ?ánh giá ch?a
                var alreadyRated = await _ratingRepository.ExistsByPredictionIdAsync(predictionId);
                if (alreadyRated)
                {
                    _logger.LogWarning("Prediction {PredictionId} has already been rated", predictionId);
                    throw new InvalidOperationException(
                        $"Prediction with ID {predictionId} has already been rated");
                }

                // L?u score d??i d?ng string vào c?t Rating1
                var rating = new Rating
                {
                    PredictionId = predictionId,
                    Rating1 = dto.Score.ToString(),
                    Comment = dto.Comment?.Trim(),
                    CreatedAt = DateTime.Now
                };

                var savedRating = await _ratingRepository.AddRatingAsync(rating);

                // Reload ?? l?y navigation properties
                var loadedRating = await _ratingRepository.GetRatingByPredictionIdAsync(predictionId);

                _logger.LogInformation(
                    "Rating {RatingId} created successfully for prediction {PredictionId} by user {UserId} with score {Score}",
                    savedRating.RatingId, predictionId, userId, dto.Score);

                return MapToDto(loadedRating!);
            }
            catch (KeyNotFoundException) { throw; }
            catch (UnauthorizedAccessException) { throw; }
            catch (InvalidOperationException) { throw; }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Error creating rating for prediction {PredictionId} by user {UserId}",
                    predictionId, userId);
                throw;
            }
        }

        public async Task<RatingResponseDto?> GetRatingByPredictionIdAsync(int predictionId)
        {
            try
            {
                _logger.LogInformation("Getting rating for prediction {PredictionId}", predictionId);

                var rating = await _ratingRepository.GetRatingByPredictionIdAsync(predictionId);

                if (rating == null)
                {
                    _logger.LogWarning("Rating for prediction {PredictionId} not found", predictionId);
                    return null;
                }

                return MapToDto(rating);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting rating for prediction {PredictionId}", predictionId);
                throw;
            }
        }

        private static RatingResponseDto MapToDto(Rating rating)
        {
            // Parse Rating1 (string) ? int score
            int? score = int.TryParse(rating.Rating1, out var parsed) ? parsed : null;

            return new RatingResponseDto
            {
                RatingId = rating.RatingId,
                PredictionId = rating.PredictionId,
                Score = score,
                ScoreLabel = score switch
                {
                    1 => "R?t không chính xác",
                    2 => "Không chính xác",
                    3 => "Trung bình",
                    4 => "Chính xác",
                    5 => "R?t chính xác",
                    _ => null
                },
                Comment = rating.Comment,
                CreatedAt = rating.CreatedAt,
                PredictedClass = rating.Prediction?.PredictedClass,
                ConfidenceScore = rating.Prediction?.ConfidenceScore,
                ConfidencePercentage = rating.Prediction?.ConfidenceScore.HasValue == true
                    ? $"{(rating.Prediction.ConfidenceScore.Value * 100):F2}%"
                    : null,
                IllnessName = rating.Prediction?.Illness?.IllnessName
            };
        }
    }
}
