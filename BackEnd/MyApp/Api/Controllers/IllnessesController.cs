using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Illnesses.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class IllnessesController : ControllerBase
{
    private readonly IIllnessService _illnessService;
    private readonly ILogger<IllnessesController> _logger;

    public IllnessesController(IIllnessService illnessService, ILogger<IllnessesController> logger)
    {
        _illnessService = illnessService;
        _logger = logger;
    }

    /// <summary>
    /// Get all illnesses
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAllIllnesses()
    {
        try
        {
            var illnesses = await _illnessService.GetAllIllnessesAsync();
            
            return Ok(new
            {
                success = true,
                message = "Illnesses retrieved successfully",
                count = illnesses.Count,
                data = illnesses
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all illnesses");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving illnesses",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Get illness by ID
    /// </summary>
    [HttpGet("{id}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetIllnessById(int id)
    {
        try
        {
            var illness = await _illnessService.GetIllnessByIdAsync(id);
            
            if (illness == null)
                return NotFound(new
                {
                    success = false,
                    message = $"Illness with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = "Illness retrieved successfully",
                data = illness
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting illness {IllnessId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving illness",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Create new illness (Admin only)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateIllness([FromBody] CreateIllnessDto createDto)
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

            var illness = await _illnessService.CreateIllnessAsync(createDto);
            
            return CreatedAtAction(
                nameof(GetIllnessById),
                new { id = illness.IllnessId },
                new
                {
                    success = true,
                    message = "Illness created successfully",
                    data = illness
                });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating illness");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while creating illness",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Update illness (Admin only)
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateIllness(int id, [FromBody] UpdateIllnessDto updateDto)
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

            var result = await _illnessService.UpdateIllnessAsync(id, updateDto);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Illness with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Illness {id} updated successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating illness {IllnessId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while updating illness",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Delete illness (Admin only)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteIllness(int id)
    {
        try
        {
            var result = await _illnessService.DeleteIllnessAsync(id);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Illness with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Illness {id} deleted successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting illness {IllnessId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while deleting illness",
                error = ex.Message
            });
        }
    }
}
