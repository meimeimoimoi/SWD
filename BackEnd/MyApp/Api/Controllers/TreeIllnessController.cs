using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Trees.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/tree-illness")]
[Authorize(Roles = "Admin")]
public class TreeIllnessController : ControllerBase
{
    private readonly ITreeIllnessService _service;
    private readonly ILogger<TreeIllnessController> _logger;

    public TreeIllnessController(ITreeIllnessService service, ILogger<TreeIllnessController> logger)
    {
        _service = service;
        _logger = logger;
    }

    /// <summary>
    /// Map tree to illness (Admin only)
    /// </summary>
    [HttpPost("map")]
    public async Task<IActionResult> MapTreeIllness([FromBody] MapTreeIllnessDto mapDto)
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

            var result = await _service.MapTreeIllnessAsync(mapDto.TreeId, mapDto.IllnessId);
            
            if (!result)
                return BadRequest(new
                {
                    success = false,
                    message = $"Failed to map tree {mapDto.TreeId} to illness {mapDto.IllnessId}. Either tree or illness does not exist, or mapping already exists."
                });

            return Ok(new
            {
                success = true,
                message = $"Tree {mapDto.TreeId} mapped to illness {mapDto.IllnessId} successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error mapping tree-illness");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while mapping tree to illness",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Unmap tree from illness (Admin only)
    /// </summary>
    [HttpDelete("unmap")]
    public async Task<IActionResult> UnmapTreeIllness([FromQuery] int treeId, [FromQuery] int illnessId)
    {
        try
        {
            if (treeId <= 0 || illnessId <= 0)
                return BadRequest(new
                {
                    success = false,
                    message = "TreeId and IllnessId must be positive integers"
                });

            var result = await _service.UnmapTreeIllnessAsync(treeId, illnessId);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Mapping between tree {treeId} and illness {illnessId} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Tree {treeId} unmapped from illness {illnessId} successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error unmapping tree-illness");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while unmapping tree from illness",
                error = ex.Message
            });
        }
    }
}
