namespace TrainAssist.Api.DTOs;

/// <summary>
/// Response DTO for Train information
/// </summary>
public class TrainResponseDto
{
    public int Id { get; set; }
    public string TrainName { get; set; } = string.Empty;
    public string Source { get; set; } = string.Empty;
    public string Destination { get; set; } = string.Empty;
    public string Timing { get; set; } = string.Empty;
    public string? Platform { get; set; }
}
