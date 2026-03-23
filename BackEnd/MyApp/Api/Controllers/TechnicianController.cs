using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Features.Technician.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Enums;

namespace MyApp.Api.Controllers
{
    [Route("api/technician")]
    [ApiController]
    [Authorize(Roles = RolePolicy.TechnicianOrAdmin)]
    public class TechnicianController : ControllerBase
    {
        private readonly ITechnicianService _technicianService;
        private readonly ILogger<TechnicianController> _logger;

        public TechnicianController(ITechnicianService technicianService, ILogger<TechnicianController> logger)
        {
            _technicianService = technicianService;
            _logger            = logger;
        }


        [HttpGet("illnesses")]
        public async Task<IActionResult> GetAllIllnesses()
        {
            try
            {
                var result = await _technicianService.GetAllIllnessesAsync();
                return Ok(new { success = true, total = result.Count, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching illnesses.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("illnesses/{id}")]
        public async Task<IActionResult> GetIllnessById(int id)
        {
            try
            {
                var result = await _technicianService.GetIllnessByIdAsync(id);
                if (result == null)
                    return NotFound(new { success = false, message = $"Illness with ID {id} not found." });
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching illness Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPost("illnesses")]
        public async Task<IActionResult> CreateIllness([FromBody] CreateIllnessDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var result = await _technicianService.CreateIllnessAsync(dto);
                return CreatedAtAction(nameof(GetIllnessById), new { id = result.IllnessId },
                    new { success = true, message = "Illness created successfully.", data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating illness.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPut("illnesses/{id}")]
        public async Task<IActionResult> UpdateIllness(int id, [FromBody] UpdateIllnessDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var result = await _technicianService.UpdateIllnessAsync(id, dto);
                if (result == null)
                    return NotFound(new { success = false, message = $"Illness with ID {id} not found." });
                return Ok(new { success = true, message = "Illness updated successfully.", data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating illness Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpDelete("illnesses/{id}")]
        public async Task<IActionResult> DeleteIllness(int id)
        {
            try
            {
                var result = await _technicianService.DeleteIllnessAsync(id);
                if (!result)
                    return NotFound(new { success = false, message = $"Illness with ID {id} not found." });
                return Ok(new { success = true, message = "Illness deleted successfully." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting illness Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPost("illnesses/{id}/assign-tree")]
        public async Task<IActionResult> AssignIllnessToTree(int id, [FromBody] AssignIllnessToTreeDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var (success, message) = await _technicianService.AssignIllnessToTreeAsync(id, dto.TreeId);
                if (!success)
                    return Conflict(new { success = false, message });
                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error assigning illness {Id} to tree.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }


        [HttpGet("stages")]
        public async Task<IActionResult> GetAllStages()
        {
            try
            {
                var result = await _technicianService.GetAllStagesAsync();
                return Ok(new { success = true, total = result.Count, data = result });
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
                var result = await _technicianService.GetStageByIdAsync(id);
                if (result == null)
                    return NotFound(new { success = false, message = $"Stage with ID {id} not found." });
                return Ok(new { success = true, data = result });
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

                var result = await _technicianService.CreateStageAsync(dto);
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

                var result = await _technicianService.UpdateStageAsync(id, dto);
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
    }
}
