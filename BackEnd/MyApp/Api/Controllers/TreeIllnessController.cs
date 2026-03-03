using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.TreeIllnesses.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/treeillness")]
    [ApiController]
    [Authorize]
    public class TreeIllnessController : ControllerBase
    {
        private readonly ITreeIllnessService _illnessService;
        private readonly ILogger<TreeIllnessController> _logger;

        public TreeIllnessController(
            ITreeIllnessService illnessService,
            ILogger<TreeIllnessController> logger)
        {
            _illnessService = illnessService;
            _logger = logger;
        }

    
        [HttpGet]
        public async Task<IActionResult> GetAllIllnesses([FromQuery] TreeIllnessListRequestDto request)
        {
            try
            {
                // Validate model
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid request parameters",
                        errors = ModelState.Values
                            .SelectMany(v => v.Errors)
                            .Select(e => e.ErrorMessage)
                    });
                }

                var (illnesses, pagination) = await _illnessService.GetAllIllnessesAsync(request);

                return Ok(new
                {
                    success = true,
                    message = $"Retrieved {illnesses.Count} illness(es)",
                    data = illnesses,
                    pagination = new
                    {
                        pagination.CurrentPage,
                        pagination.PageSize,
                        pagination.TotalItems,
                        pagination.TotalPages,
                        pagination.HasPrevious,
                        pagination.HasNext
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting illnesses list");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving illnesses",
                    error = ex.Message
                });
            }
        }

    
        [HttpGet("{illnessId}")]
        public async Task<IActionResult> GetIllnessById(int illnessId)
        {
            try
            {
                var illness = await _illnessService.GetIllnessByIdAsync(illnessId);

                if (illness == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"Illness with ID {illnessId} not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "Illness retrieved successfully",
                    data = illness
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting illness {IllnessId}", illnessId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving illness",
                    error = ex.Message
                });
            }
        }

        [HttpGet("statistics/severity")]
        public async Task<IActionResult> GetSeverityStatistics()
        {
            try
            {
                var stats = await _illnessService.GetSeverityStatisticsAsync();

                return Ok(new
                {
                    success = true,
                    message = "Statistics retrieved successfully",
                    data = stats
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting severity statistics");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving statistics",
                    error = ex.Message
                });
            }
        }

     
        [HttpPost]
        [Authorize(Roles = "Technician")]
        public async Task<IActionResult> CreateIllness([FromBody] CreateTreeIllnessDto dto)
        {
            try
            {
                // Validate model
                if (!ModelState.IsValid)
                {
                    _logger.LogWarning("Invalid model state for illness creation");
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input data",
                        errors = ModelState.Values
                            .SelectMany(v => v.Errors)
                            .Select(e => e.ErrorMessage)
                    });
                }

                var createdIllness = await _illnessService.CreateIllnessAsync(dto);

                _logger.LogInformation("Illness created successfully with ID: {IllnessId}", createdIllness.IllnessId);

                return CreatedAtAction(
                    nameof(GetIllnessById),
                    new { illnessId = createdIllness.IllnessId },
                    new
                    {
                        success = true,
                        message = "Illness created successfully",
                        data = createdIllness
                    });
            }
            catch (InvalidOperationException ex)
            {
                // Duplicate illness name
                _logger.LogWarning(ex, "Duplicate illness name: {IllnessName}", dto.IllnessName);
                return Conflict(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (ArgumentException ex)
            {
                // Validation error
                _logger.LogWarning(ex, "Validation error creating illness");
                return BadRequest(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating illness: {IllnessName}", dto.IllnessName);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while creating the illness",
                    error = ex.Message
                });
            }
        }

        [HttpPut("{illnessId}")]
        [Authorize(Roles = "Technician")]
        public async Task<IActionResult> UpdateIllness(int illnessId, [FromBody] UpdateTreeIllnessDto dto)
        {
            try
            {
                // Validate model
                if (!ModelState.IsValid)
                {
                    _logger.LogWarning("Invalid model state for illness update");
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input data",
                        errors = ModelState.Values
                            .SelectMany(v => v.Errors)
                            .Select(e => e.ErrorMessage)
                    });
                }

                var updatedIllness = await _illnessService.UpdateIllnessAsync(illnessId, dto);

                _logger.LogInformation("Illness {IllnessId} updated successfully", illnessId);

                return Ok(new
                {
                    success = true,
                    message = "Illness updated successfully",
                    data = updatedIllness
                });
            }
            catch (KeyNotFoundException ex)
            {
                // Illness not found
                _logger.LogWarning(ex, "Illness {IllnessId} not found for update", illnessId);
                return NotFound(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (InvalidOperationException ex)
            {
                // Duplicate illness name
                _logger.LogWarning(ex, "Duplicate illness name while updating {IllnessId}", illnessId);
                return Conflict(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (ArgumentException ex)
            {
                // Validation error
                _logger.LogWarning(ex, "Validation error updating illness {IllnessId}", illnessId);
                return BadRequest(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating illness {IllnessId}", illnessId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while updating the illness",
                    error = ex.Message
                });
            }
        }

       
        [HttpPost("{illnessId}/stages")]
        [Authorize(Roles = "Technician")]
        public async Task<IActionResult> AddIllnessStages(
            int illnessId,
            [FromBody] AddIllnessStagesDto dto)
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

                // Get existing illness
                var illness = await _illnessService.GetIllnessByIdAsync(illnessId);
                if (illness == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"Illness with ID {illnessId} not found"
                    });
                }

                // Build stage information
                var stageInfo = string.Join("\n\n", dto.Stages.Select((s, i) => 
                    $"Giai đoạn {i + 1}: {s.StageName}\n" +
                    $"Mô tả: {s.Description}\n" +
                    $"Triệu chứng: {s.Symptoms}"
                ));

                // Update illness with stage information
                var updateDto = new UpdateTreeIllnessDto
                {
                    Description = illness.Description + "\n\n--- GIAI ĐOẠN BỆNH ---\n" + stageInfo
                };

                var updatedIllness = await _illnessService.UpdateIllnessAsync(illnessId, updateDto);

                _logger.LogInformation(
                    "Added {Count} stages to illness {IllnessId}",
                    dto.Stages.Count, illnessId);

                return Ok(new
                {
                    success = true,
                    message = $"Added {dto.Stages.Count} stage(s) to illness successfully",
                    data = new
                    {
                        illnessId = updatedIllness.IllnessId,
                        illnessName = updatedIllness.IllnessName,
                        stagesAdded = dto.Stages.Count,
                        stages = dto.Stages
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding stages to illness {IllnessId}", illnessId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while adding stages",
                    error = ex.Message
                });
            }
        }
    }
}
