using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Solutions.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SolutionsController : ControllerBase
{
    private readonly ISolutionService _solutionService;
    private readonly ILogger<SolutionsController> _logger;

    public SolutionsController(ISolutionService solutionService, ILogger<SolutionsController> logger)
    {
        _solutionService = solutionService;
        _logger = logger;
    }

    /// <summary>
    /// Get all solutions
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAllSolutions()
    {
        try
        {
            var solutions = await _solutionService.GetAllSolutionsAsync();
            
            return Ok(new
            {
                success = true,
                message = "Solutions retrieved successfully",
                count = solutions.Count,
                data = solutions
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all solutions");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving solutions",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Get solution by ID
    /// </summary>
    [HttpGet("{id}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetSolutionById(int id)
    {
        try
        {
            var solution = await _solutionService.GetSolutionByIdAsync(id);
            
            if (solution == null)
                return NotFound(new
                {
                    success = false,
                    message = $"Solution with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = "Solution retrieved successfully",
                data = solution
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting solution {SolutionId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving the solution",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Get solutions by prediction ID
    /// </summary>
    [HttpGet("by-prediction/{predictionId}")]
    [Authorize]
    public async Task<IActionResult> GetSolutionsByPrediction(int predictionId)
    {
        try
        {
            var solutions = await _solutionService.GetSolutionsByPredictionIdAsync(predictionId);
            
            return Ok(new
            {
                success = true,
                message = "Solutions retrieved successfully",
                predictionId = predictionId,
                count = solutions.Count,
                data = solutions
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting solutions for prediction {PredictionId}", predictionId);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving solutions",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Get solutions by illness ID
    /// </summary>
    [HttpGet("by-illness/{illnessId}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetSolutionsByIllness(int illnessId)
    {
        try
        {
            var solutions = await _solutionService.GetSolutionsByIllnessIdAsync(illnessId);
            
            return Ok(new
            {
                success = true,
                message = "Solutions retrieved successfully",
                illnessId = illnessId,
                count = solutions.Count,
                data = solutions
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting solutions for illness {IllnessId}", illnessId);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving solutions",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Create new solution (Admin only)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateSolution([FromBody] CreateSolutionDto createDto)
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

            var solution = await _solutionService.CreateSolutionAsync(createDto);
            
            return CreatedAtAction(
                nameof(GetSolutionById),
                new { id = solution.SolutionId },
                new
                {
                    success = true,
                    message = "Solution created successfully",
                    data = solution
                });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating solution");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while creating the solution",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Update solution (Admin only)
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateSolution(int id, [FromBody] UpdateSolutionDto updateDto)
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

            var result = await _solutionService.UpdateSolutionAsync(id, updateDto);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Solution with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Solution {id} updated successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating solution {SolutionId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while updating the solution",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Delete solution (Admin only)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteSolution(int id)
    {
        try
        {
            var result = await _solutionService.DeleteSolutionAsync(id);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Solution with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Solution {id} deleted successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting solution {SolutionId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while deleting the solution",
                error = ex.Message
            });
        }
    }
}
