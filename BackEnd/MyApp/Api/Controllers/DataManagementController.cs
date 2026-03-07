using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/admin/data")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class DataManagementController : ControllerBase
    {
        private readonly IDataManagementService _dataService;
        private readonly ILogger<DataManagementController> _logger;

        public DataManagementController(IDataManagementService dataService, ILogger<DataManagementController> logger)
        {
            _dataService = dataService;
            _logger = logger;
        }

        // ── Tree Stages ──────────────────

        [HttpGet("stages")]
        public async Task<IActionResult> GetAllStages()
        {
            try
            {
                var stages = await _dataService.GetAllStagesAsync();
                return Ok(new { success = true, total = stages.Count, data = stages });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching stages.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("stages/{id}")]
        public async Task<IActionResult> GetStageById(int id)
        {
            try
            {
                var stage = await _dataService.GetStageByIdAsync(id);
                if (stage == null)
                    return NotFound(new { success = false, message = $"Stage with ID {id} not found." });
                return Ok(new { success = true, data = stage });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching stage Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPost("stages")]
        public async Task<IActionResult> CreateStage([FromBody] CreateTreeStageDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var result = await _dataService.CreateStageAsync(dto);
                return CreatedAtAction(nameof(GetStageById), new { id = result.StageId },
                    new { success = true, message = "Stage created successfully.", data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating stage.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPut("stages/{id}")]
        public async Task<IActionResult> UpdateStage(int id, [FromBody] UpdateTreeStageDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var result = await _dataService.UpdateStageAsync(id, dto);
                if (result == null)
                    return NotFound(new { success = false, message = $"Stage with ID {id} not found." });
                return Ok(new { success = true, message = "Stage updated successfully.", data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating stage Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpDelete("stages/{id}")]
        public async Task<IActionResult> DeleteStage(int id)
        {
            try
            {
                var result = await _dataService.DeleteStageAsync(id);
                if (!result)
                    return NotFound(new { success = false, message = $"Stage with ID {id} not found." });
                return Ok(new { success = true, message = "Stage deleted successfully." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting stage Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        // ── Tree-Illness Relationships ──────────────────

        [HttpGet("relationships")]
        public async Task<IActionResult> GetAllRelationships(
            [FromQuery] int? treeId,
            [FromQuery] int? illnessId)
        {
            try
            {
                var result = treeId.HasValue
                    ? await _dataService.GetRelationshipsByTreeAsync(treeId.Value)
                    : illnessId.HasValue
                        ? await _dataService.GetRelationshipsByIllnessAsync(illnessId.Value)
                        : await _dataService.GetAllRelationshipsAsync();

                return Ok(new { success = true, total = result.Count, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching relationships.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPost("relationships")]
        public async Task<IActionResult> CreateRelationship([FromBody] CreateRelationshipDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input." });

                var result = await _dataService.CreateRelationshipAsync(dto);
                return CreatedAtAction(nameof(GetAllRelationships), new { },
                    new { success = true, message = "Relationship created successfully.", data = result });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating relationship.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpDelete("relationships/{id}")]
        public async Task<IActionResult> DeleteRelationship(int id)
        {
            try
            {
                var result = await _dataService.DeleteRelationshipAsync(id);
                if (!result)
                    return NotFound(new { success = false, message = $"Relationship with ID {id} not found." });
                return Ok(new { success = true, message = "Relationship deleted successfully." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting relationship Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
    }
}
