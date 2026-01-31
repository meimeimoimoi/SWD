using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.DTOs
{
    public class ApiResponse<T>
    {
        public bool Succeeded { get; set; }
        public string? Message { get; set; }
        public T? Data { get; set; }

        private ApiResponse() { }
        public static ApiResponse<T> Success(T data, string? messsage = null)
        {
            return new ApiResponse<T>
            {
                Succeeded = true,
                Data = data,
                Message = messsage
            };
        }

        public static ApiResponse<T> Error(string message)
        {
            return new ApiResponse<T>
            {
                Succeeded = false,
                Message = message,
                Data = default
            };
        }
    }
}
