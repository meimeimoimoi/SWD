using MyApp.Application.Features.Users.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IRatingService
    {
        /// <summary>
        /// T?o ?ánh giá cho m?t prediction.
        /// Throws KeyNotFoundException n?u prediction không t?n t?i.
        /// Throws UnauthorizedAccessException n?u prediction không thu?c v? user.
        /// Throws InvalidOperationException n?u prediction ?ã ???c ?ánh giá.
        /// </summary>
        Task<RatingResponseDto> CreateRatingAsync(int userId, int predictionId, RatingRequestDto dto);

        /// <summary>
        /// L?y ?ánh giá c?a m?t prediction theo predictionId.
        /// </summary>
        Task<RatingResponseDto?> GetRatingByPredictionIdAsync(int predictionId);
    }
}
