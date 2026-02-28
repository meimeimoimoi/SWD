using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace MyApp.Api.Controllers
{
    [Route("api")]
    [ApiController]
    [Authorize]
    public class UserTreatmentController : ControllerBase
    {
        private readonly ITreatmentService _treatmentService;
        private readonly IPredictionHistoryService _historyService;
        private readonly ILogger<UserTreatmentController> _logger;

        public UserTreatmentController(
            ITreatmentService treatmentService,
            IPredictionHistoryService historyService,
            ILogger<UserTreatmentController> logger)
        {
            _treatmentService = treatmentService;
            _historyService = historyService;
            _logger = logger;
        }

        [HttpGet("treatments/recommendations")]
        [AllowAnonymous]
        public async Task<IActionResult> GetRecommendations(
            [FromQuery] int? illnessId,
            [FromQuery] int? illnessStageId,
            [FromQuery] int? treeStageId)
        {
            try
            {
                if (treeStageId.HasValue)
                {
                    var result = await _treatmentService.GetRecommendationsByTreeStageAsync(treeStageId.Value);
                    return Ok(new { success = true, data = result });
                }

                if (illnessId.HasValue && illnessStageId.HasValue)
                {
                    var result = await _treatmentService.GetRecommendationsByIllnessStageAsync(illnessId.Value, illnessStageId.Value);
                    return Ok(new { success = true, data = result });
                }

                if (illnessId.HasValue)
                {
                    var result = await _treatmentService.GetRecommendationsByIllnessAsync(illnessId.Value);
                    return Ok(new { success = true, data = result });
                }

                return BadRequest(new
                {
                    success = false,
                    message = "Please provide at least one of: illnessId, illnessId + illnessStageId, or treeStageId."
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting treatment recommendations");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("treatments/solutions/{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetSolutionDetail(int id)
        {
            try
            {
                var solution = await _treatmentService.GetSolutionDetailAsync(id);
                if (solution == null)
                    return NotFound(new { success = false, message = $"Solution with ID {id} not found." });

                return Ok(new { success = true, data = solution });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting solution detail id={Id}", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("predictions/history")]
        public async Task<IActionResult> GetPredictionHistory()
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                                  ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

                if (!int.TryParse(userIdClaim, out var userId))
                    return Unauthorized(new { success = false, message = "Unable to identify the current user." });

                var history = await _historyService.GetUserHistoryAsync(userId);

                return Ok(new
                {
                    success = true,
                    message = "Prediction history retrieved successfully.",
                    total = history.Count,
                    data = history
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting prediction history");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
    }
}
