using Microsoft.AspNetCore.Identity.Data;
using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;
using MyApp.Persistence.Repositories;
using System.Security.Claims;

namespace MyApp.Infrastructure.Services
{
    public class AuthService : IAuthService
    {
        private readonly UserRepository _userRepository;
        private readonly IPasswordHasher _passwordHasher;
        private readonly JwtTokenGeneratior _jwtTokenGeneratior;
        private readonly AppDbContext _context;
        public AuthService(UserRepository userRepository, IPasswordHasher passwordHasher, JwtTokenGeneratior jwtTokenGeneratior)
        {
            _userRepository = userRepository;
            _passwordHasher = passwordHasher;
            _jwtTokenGeneratior = jwtTokenGeneratior;
        }

        public async Task<string> LoginAsync(LoginRequestDTO request)
        {
            var User = await _userRepository.GetByUserNameAsync(request.Username);

            if (User == null || !_passwordHasher.verify(request.Password, User.PasswordHash))
            {
                throw new UnauthorizedAccessException("Invalid username or password.");
            }

            return _jwtTokenGeneratior.GenerateToken(User);


        }

        public Task LogoutAsync(string token)
        {
            return Task.CompletedTask;
        }

        public async Task RegisterAsync(ResgisterRequestDTO request)
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password)) 
                throw new ArgumentException("Username and password are required");

            bool exists = await _context.Users.AnyAsync(u => u.Username == request.Username);
            if (exists)
                throw new InvalidOperationException("Username already exists.");


            var user = new User
            {
                Username = request.Username,
                PasswordHash = _passwordHasher.Hash(request.Password),
                CreatedAt = DateTime.UtcNow,
                AccountStatus = "Active",
                Role = "User"
            };

            await _userRepository.AddUserAsync(user);
        }
    }
}
