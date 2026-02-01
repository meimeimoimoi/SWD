using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.Versioning;

namespace SWD.Business.ML;

/// <summary>
/// Helper class for image preprocessing before feeding to ResNet18
/// </summary>
public static class ImagePreprocessor
{
    private const int TargetWidth = 224;
    private const int TargetHeight = 224;

    /// <summary>
    /// Resize and normalize image to 224x224 for ResNet18
    /// </summary>
    public static byte[] PreprocessImage(byte[] imageBytes)
    {
        using var ms = new MemoryStream(imageBytes);
        using var image = Image.FromStream(ms);
        
        // Resize to 224x224 (ResNet18 input size)
        using var resizedImage = new Bitmap(image, new Size(TargetWidth, TargetHeight));
        
        // Convert to byte array
        using var outputMs = new MemoryStream();
        resizedImage.Save(outputMs, ImageFormat.Jpeg);
        return outputMs.ToArray();
    }

    /// <summary>
    /// Validate if the byte array is a valid image
    /// </summary>
    [SupportedOSPlatform("windows")]
    [SupportedOSPlatform("linux")]
    [SupportedOSPlatform("macos")]
    public static bool IsValidImage(byte[] imageBytes)
    {
        try
        {
            using var ms = new MemoryStream(imageBytes);
            using var image = Image.FromStream(ms);
            return true;
        }
        catch
        {
            return false;
        }
    }

    /// <summary>
    /// Get image dimensions
    /// </summary>
    [SupportedOSPlatform("windows")]
    [SupportedOSPlatform("linux")]
    [SupportedOSPlatform("macos")]
    public static (int width, int height) GetImageDimensions(byte[] imageBytes)
    {
        using var ms = new MemoryStream(imageBytes);
        using var image = Image.FromStream(ms);
        return (image.Width, image.Height);
    }
}
