using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class TreatmentSolutionController : ControllerBase
    {
        private readonly ITreatmentSolutionService _treatmentSolutionService;
        private readonly ILogger<TreatmentSolutionController> _logger;

        public TreatmentSolutionController(ITreatmentSolutionService treatmentSolutionService, ILogger<TreatmentSolutionController> logger)
        {
            _treatmentSolutionService = treatmentSolutionService;
            _logger = logger;
        }

        [HttpGet("by-prediction/{predictionId}")]
        public async Task<IActionResult> GetTreatmentsByPrediction(int predictionId)
        {
            try
            {
                var solutions = await _treatmentSolutionService.GetSolutionsByPredictionIdAsync(predictionId);

                if (solutions == null || !solutions.Any())
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"No treatment solutions found for prediction {predictionId}"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = $"Found {solutions.Count} treatment solution(s)",
                    data = solutions
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
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting treatment solutions for prediction {PredictionId}", predictionId);
                return StatusCode(StatusCodes.Status500InternalServerError, new
                {
                    success = false,
                    message = "An error occurred while retrieving treatment solutions"
                });
            }
        }

        [HttpGet("by-illness/{illnessId}")]
        public async Task<IActionResult> GetTreatmentsByIllness(
            int illnessId,
            [FromQuery] decimal? confidenceScore = null)
        {
            try
            {
                //Validate confidence score range
                if (confidenceScore.HasValue && (confidenceScore < 0 || confidenceScore > 1))
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Confidence score must be between 0 and 1"
                    });
                }

                var solutions = await _treatmentSolutionService.GetSolutionByIllnessIdAsync(illnessId, confidenceScore);

                if (solutions == null || !solutions.Any())
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"No treatment solutions found for illness {illnessId} with confidence {confidenceScore}"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = $"Found {solutions.Count} treatment solution(s)",
                    data = solutions,
                    filters = new
                    {
                        illnessId,
                        confidenceScore
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting treatments for illness {IllnessId}", illnessId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving treatment solutions",
                    error = ex.Message
                });
            }
        }

        [HttpGet("{solutionId}")]
        public async Task<IActionResult> GetTreatmentSolution(int solutionId)
        {
            try
            {
                var solution = await _treatmentSolutionService.GetSolutionByIdAsync(solutionId);

                if (solution == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"Treatment solution {solutionId} not found"
                    });
                }
                return Ok(new
                {
                    success = true,
                    message = $"Treatment solution {solutionId} retrieved successfully",
                    data = solution
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting treatment solution {SolutionId}", solutionId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving the treatment solution",
                    error = ex.Message
                });
            }
        }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetAllTreatments()
        {
            try
            {
                var solutions = await _treatmentSolutionService.GetAllSolutionsAsync();

                return Ok(new
                {
                    success = true,
                    message = $"Retrieved {solutions.Count} treatment solution(s)",
                    data = solutions
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all treatment solutions");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving treatment solutions",
                    error = ex.Message
                });
            }
        }
    }
}
