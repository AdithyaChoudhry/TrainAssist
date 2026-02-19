using System.ComponentModel.DataAnnotations;

namespace TrainAssist.Api.DTOs;

/// <summary>
/// Request DTO for creating an SOS report
/// </summary>
public class SOSReportRequestDto
{
    [Required(ErrorMessage = "Reporter name is required")]
    [StringLength(100, ErrorMessage = "Reporter name cannot exceed 100 characters")]
    public string ReporterName { get; set; } = string.Empty;

    public int? TrainId { get; set; }

    public int? CoachId { get; set; }

    [Range(-90, 90, ErrorMessage = "Latitude must be between -90 and 90")]
    public double? Latitude { get; set; }

    [Range(-180, 180, ErrorMessage = "Longitude must be between -180 and 180")]
    public double? Longitude { get; set; }

    [StringLength(500, ErrorMessage = "Message cannot exceed 500 characters")]
    public string? Message { get; set; }
}
