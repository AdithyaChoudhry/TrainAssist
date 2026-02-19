using System.ComponentModel.DataAnnotations;

namespace TrainAssist.Api.Models;

/// <summary>
/// Represents a train in the system
/// </summary>
public class Train
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string TrainName { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Source { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Destination { get; set; } = string.Empty;

    [Required]
    [StringLength(10)]
    public string Timing { get; set; } = string.Empty;

    [StringLength(10)]
    public string? Platform { get; set; }

    // Navigation property
    public virtual ICollection<Coach> Coaches { get; set; } = new List<Coach>();
}
