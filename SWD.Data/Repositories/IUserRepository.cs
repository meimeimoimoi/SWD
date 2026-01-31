using SWD.Data.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Data.Repositories
{
    public interface IUserRepository
    {
        Task<User?> FindByEmailAsync(string email);
        Task<User?> FindByIdAsync(Guid userId);
        Task<IEnumerable<User>> GetAllAsync();
        Task<(IEnumerable<User> Users, int TotalCount)> GetAllPaginatedAsync(int page, int pageSize, string? search = null, string? role = null, string? sortBy = "email", string? sortOrder = "asc");
        Task<bool> UserExistsByEmailAsync(string email);
        Task CreateUserWithRoleAsync(User user, string roleName);
        Task UpdateUserAsync(User user);
    }
}
