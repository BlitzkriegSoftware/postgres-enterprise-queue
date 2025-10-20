using System.Diagnostics.CodeAnalysis;

namespace queue.test.csproj;

/// <summary>
/// Contains a postgresql connection details
/// From: <![CDATA[https://github.com/bolorundurowb/PostgresConnString.NET/tree/master/PostgresConnString.NET]]>
/// </summary>
public class NpgsqlConnectionStringParser
{
    /// <summary>
    /// The database server host address
    /// Default: ""
    /// </summary>
    public string Host { get; set; } = string.Empty;

    /// <summary>
    /// The port the database is on
    /// Default: 5432
    /// </summary>
    public int Port { get; set; } = 5432;

    /// <summary>
    /// The database name
    /// Default: ""
    /// </summary>
    public string Database { get; set; } = string.Empty;

    /// <summary>
    /// Sets if pooling is on
    /// Default: false
    /// </summary>
    public bool Pooling { get; set; } = false;

    /// <summary>
    /// The login user name
    /// Default: ""
    /// </summary>
    public string User { get; set; } = string.Empty;

    /// <summary>
    /// The login password
    /// Default: ""
    /// </summary>
    public string Password { get; set; } = string.Empty;

    /// <summary>
    /// Initialize with default values
    /// </summary>
    [ExcludeFromCodeCoverage]
    private NpgsqlConnectionStringParser() { }

    /// <summary>
    /// Initialize with specified values
    /// </summary>
    /// <param name="host">The database server host address</param>
    /// <param name="user">The login user name</param>
    /// <param name="password">The login password</param>
    /// <param name="database">The database name</param>
    /// <param name="port">The port the database is on</param>
    public NpgsqlConnectionStringParser(
        string host,
        string user,
        string password,
        string database,
        int? port = null
    )
    {
        if (!string.IsNullOrWhiteSpace(host))
            Host = host;

        if (!string.IsNullOrWhiteSpace(user))
            User = user;

        if (!string.IsNullOrWhiteSpace(password))
            Password = password;

        if (!string.IsNullOrWhiteSpace(database))
            Database = database;

        if (port.HasValue)
            Port = port.Value;
    }

    public static bool IsPostgresFormat(string connectionString)
    {
        return connectionString.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Parse a postgres connection url
    /// </summary>
    /// <param name="url">A postgres connection url</param>
    /// <returns>The <see cref="NpgsqlConnectionStringParser"/></returns>
    /// <exception cref="ArgumentNullException">Thrown on null input</exception>
    /// <exception cref="ArgumentException">Thrown on empty or whitespace input</exception>
    public static NpgsqlConnectionStringParser Parse(string url)
    {
        if (string.IsNullOrWhiteSpace(url))
            throw new ArgumentNullException(
                "Url cannot be null, empty or contain only whitespace characters.",
                nameof(url)
            );

        var (host, user, password, database, port) = Parser.Parse(url);
        return new NpgsqlConnectionStringParser(
            host,
            user,
            password,
            database ?? string.Empty,
            port
        );
    }

    /// <summary>
    /// Generates a formatted, valid Npgsql connection with the connection details
    /// </summary>
    /// <returns>A formatted <see cref="string"/></returns>
    public string ToNpgsqlConnectionString() =>
        $"User ID={User};Password={Password};Server={Host};Port={Port};Database={Database};Pooling={Pooling};SSL Mode=Prefer;Trust Server Certificate=true";
}

internal static class Parser
{
    internal static (string, string, string, string?, int?) Parse(string url)
    {
        var uri = new Uri(url);

        var databasePath = uri.AbsolutePath;
        var auth = string.IsNullOrWhiteSpace(uri.UserInfo) ? ":" : uri.UserInfo;
        var authParts = auth.Split(new[] { ':' }, 2);

        var host = uri.Host;
        var port = uri.Port;
        var user = authParts[0];
        var password = authParts[1];
        var databaseName = databasePath?.Trim('/');

        return (host, user, password, databaseName, port == -1 ? null : port);
    }
}
