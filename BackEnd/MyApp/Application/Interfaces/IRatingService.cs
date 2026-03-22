using MyApp.Application.Features.Users.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IRatingService
    {
        Task<RatingResponseDto> CreateRatingAsync(int userId, int predictionId, RatingRequestDto dto);

        Task<RatingResponseDto?> GetRatingByPredictionIdAsync(int predictionId);

        Task<IEnumerable<RatingResponseDto>> GetAllRatingsAsync();
    }
}
