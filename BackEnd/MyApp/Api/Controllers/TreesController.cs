using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Trees.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TreesController : ControllerBase
{
    private readonly ITreeService _treeService;
    private readonly ILogger<TreesController> _logger;

    public TreesController(ITreeService treeService, ILogger<TreesController> logger)
    {
        _treeService = treeService;
        _logger = logger;
    }

    /// <summary>
    /// Get all trees
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAllTrees()
    {
        try
        {
            var trees = await _treeService.GetAllTreesAsync();
            
            return Ok(new
            {
                success = true,
                message = "Trees retrieved successfully",
                count = trees.Count,
                data = trees
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all trees");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving trees",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Get tree by ID
    /// </summary>
    [HttpGet("{id}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetTreeById(int id)
    {
        try
        {
            var tree = await _treeService.GetTreeByIdAsync(id);
            
            if (tree == null)
                return NotFound(new
                {
                    success = false,
                    message = $"Tree with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = "Tree retrieved successfully",
                data = tree
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting tree {TreeId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while retrieving tree",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Create new tree (Admin only)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateTree([FromBody] CreateTreeDto createDto)
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

            var tree = await _treeService.CreateTreeAsync(createDto);
            
            return CreatedAtAction(
                nameof(GetTreeById),
                new { id = tree.TreeId },
                new
                {
                    success = true,
                    message = "Tree created successfully",
                    data = tree
                });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating tree");
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while creating tree",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Update tree (Admin only)
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateTree(int id, [FromBody] UpdateTreeDto updateDto)
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

            var result = await _treeService.UpdateTreeAsync(id, updateDto);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Tree with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Tree {id} updated successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating tree {TreeId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while updating tree",
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// Delete tree (Admin only)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteTree(int id)
    {
        try
        {
            var result = await _treeService.DeleteTreeAsync(id);
            
            if (!result)
                return NotFound(new
                {
                    success = false,
                    message = $"Tree with ID {id} not found"
                });

            return Ok(new
            {
                success = true,
                message = $"Tree {id} deleted successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting tree {TreeId}", id);
            return StatusCode(500, new
            {
                success = false,
                message = "An error occurred while deleting tree",
                error = ex.Message
            });
        }
    }
}
