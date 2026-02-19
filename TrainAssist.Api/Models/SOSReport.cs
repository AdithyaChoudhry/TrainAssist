using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TrainAssist.Api.Models;

/// <summary>
/// Represents an SOS emergency report
/// </summary>
public class SOSReport
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string ReporterName { get; set; } = string.Empty;

    public int? TrainId { get; set; }

    public int? CoachId { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    [StringLength(500)]
    public string? Message { get; set; }

    [Required]
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    // Navigation properties
    [ForeignKey(nameof(TrainId))]
    public virtual Train? Train { get; set; }

    [ForeignKey(nameof(CoachId))]
    public virtual Coach? Coach { get; set; }
}
