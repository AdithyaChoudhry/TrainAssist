using Microsoft.EntityFrameworkCore;
using TrainAssist.Api.Data;
using TrainAssist.Api.Models;
using TrainAssist.Api.DTOs;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() 
    { 
        Title = "Train Assist API", 
        Version = "v1",
        Description = "API for Train Assist mobile application - crowd reporting and SOS features"
    });
});

// Configure PostgreSQL Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add CORS - Allow all origins for development
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

var app = builder.Build();

// Seed the database
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<AppDbContext>();
        
        // Ensure database is created
        Console.WriteLine("Ensuring database is created...");
        context.Database.EnsureCreated();
        Console.WriteLine("✅ Database ready");
        
        // Seed initial data
        DataSeeder.SeedData(context);
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while seeding the database.");
    }
}

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Train Assist API v1");
        c.RoutePrefix = "swagger";
    });
}

// Enable CORS
app.UseCors("AllowAll");

// Middleware to log all incoming requests
app.Use(async (context, next) =>
{
    var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
    logger.LogInformation("📥 {Method} {Path} from {RemoteIp}", 
        context.Request.Method, 
        context.Request.Path, 
        context.Connection.RemoteIpAddress);
    
    await next();
    
    logger.LogInformation("📤 {Method} {Path} - Status: {StatusCode}", 
        context.Request.Method, 
        context.Request.Path, 
        context.Response.StatusCode);
});

app.UseHttpsRedirection();

// Health check endpoint
app.MapGet("/api/health", () =>
{
    return Results.Ok(new
    {
        status = "healthy",
        timestamp = DateTime.UtcNow,
        version = "1.0.0"
    });
})
.WithName("HealthCheck")
.WithTags("Health");

// =============================================================================
// TRAIN ENDPOINTS
// =============================================================================

// GET /api/trains - Search trains by source and/or destination
app.MapGet("/api/trains", async (AppDbContext db, string? source, string? destination, ILogger<Program> logger) =>
{
    try
    {
        logger.LogInformation("GET /api/trains - Source: {Source}, Destination: {Destination}", 
            source ?? "all", destination ?? "all");

        var query = db.Trains.AsQueryable();

        // Filter by source if provided
        if (!string.IsNullOrWhiteSpace(source))
        {
            query = query.Where(t => t.Source.ToLower().Contains(source.ToLower()));
        }

        // Filter by destination if provided
        if (!string.IsNullOrWhiteSpace(destination))
        {
            query = query.Where(t => t.Destination.ToLower().Contains(destination.ToLower()));
        }

        var trains = await query.ToListAsync();

        var response = trains.Select(t => new TrainResponseDto
        {
            Id = t.Id,
            TrainName = t.TrainName,
            Source = t.Source,
            Destination = t.Destination,
            Timing = t.Timing,
            Platform = t.Platform
        }).ToList();

        return Results.Ok(response);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error retrieving trains");
        return Results.Problem("An error occurred while retrieving trains");
    }
})
.WithName("GetTrains")
.WithTags("Trains")
.Produces<List<TrainResponseDto>>(200);

// GET /api/trains/{trainId}/coaches - Get coaches for a specific train with latest crowd status
app.MapGet("/api/trains/{trainId}/coaches", async (int trainId, AppDbContext db, ILogger<Program> logger) =>
{
    try
    {
        logger.LogInformation("GET /api/trains/{TrainId}/coaches", trainId);

        // Check if train exists
        var trainExists = await db.Trains.AnyAsync(t => t.Id == trainId);
        if (!trainExists)
        {
            return Results.NotFound(new { error = $"Train with ID {trainId} not found" });
        }

        // Get coaches for the train
        var coaches = await db.Coaches
            .Where(c => c.TrainId == trainId)
            .Include(c => c.CrowdReports)
            .ToListAsync();

        var response = coaches.Select(coach =>
        {
            var latestReport = coach.CrowdReports
                .OrderByDescending(cr => cr.Timestamp)
                .FirstOrDefault();

            return new CoachStatusDto
            {
                CoachId = coach.Id,
                CoachName = coach.CoachName,
                LatestStatus = latestReport?.Status ?? "Unknown",
                LastReportedAt = latestReport?.Timestamp,
                LastReporterName = latestReport?.ReporterName
            };
        }).ToList();

        return Results.Ok(response);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error retrieving coaches for train {TrainId}", trainId);
        return Results.Problem("An error occurred while retrieving coaches");
    }
})
.WithName("GetCoaches")
.WithTags("Coaches")
.Produces<List<CoachStatusDto>>(200)
.Produces(404);

// =============================================================================
// CROWD REPORT ENDPOINTS
// =============================================================================

