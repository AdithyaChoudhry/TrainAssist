using System.ComponentModel.DataAnnotations;

namespace TrainAssist.Api.DTOs;

/// <summary>
/// Request DTO for creating a crowd report
/// </summary>
public class CrowdReportRequestDto
{
    [Required(ErrorMessage = "Reporter name is required")]
    [StringLength(100, ErrorMessage = "Reporter name cannot exceed 100 characters")]
    public string ReporterName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Status is required")]
    [RegularExpression("^(Low|Medium|High)$", ErrorMessage = "Status must be 'Low', 'Medium', or 'High'")]
    public string Status { get; set; } = string.Empty;
}
