namespace MyApp.Application.Interfaces
{
    public interface IPasswordHasher
    {
        string Hash(string password);
        bool verify(string password, string passwordHash);
        string GenerateRandomPassword(int length = 12);
    }
}
