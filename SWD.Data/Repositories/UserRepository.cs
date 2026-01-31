using Microsoft.EntityFrameworkCore;
using SWD.Data.Data;
using SWD.Data.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Data.Repositories
{
    public class UserRepository: IUserRepository
    {
        private readonly Swd392Context _context;
        public UserRepository(Swd392Context context)
        {
            _context = context;
        }

        public async Task<User?> FindByEmailAsync(string email)
        {
            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Email == email);
        }

        public async Task<User?> FindByIdAsync(Guid userId)
        {
            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Id == userId);
        }

        public async Task<IEnumerable<User>> GetAllAsync()
        {
            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .ToListAsync();
        }

        public async Task<(IEnumerable<User> Users, int TotalCount)> GetAllPaginatedAsync(
            int page,
            int pageSize,
            string? search = null,
            string? role = null,
            string? sortBy = "email",
            string? sortOrder = "asc")
        {
            var query = _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .AsQueryable();

            // Apply search filter
            if (!string.IsNullOrWhiteSpace(search))
            {
                var searchLower = search.ToLower();
                query = query.Where(u =>
                    u.Email.ToLower().Contains(searchLower) ||
                    (u.FirstName != null && u.FirstName.ToLower().Contains(searchLower)) ||
                    (u.LastName != null && u.LastName.ToLower().Contains(searchLower)) ||
                    ((u.FirstName ?? "") + " " + (u.LastName ?? "")).ToLower().Contains(searchLower));
            }

            // Apply role filter
            if (!string.IsNullOrWhiteSpace(role) && role != "all")
            {
                query = query.Where(u => u.UserRoles.Any(ur => ur.Role.Name == role));
            }

            // Get total count before pagination
            var totalCount = await query.CountAsync();

            // Apply sorting
            query = sortBy?.ToLower() switch
            {
                "name" => sortOrder?.ToLower() == "desc"
                    ? query.OrderByDescending(u => u.FirstName ?? "").ThenByDescending(u => u.LastName ?? "")
                    : query.OrderBy(u => u.FirstName ?? "").ThenBy(u => u.LastName ?? ""),
                "createdat" => sortOrder?.ToLower() == "desc"
                    ? query.OrderByDescending(u => u.CreatedAt)
                    : query.OrderBy(u => u.CreatedAt),
                "email" or _ => sortOrder?.ToLower() == "desc"
                    ? query.OrderByDescending(u => u.Email)
                    : query.OrderBy(u => u.Email)
            };

            // Apply pagination
            var users = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (users, totalCount);
        }

        public async Task<bool> UserExistsByEmailAsync(string email)
        {
            return await _context.Users.AnyAsync(u => u.Email == email);
        }

        public async Task CreateUserWithRoleAsync(User user, string roleName)
        {
            var role = await _context.Roles.SingleOrDefaultAsync(r => r.Name == roleName);
            if (role == null)
            {
                throw new InvalidOperationException($"Role '{roleName}' not found.");
            }

            await _context.Users.AddAsync(user);
            await _context.UserRoles.AddAsync(new UserRole { UserId = user.Id, RoleId = role.Id });
            await _context.SaveChangesAsync();
        }

        public async Task UpdateUserAsync(User user)
        {
            _context.Users.Update(user);
            await _context.SaveChangesAsync();
        }
    }
}
