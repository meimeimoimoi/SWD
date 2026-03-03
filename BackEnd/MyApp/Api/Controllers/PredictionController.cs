using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace MyApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class PredictionController : ControllerBase
    {
        private readonly IPredictionService _predictionService;
        private readonly ILogger<PredictionController> _logger;

        public PredictionController(
            IPredictionService predictionService,
            ILogger<PredictionController> logger)
        {
            _predictionService = predictionService;
            _logger = logger;
        }

        [HttpGet("{predictionId}")]
        public async Task<IActionResult> GetPrediction(int predictionId)
        {
            try
            {
                var prediction = await _predictionService.GetPredictionByIdAsync(predictionId);

                if (prediction == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"Prediction with ID {predictionId} not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "Prediction retrieved successfully",
                    data = prediction
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving prediction {PredictionId}", predictionId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred",
                    error = ex.Message
                });
            }
        }

        [HttpGet("my-predictions")]
        public async Task<IActionResult> GetMyPredictions([FromQuery] PredictionFilterRequestDto filter)
        {
            try
            {
                // Validate model
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid request parameters",
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

                var (predictions, pagination) = await _predictionService
                    .GetFilteredUserPredictionsAsync(userId, filter);

                return Ok(new
                {
                    success = true,
                    message = $"Retrieved {predictions.Count} prediction(s)",
                    data = predictions,
                    pagination = new
                    {
                        pagination.CurrentPage,
                        pagination.PageSize,
                        pagination.TotalItems,
                        pagination.TotalPages,
                        pagination.HasPrevious,
                        pagination.HasNext
                    },
                    filters = new
                    {
                        filter.IllnessName,
                        filter.IllnessId,
                        filter.Severity,
                        filter.MinConfidence,
                        filter.MaxConfidence,
                        filter.DateFrom,
                        filter.DateTo,
                        filter.SortBy,
                        filter.SortOrder
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user predictions");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred",
                    error = ex.Message
                });
            }
        }
    }
}
