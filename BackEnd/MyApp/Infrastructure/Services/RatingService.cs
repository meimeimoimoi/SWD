using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;
using Microsoft.Extensions.Logging;

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

        public async Task<RatingResponseDto> CreateRatingAsync(int userId, int predictionId, RatingRequestDto dto)
        {
            try
            {
                var prediction = await _predictionRepository.GetPredictionByIdAsync(predictionId);
                if (prediction == null) throw new KeyNotFoundException($"Prediction with ID {predictionId} not found");
                if (prediction.Upload.UserId != userId) throw new UnauthorizedAccessException("You are not authorized to rate this prediction");

                var alreadyRated = await _ratingRepository.ExistsByPredictionIdAsync(predictionId);
                if (alreadyRated) throw new InvalidOperationException($"Prediction with ID {predictionId} has already been rated");

                var rating = new Rating
                {
                    PredictionId = predictionId,
                    Rating1 = dto.Score.ToString(),
                    Comment = dto.Comment?.Trim(),
                    CreatedAt = DateTime.Now
                };

                var savedRating = await _ratingRepository.AddRatingAsync(rating);
                var loadedRating = await _ratingRepository.GetRatingByPredictionIdAsync(predictionId);
                return MapToDto(loadedRating!);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rating for prediction {PredictionId}", predictionId);
                throw;
            }
        }

        public async Task<RatingResponseDto?> GetRatingByPredictionIdAsync(int predictionId)
        {
            var rating = await _ratingRepository.GetRatingByPredictionIdAsync(predictionId);
            return rating == null ? null : MapToDto(rating);
        }

        public async Task<IEnumerable<RatingResponseDto>> GetAllRatingsAsync()
        {
            var ratings = await _ratingRepository.GetAllRatingsAsync();
            return ratings.Select(MapToDto);
        }

        private static RatingResponseDto MapToDto(Rating rating)
        {
            int? score = int.TryParse(rating.Rating1, out var parsed) ? parsed : null;
            var storedFilename = rating.Prediction?.Upload?.StoredFilename;

            return new RatingResponseDto
            {
                RatingId = rating.RatingId,
                PredictionId = rating.PredictionId,
                Score = score,
                ScoreLabel = score switch
                {
                    1 => "Very inaccurate",
                    2 => "Inaccurate",
                    3 => "Average",
                    4 => "Accurate",
                    5 => "Very accurate",
                    _ => null
                },
                Comment = rating.Comment,
                CreatedAt = rating.CreatedAt,
                PredictedClass = rating.Prediction?.PredictedClass,
                ConfidenceScore = rating.Prediction?.ConfidenceScore,
                ConfidencePercentage = rating.Prediction?.ConfidenceScore.HasValue == true
                    ? $"{(rating.Prediction.ConfidenceScore.Value * 100):F2}%"
                    : null,
                IllnessName = rating.Prediction?.Illness?.IllnessName,
                UserEmail = rating.Prediction?.Upload?.User?.Email,
                UserName = rating.Prediction?.Upload?.User?.Username,
                UserId = rating.Prediction?.Upload?.UserId,
                ImageUrl = string.IsNullOrWhiteSpace(storedFilename)
                    ? null
                    : $"/uploads/images/{storedFilename}"
            };
        }
    }
}
