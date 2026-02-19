using System.ComponentModel.DataAnnotations;

namespace TrainAssist.Api.Models;

/// <summary>
/// Represents a user in the Train Assist system
/// </summary>
public class User
{
    [Key]
    public Guid Id { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [StringLength(20)]
    public string? Phone { get; set; }
}
