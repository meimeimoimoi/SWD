using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services
{
    public class DataManagementService : IDataManagementService
    {
        private readonly AppDbContext _context;
        private readonly ILogger<DataManagementService> _logger;

        public DataManagementService(AppDbContext context, ILogger<DataManagementService> logger)
        {
            _context = context;
            _logger = logger;
        }


        public async Task<List<TreeStageDto>> GetAllStagesAsync()
        {
            _logger.LogInformation("Fetching all tree stages.");
            var stages = await _context.TreeStages.OrderBy(s => s.StageId).ToListAsync();
            return stages.Select(MapStageToDto).ToList();
        }

        public async Task<TreeStageDto?> GetStageByIdAsync(int id)
        {
            var stage = await _context.TreeStages.FindAsync(id);
            return stage == null ? null : MapStageToDto(stage);
        }

        public async Task<TreeStageDto> CreateStageAsync(CreateTreeStageDto dto)
        {
            var stage = new TreeStage
            {
                StageName   = dto.StageName,
                Description = dto.Description,
                CreatedAt   = DateTime.UtcNow
            };
            _context.TreeStages.Add(stage);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Tree stage created - Id={Id}, Name='{Name}'", stage.StageId, stage.StageName);
            return MapStageToDto(stage);
        }

        public async Task<TreeStageDto?> UpdateStageAsync(int id, UpdateTreeStageDto dto)
        {
            var stage = await _context.TreeStages.FindAsync(id);
            if (stage == null) return null;

            if (dto.StageName   != null) stage.StageName   = dto.StageName;
            if (dto.Description != null) stage.Description = dto.Description;

            await _context.SaveChangesAsync();
            _logger.LogInformation("Tree stage updated - Id={Id}", id);
            return MapStageToDto(stage);
        }

        public async Task<bool> DeleteStageAsync(int id)
        {
            var stage = await _context.TreeStages.FindAsync(id);
            if (stage == null) return false;

            _context.TreeStages.Remove(stage);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Tree stage deleted - Id={Id}", id);
            return true;
        }


        public async Task<List<TreeIllnessRelationshipDto>> GetAllRelationshipsAsync()
        {
            _logger.LogInformation("Fetching all tree-illness relationships.");
            var list = await _context.TreeIllnessRelationships
                .Include(r => r.Tree)
                .Include(r => r.Illness)
                .ToListAsync();
            return list.Select(MapRelationToDto).ToList();
        }

        public async Task<List<TreeIllnessRelationshipDto>> GetRelationshipsByTreeAsync(int treeId)
        {
            var list = await _context.TreeIllnessRelationships
                .Include(r => r.Tree)
                .Include(r => r.Illness)
                .Where(r => r.TreeId == treeId)
                .ToListAsync();
            return list.Select(MapRelationToDto).ToList();
        }

        public async Task<List<TreeIllnessRelationshipDto>> GetRelationshipsByIllnessAsync(int illnessId)
        {
            var list = await _context.TreeIllnessRelationships
                .Include(r => r.Tree)
                .Include(r => r.Illness)
                .Where(r => r.IllnessId == illnessId)
                .ToListAsync();
            return list.Select(MapRelationToDto).ToList();
        }

        public async Task<TreeIllnessRelationshipDto> CreateRelationshipAsync(CreateRelationshipDto dto)
        {
            var exists = await _context.TreeIllnessRelationships
                .AnyAsync(r => r.TreeId == dto.TreeId && r.IllnessId == dto.IllnessId);
            if (exists)
                throw new InvalidOperationException(
                    $"Relationship between TreeId={dto.TreeId} and IllnessId={dto.IllnessId} already exists.");

            var rel = new TreeIllnessRelationship
            {
                TreeId    = dto.TreeId,
                IllnessId = dto.IllnessId
            };
            _context.TreeIllnessRelationships.Add(rel);
            await _context.SaveChangesAsync();

            await _context.Entry(rel).Reference(r => r.Tree).LoadAsync();
            await _context.Entry(rel).Reference(r => r.Illness).LoadAsync();

            _logger.LogInformation(
                "Relationship created - TreeId={TreeId}, IllnessId={IllnessId}", dto.TreeId, dto.IllnessId);
            return MapRelationToDto(rel);
        }

        public async Task<bool> DeleteRelationshipAsync(int relationshipId)
        {
            var rel = await _context.TreeIllnessRelationships.FindAsync(relationshipId);
            if (rel == null) return false;

            _context.TreeIllnessRelationships.Remove(rel);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Relationship deleted - Id={Id}", relationshipId);
            return true;
        }


        private static TreeStageDto MapStageToDto(TreeStage s) => new()
        {
            StageId     = s.StageId,
            StageName   = s.StageName,
            Description = s.Description,
            CreatedAt   = s.CreatedAt
        };

        private static TreeIllnessRelationshipDto MapRelationToDto(TreeIllnessRelationship r) => new()
        {
            RelationshipId = r.RelationshipId,
            TreeId         = r.TreeId,
            TreeName       = r.Tree?.TreeName,
            IllnessId      = r.IllnessId,
            IllnessName    = r.Illness?.IllnessName
        };
    }
}
