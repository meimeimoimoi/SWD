using System.Security.Cryptography;
using System.Text;

namespace MyApp.Infrastructure.Helpers
{
    public static class PasswordGenerator
    {
        /// <summary>
        /// Generate a secure random password
        /// </summary>
        /// <param name="length">Password length (default: 12)</param>
        /// <param name="includeUppercase">Include uppercase letters (default: true)</param>
        /// <param name="includeLowercase">Include lowercase letters (default: true)</param>
        /// <param name="includeDigits">Include digits (default: true)</param>
        /// <param name="includeSpecialChars">Include special characters (default: true)</param>
        /// <returns>Generated password</returns>
        public static string Generate(
            int length = 12,
            bool includeUppercase = true,
            bool includeLowercase = true,
            bool includeDigits = true,
            bool includeSpecialChars = true)
        {
            if (length < 8)
                throw new ArgumentException("Password length must be at least 8 characters", nameof(length));

            const string uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            const string lowercase = "abcdefghijklmnopqrstuvwxyz";
            const string digits = "0123456789";
            const string specialChars = "!@#$%^&*()_+-=[]{}|;:,.<>?";

            var characterPool = new StringBuilder();
            var password = new StringBuilder();

            // Build character pool based on options
            if (includeUppercase) characterPool.Append(uppercase);
            if (includeLowercase) characterPool.Append(lowercase);
            if (includeDigits) characterPool.Append(digits);
            if (includeSpecialChars) characterPool.Append(specialChars);

            if (characterPool.Length == 0)
                throw new ArgumentException("At least one character type must be included");

            // Ensure at least one character from each enabled category
            var requiredChars = new List<char>();
            if (includeUppercase) requiredChars.Add(uppercase[RandomNumberGenerator.GetInt32(uppercase.Length)]);
            if (includeLowercase) requiredChars.Add(lowercase[RandomNumberGenerator.GetInt32(lowercase.Length)]);
            if (includeDigits) requiredChars.Add(digits[RandomNumberGenerator.GetInt32(digits.Length)]);
            if (includeSpecialChars) requiredChars.Add(specialChars[RandomNumberGenerator.GetInt32(specialChars.Length)]);

            // Add required characters
            foreach (var c in requiredChars)
            {
                password.Append(c);
            }

            // Fill the rest randomly
            string pool = characterPool.ToString();
            for (int i = password.Length; i < length; i++)
            {
                password.Append(pool[RandomNumberGenerator.GetInt32(pool.Length)]);
            }

            // Shuffle the password
            return Shuffle(password.ToString());
        }

        /// <summary>
        /// Generate a memorable password (easier to type)
        /// Format: Word1-Word2-Number (e.g., Tiger-Cloud-2024)
        /// </summary>
        public static string GenerateMemorablePassword()
        {
            var words = new[]
            {
                "Tiger", "Lion", "Eagle", "Shark", "Bear", "Wolf", "Fox", "Hawk",
                "Storm", "Cloud", "River", "Ocean", "Mountain", "Forest", "Desert", "Valley",
                "Swift", "Brave", "Strong", "Noble", "Wise", "Quick", "Silent", "Mighty",
                "Ruby", "Jade", "Pearl", "Amber", "Crystal", "Diamond", "Emerald", "Sapphire"
            };

            var word1 = words[RandomNumberGenerator.GetInt32(words.Length)];
            var word2 = words[RandomNumberGenerator.GetInt32(words.Length)];
            var number = RandomNumberGenerator.GetInt32(1000, 9999);

            return $"{word1}{word2}{number}!";
        }

        /// <summary>
        /// Generate a PIN code (numeric only)
        /// </summary>
        /// <param name="length">PIN length (default: 6)</param>
        public static string GeneratePin(int length = 6)
        {
            if (length < 4 || length > 12)
                throw new ArgumentException("PIN length must be between 4 and 12", nameof(length));

            var pin = new StringBuilder();
            for (int i = 0; i < length; i++)
            {
                pin.Append(RandomNumberGenerator.GetInt32(0, 10));
            }
            return pin.ToString();
        }

        private static string Shuffle(string input)
        {
            var array = input.ToCharArray();
            int n = array.Length;
            for (int i = n - 1; i > 0; i--)
            {
                int j = RandomNumberGenerator.GetInt32(0, i + 1);
                (array[i], array[j]) = (array[j], array[i]);
            }
            return new string(array);
        }
    }
}
