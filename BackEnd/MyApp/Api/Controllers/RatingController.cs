using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace MyApp.Api.Controllers
{
    [Route("api/rating")]
    [ApiController]
    [Authorize]
    public class RatingController : ControllerBase
    {
        private readonly IRatingService _ratingService;
        private readonly ILogger<RatingController> _logger;

        public RatingController(
            IRatingService ratingService,
            ILogger<RatingController> logger)
        {
            _ratingService = ratingService;
            _logger = logger;
        }

      
        [HttpPost("prediction/{predictionId}")]
        public async Task<IActionResult> CreateRating(
            int predictionId,
            [FromBody] RatingRequestDto dto)
        {
            try
            {
                // Validate model
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input data",
                        errors = ModelState.Values
                            .SelectMany(v => v.Errors)
                            .Select(e => e.ErrorMessage)
                    });
                }

                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                    ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    return Unauthorized(new
                    {
                        success = false,
                        message = "Invalid user authentication"
                    });
                }

                var rating = await _ratingService.CreateRatingAsync(userId, predictionId, dto);

                _logger.LogInformation(
                    "User {UserId} rated prediction {PredictionId} with score {Score}",
                    userId, predictionId, dto.Score);

                return CreatedAtAction(
                    nameof(GetRatingByPrediction),
                    new { predictionId },
                    new
                    {
                        success = true,
                        message = "Rating submitted successfully",
                        data = rating
                    });
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Forbid();
            }
            catch (InvalidOperationException ex)
            {
                // Prediction already rated
                _logger.LogWarning(ex, "Prediction {PredictionId} already rated", predictionId);
                return Conflict(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rating for prediction {PredictionId}", predictionId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while submitting the rating",
                    error = ex.Message
                });
            }
        }

        
        [HttpGet("prediction/{predictionId}")]
        public async Task<IActionResult> GetRatingByPrediction(int predictionId)
        {
            try
            {
                var rating = await _ratingService.GetRatingByPredictionIdAsync(predictionId);

                if (rating == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"No rating found for prediction {predictionId}"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "Rating retrieved successfully",
                    data = rating
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting rating for prediction {PredictionId}", predictionId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving the rating",
                    error = ex.Message
                });
            }
        }
    }
}