// POST /api/coaches/{coachId}/crowd - Submit a crowd report for a coach
app.MapPost("/api/coaches/{coachId}/crowd", async (int coachId, CrowdReportRequestDto request, AppDbContext db, ILogger<Program> logger) =>
{
    try
    {
        // Validate coach exists
        var coach = await db.Coaches.FindAsync(coachId);
        if (coach == null)
        {
            return Results.NotFound(new { error = $"Coach with ID {coachId} not found" });
        }

        // Validate reporter name
        if (string.IsNullOrWhiteSpace(request.ReporterName))
        {
            return Results.BadRequest(new { error = "Reporter name is required" });
        }

        // Normalize and validate status
        var normalizedStatus = request.Status.Trim();
        var validStatuses = new[] { "Low", "Medium", "High" };
        
        if (!validStatuses.Contains(normalizedStatus, StringComparer.OrdinalIgnoreCase))
        {
            return Results.BadRequest(new { error = "Status must be 'Low', 'Medium', or 'High'" });
        }

        // Normalize status to proper case
        normalizedStatus = validStatuses.First(s => s.Equals(normalizedStatus, StringComparison.OrdinalIgnoreCase));

        // Create crowd report
        var crowdReport = new CrowdReport
        {
            CoachId = coachId,
            ReporterName = request.ReporterName.Trim(),
            Status = normalizedStatus,
            Timestamp = DateTime.UtcNow
        };

        db.CrowdReports.Add(crowdReport);
        await db.SaveChangesAsync();

        logger.LogInformation("POST /api/coaches/{CoachId}/crowd - Reporter: {ReporterName}, Status: {Status}", 
            coachId, request.ReporterName, normalizedStatus);

        var response = new CrowdReportResponseDto
        {
            Id = crowdReport.Id,
            CoachId = crowdReport.CoachId,
            ReporterName = crowdReport.ReporterName,
            Status = crowdReport.Status,
            Timestamp = crowdReport.Timestamp
        };

        return Results.Created($"/api/coaches/{coachId}/crowd/{crowdReport.Id}", response);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error creating crowd report for coach {CoachId}", coachId);
        return Results.Problem("An error occurred while creating the crowd report");
    }
})
.WithName("ReportCrowd")
.WithTags("Coaches")
.Produces<CrowdReportResponseDto>(201)
.Produces(400)
.Produces(404);

// =============================================================================
// SOS ENDPOINTS
// =============================================================================

// POST /api/sos - Submit an SOS emergency report
app.MapPost("/api/sos", async (SOSReportRequestDto request, AppDbContext db, ILogger<Program> logger) =>
{
    try
    {
        // Validate reporter name
        if (string.IsNullOrWhiteSpace(request.ReporterName))
        {
            return Results.BadRequest(new { error = "Reporter name is required" });
        }

        // Validate TrainId if provided
        if (request.TrainId.HasValue)
        {
            var trainExists = await db.Trains.AnyAsync(t => t.Id == request.TrainId.Value);
            if (!trainExists)
            {
                return Results.NotFound(new { error = $"Train with ID {request.TrainId} not found" });
            }
        }

        // Validate CoachId if provided
        if (request.CoachId.HasValue)
        {
            var coachExists = await db.Coaches.AnyAsync(c => c.Id == request.CoachId.Value);
            if (!coachExists)
            {
                return Results.NotFound(new { error = $"Coach with ID {request.CoachId} not found" });
            }
        }

        // Create SOS report
        var sosReport = new SOSReport
        {
            ReporterName = request.ReporterName.Trim(),
            TrainId = request.TrainId,
            CoachId = request.CoachId,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Message = request.Message?.Trim(),
            Timestamp = DateTime.UtcNow
        };

        db.SOSReports.Add(sosReport);
        await db.SaveChangesAsync();

        logger.LogWarning("🚨 SOS REPORT - Reporter: {ReporterName}, Train: {TrainId}, Coach: {CoachId}, Message: {Message}", 
            request.ReporterName, 
            request.TrainId?.ToString() ?? "N/A", 
            request.CoachId?.ToString() ?? "N/A", 
            request.Message ?? "N/A");

        var response = new SOSReportResponseDto
        {
            Id = sosReport.Id,
            ReporterName = sosReport.ReporterName,
            TrainId = sosReport.TrainId,
            CoachId = sosReport.CoachId,
            Latitude = sosReport.Latitude,
            Longitude = sosReport.Longitude,
            Message = sosReport.Message,
            Timestamp = sosReport.Timestamp
        };

        return Results.Created($"/api/sos/{sosReport.Id}", response);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error creating SOS report");
        return Results.Problem("An error occurred while creating the SOS report");
    }
})
.WithName("CreateSOSReport")
.WithTags("SOS")
.Produces<SOSReportResponseDto>(201)
.Produces(400)
.Produces(404);

// GET /api/sos - Get recent SOS reports
app.MapGet("/api/sos", async (AppDbContext db, ILogger<Program> logger) =>
{
    try
    {
        logger.LogInformation("GET /api/sos - Retrieving recent SOS reports");

        var sosReports = await db.SOSReports
            .Include(s => s.Train)
            .Include(s => s.Coach)
            .OrderByDescending(s => s.Timestamp)
            .Take(50)
            .ToListAsync();

        var response = sosReports.Select(s => new SOSReportResponseDto
        {
            Id = s.Id,
            ReporterName = s.ReporterName,
            TrainId = s.TrainId,
            CoachId = s.CoachId,
            Latitude = s.Latitude,
            Longitude = s.Longitude,
            Message = s.Message,
            Timestamp = s.Timestamp
        }).ToList();

        logger.LogInformation("Retrieved {Count} SOS reports", response.Count);

        return Results.Ok(response);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error retrieving SOS reports");
        return Results.Problem("An error occurred while retrieving SOS reports");
    }
})
.WithName("GetSOSReports")
.WithTags("SOS")
.Produces<List<SOSReportResponseDto>>(200);

app.Run();

