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
    private readonly ITreeIllnessService _treeIllnessService;
    private readonly ILogger<TreeIllnessController> _logger;

    public TreeIllnessController(ITreeIllnessService treeIllnessService, ILogger<TreeIllnessController> logger)
    {
        _treeIllnessService = treeIllnessService;
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

            var result = await _treeIllnessService.MapTreeIllnessAsync(mapDto.TreeId, mapDto.IllnessId);
            
            if (!result)
                return BadRequest(new
                {
                    success = false,
                    message = "Failed to create mapping. Tree or Illness may not exist, or mapping already exists."
                });

            return Ok(new
            {
                success = true,
                message = $"Tree {mapDto.TreeId} successfully mapped to Illness {mapDto.IllnessId}"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error mapping tree-illness");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while creating the mapping",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Unmap tree from illness (Admin only)
    /// </summary>
    [HttpDelete("unmap")]
    public async Task<IActionResult> UnmapTreeIllness([FromBody] MapTreeIllnessDto mapDto)
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

            var result = await _treeIllnessService.UnmapTreeIllnessAsync(mapDto.TreeId, mapDto.IllnessId);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Mapping between Tree {mapDto.TreeId} and Illness {mapDto.IllnessId} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Tree {mapDto.TreeId} successfully unmapped from Illness {mapDto.IllnessId}"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error unmapping tree-illness");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while removing the mapping",
                error = ex.Message
            });
        }
    }
}
