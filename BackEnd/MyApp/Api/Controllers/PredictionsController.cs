using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Predictions.DTOs;
using MyApp.Application.Interfaces;
using System.Security.Claims;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PredictionsController : ControllerBase
{
    private readonly IPredictionService _predictionService;
    private readonly ILogger<PredictionsController> _logger;

    public PredictionsController(IPredictionService predictionService, ILogger<PredictionsController> logger)
    {
        _predictionService = predictionService;
        _logger = logger;
    }

    /// <summary>
    /// Run prediction on an uploaded image
    /// </summary>
    /// <param name="request">Prediction request containing uploadId</param>
    /// <returns>Prediction result with tree, illness info and confidence score</returns>
    [HttpPost("run")]
    public async Task<IActionResult> RunPrediction([FromBody] RunPredictionRequestDto request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(new
                {
                    success = false,
                    message = "Invalid input",
                    errors = ModelState.Values.SelectMany(v => v.Errors.Select(e => e.ErrorMessage))
                });

            var result = await _predictionService.RunPredictionAsync(request);

            return Ok(new
            {
                success = true,
                message = "Prediction completed successfully",
                data = result
            });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid operation during prediction");
            return BadRequest(new
            {
                success = false,
                message = ex.Message
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error running prediction");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while running prediction",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Get prediction details by ID
    /// </summary>
    /// <param name="id">Prediction ID</param>
    /// <returns>Detailed prediction information including top N predictions</returns>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetPredictionById(int id)
    {
        try
        {
            var prediction = await _predictionService.GetPredictionByIdAsync(id);

            if (prediction == null)
                return NotFound(new
                {
                    success = false,
                    message = $"Prediction with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = "Prediction retrieved successfully",
                data = prediction
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting prediction {PredictionId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving prediction",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Get prediction history
    /// </summary>
    /// <param name="userId">Optional: Filter by user ID</param>
    /// <param name="fromDate">Optional: Filter from date</param>
    /// <param name="toDate">Optional: Filter to date</param>
    /// <returns>List of predictions history</returns>
    [HttpGet("history")]
    public async Task<IActionResult> GetPredictionHistory(
        [FromQuery] int? userId = null,
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null)
    {
        try
        {
            // If userId not provided, use current user's ID from JWT token
            if (!userId.HasValue)
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (!string.IsNullOrEmpty(userIdClaim) && int.TryParse(userIdClaim, out int currentUserId))
                {
                    userId = currentUserId;
                }
            }

            var history = await _predictionService.GetPredictionHistoryAsync(userId, fromDate, toDate);

            return Ok(new
            {
                success = true,
                message = "Prediction history retrieved successfully",
                count = history.Count,
                data = history
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting prediction history");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving prediction history",
                error = ex.Message
            });
        }
    }
}
