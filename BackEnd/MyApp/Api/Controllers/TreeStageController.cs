using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.TreeStages.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class TreeStageController : ControllerBase
    {
        private readonly ITreeStageService _stageService;
        private readonly ILogger<TreeStageController> _logger;

        public TreeStageController(
            ITreeStageService stageService,
            ILogger<TreeStageController> logger)
        {
            _stageService = stageService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllStages()
        {
            try
            {
                var stages = await _stageService.GetAllStagesAsync();

                return Ok(new
                {
                    success = true,
                    message = $"Retrieved {stages.Count} tree stage(s)",
                    data = stages
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting tree stages");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving tree stages",
                    error = ex.Message
                });
            }
        }


        [HttpGet("{stageId}")]
        public async Task<IActionResult> GetStageById(int stageId)
        {
            try
            {
                var stage = await _stageService.GetStageByIdAsync(stageId);

                if (stage == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"Tree stage with ID {stageId} not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "Tree stage retrieved successfully",
                    data = stage
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting tree stage {StageId}", stageId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving the tree stage",
                    error = ex.Message
                });
            }
        }

        [HttpPost]
        [Authorize(Roles = "Technician")]
        public async Task<IActionResult> CreateStage([FromBody] CreateTreeStageDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input data",
                        errors = ModelState.Values
                            .SelectMany(v => v.Errors)
                            .Select(e => e.ErrorMessage)
                    });
                }

                var createdStage = await _stageService.CreateStageAsync(dto);

                return CreatedAtAction(
                    nameof(GetStageById),
                    new { stageId = createdStage.StageId },
                    new
                    {
                        success = true,
                        message = "Tree stage created successfully",
                        data = createdStage
                    });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating tree stage");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while creating the tree stage",
                    error = ex.Message
                });
            }
        }

    
        [HttpPut("{stageId}")]
        [Authorize(Roles = "Technician")]
        public async Task<IActionResult> UpdateStage(
            int stageId,
            [FromBody] UpdateTreeStageDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input data",
                        errors = ModelState.Values
                            .SelectMany(v => v.Errors)
                            .Select(e => e.ErrorMessage)
                    });
                }

                var updatedStage = await _stageService.UpdateStageAsync(stageId, dto);

                return Ok(new
                {
                    success = true,
                    message = "Tree stage updated successfully",
                    data = updatedStage
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
            catch (InvalidOperationException ex)
            {
                return Conflict(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating tree stage {StageId}", stageId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while updating the tree stage",
                    error = ex.Message
                });
            }
        }

      
        [HttpDelete("{stageId}")]
        [Authorize(Roles = "Technician")]
        public async Task<IActionResult> DeleteStage(int stageId)
        {
            try
            {
                await _stageService.DeleteStageAsync(stageId);

                return NoContent();
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting tree stage {StageId}", stageId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while deleting the tree stage",
                    error = ex.Message
                });
            }
        }
    }
}
