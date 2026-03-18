using Microsoft.EntityFrameworkCore;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services
{
    public class SystemSettingService : ISystemSettingService
    {
        private readonly AppDbContext _context;
        private readonly ILogger<SystemSettingService> _logger;

        public SystemSettingService(AppDbContext context, ILogger<SystemSettingService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<SystemSetting>> GetAllSettingsAsync()
        {
            return await _context.SystemSettings.OrderBy(s => s.Group).ThenBy(s => s.Key).ToListAsync();
        }

        public async Task<SystemSetting?> GetSettingByKeyAsync(string key)
        {
            return await _context.SystemSettings.FirstOrDefaultAsync(s => s.Key == key);
        }

        public async Task<bool> UpdateSettingAsync(string key, string value)
        {
            try
            {
                var setting = await _context.SystemSettings.FirstOrDefaultAsync(s => s.Key == key);
                if (setting == null)
                {
                    _logger.LogWarning("System setting with key '{Key}' not found.", key);
                    return false;
                }

                setting.Value = value;
                setting.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                _logger.LogInformation("System setting '{Key}' updated to '{Value}'.", key, value);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating system setting '{Key}'.", key);
                throw;
            }
        }
    }
}
