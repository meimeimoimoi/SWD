using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Prediction;
using MyApp.Application.Features.Treatment.DTOs;
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
        private readonly IAiSolutionSuggestionService _aiSolutionSuggestionService;
        private readonly IPredictionHistoryService _historyService;
        private readonly IUserTreeService _userTreeService;
        private readonly ILogger<UserTreatmentController> _logger;

        public UserTreatmentController(
            ITreatmentService treatmentService,
            IAiSolutionSuggestionService aiSolutionSuggestionService,
            IPredictionHistoryService historyService,
            IUserTreeService userTreeService,
            ILogger<UserTreatmentController> logger)
        {
            _treatmentService = treatmentService;
            _aiSolutionSuggestionService = aiSolutionSuggestionService;
            _historyService = historyService;
            _userTreeService = userTreeService;
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

        /// <summary>
        /// Uses catalog context plus optional OpenAI (see appsettings <c>AiSolution</c>) to propose actions; falls back to heuristic text if no API key.
        /// </summary>
        [HttpPost("treatments/ai-suggest")]
        public async Task<IActionResult> AiSuggestTreatmentPlan(
            [FromBody] AiSolutionSuggestRequest request,
            CancellationToken cancellationToken)
        {
            try
            {
                if (request == null)
                    return BadRequest(new { success = false, message = "Request body is required." });

                if (!request.IllnessId.HasValue && string.IsNullOrWhiteSpace(request.DiseaseName))
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Provide illnessId and/or diseaseName.",
                    });
                }

                var result = await _aiSolutionSuggestionService.SuggestAsync(request, cancellationToken);
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "AI / heuristic solution suggestion failed");
                return StatusCode(500, new { success = false, message = "Could not build a suggestion." });
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

        [HttpGet("predictions/history/{id:int}")]
        public async Task<IActionResult> GetPredictionDetail(int id)
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                                  ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

                if (!int.TryParse(userIdClaim, out var userId))
                    return Unauthorized(new { success = false, message = "Unable to identify the current user." });

                var predictionDetail = await _historyService.GetPredictionByIdAsync(id, userId);

                if (predictionDetail == null)
                    return NotFound(new { success = false, message = $"Prediction record with ID {id} not found." });

                return Ok(new { success = true, data = predictionDetail });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting prediction detail id={Id}", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        /// <summary>
        /// Link a completed scan to a tree (updates prediction.TreeId; may add illness–tree relationship).
        /// </summary>
        [HttpPatch("predictions/history/{id:int}/tree")]
        public async Task<IActionResult> AssignPredictionToTree(int id, [FromBody] AssignPredictionToTreeDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage)
                    });
                }

                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                                  ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

                if (!int.TryParse(userIdClaim, out var userId))
                    return Unauthorized(new { success = false, message = "Unable to identify the current user." });

                var (success, message) = await _userTreeService.AssignPredictionToTreeAsync(
                    userId, id, dto.TreeId);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error assigning prediction {Id} to tree.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
    }
}
