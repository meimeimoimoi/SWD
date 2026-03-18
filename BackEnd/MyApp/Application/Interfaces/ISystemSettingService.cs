using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MyApp.Domain.Entities;

namespace MyApp.Application.Interfaces
{
    public interface ISystemSettingService
    {
        Task<List<SystemSetting>> GetAllSettingsAsync();
        Task<SystemSetting?> GetSettingByKeyAsync(string key);
        Task<bool> UpdateSettingAsync(string key, string value);
    }
}
