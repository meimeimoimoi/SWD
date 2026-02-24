using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
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
        public async Task<IActionResult> GetMyPredictions()
        {
            try
            {
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

                var predictions = await _predictionService.GetUserPredictionsAsync(userId);

                return Ok(new
                {
                    success = true,
                    message = $"Retrieved {predictions.Count} predictions",
                    data = predictions
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
