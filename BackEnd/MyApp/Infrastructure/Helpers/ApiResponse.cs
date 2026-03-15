namespace MyApp.Infrastructure.Helpers
{
    public class ApiResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public object? Data { get; set; }

        public ApiResponse() { }
        public ApiResponse(bool success, string message, object? data = null)
        {
            Success = success;
            Message = message;
            Data = data;
        }

        public static ApiResponse SuccessResponse(string message, object? data = null)
        {
            return new ApiResponse(true, message, data);
        }

        public static ApiResponse ErrorResponse(string message, object? data = null)
        {
            return new ApiResponse(false, message, data);
        }

    }
}
