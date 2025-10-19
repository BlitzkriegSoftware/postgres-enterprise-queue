namespace queue.test.csproj;

using System;
using System.Data;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;
using Npgsql;

#region  "Custom Exceptions"

/// <summary>
/// PEQ Client Error Codes
/// </summary>
public enum QueueErrorCode : int
{
    Unknown = 0,
    BadUuid,
    BadJson,
    BadField,
    NoMessageAvailable,
    LeaseExpired,
    InvalidClientId,
    QueryExecution,
}

/// <summary>
/// Custom Exception
/// </summary>
[Serializable]
[ExcludeFromCodeCoverage]
public class QueueException : Exception
{
    public QueueErrorCode ErrorCode = QueueErrorCode.Unknown;

    public QueueException()
        : base() { }

    public QueueException(string message)
        : base(message) { }

    public QueueException(string message, Exception innerException)
        : base(message, innerException) { }

    public QueueException(string message, QueueErrorCode errorCode)
        : base(message)
    {
        ErrorCode = errorCode;
    }

    public QueueException(string message, QueueErrorCode errorCode, Exception innerException)
        : base(message, innerException)
    {
        ErrorCode = errorCode;
    }
}

#endregion

/// <summary>
/// Queue Items returned by Dequeue()
/// </summary>
public class QueueItem
{
    /// <summary>
    /// Message Id (PK)
    /// </summary>
    public string Msg_Id { get; set; } = string.Empty;

    /// <summary>
    /// Message Expires
    /// </summary>
    public DateTime Expires { get; set; } = DateTime.MinValue;

    /// <summary>
    /// Message Payload
    /// </summary>
    public string Msg_Json { get; set; } = string.Empty;

    /// <summary>
    /// CTOR
    /// </summary>
    /// <param name="msg_id">(sic)</param>
    /// <param name="expires">(sic)</param>
    /// <param name="msg_json">(sic)</param>
    public QueueItem(string msg_id, DateTime expires, string msg_json)
    {
        this.Msg_Id = msg_id;
        this.Expires = expires;
        this.Msg_Json = msg_json;
    }
}

/// <summary>
/// Postgres Enterprise Queue (client)
/// </summary>
public class PEQ
{
    #region  "Constants"

    /// <summary>
    /// Default: Postgres Connection String (local docker)
    /// </summary>
    public const string DefaultConnectionString =
        "postgresql://postgres:password123-@localhost:5432/postgres";

    /// <summary>
    /// Default: Schema Name (for testing)
    /// </summary>
    public const string DefaultSchemaName = "test01";

    /// <summary>
    /// Default: Role Name
    /// (Unused)
    /// </summary>
    public const string DefaultRoleName = "queue_role";

    /// <summary>
    /// Default: User
    /// </summary>
    public const string DefaultUser = "system";

    /// <summary>
    /// Default: Lease Seconds
    /// </summary>
    public const int DefaultLeaseSeconds = -1;

    /// <summary>
    /// Default: Message Time to Live (TTL)
    /// </summary>
    public const int DefaultMessageTtl = 4320;

    /// <summary>
    /// Default: RSH Delay Seconds
    /// </summary>
    public const int DefaultRescheduleDelaySeconds = 3600;

    /// <summary>
    /// Minimum: Json Payload Size
    /// </summary>
    public const int MinJsonSize = 2;

    /// <summary>
    /// Minumum: Lease Seconds
    /// </summary>
    public const int MinLeaseSeconds = 15;

    /// <summary>
    /// Minimum TTL for a message in Minutes
    /// </summary>
    public const int MinMessageTtlMinutes = 1440;

    /// <summary>
    /// Empty: JSON payload
    /// </summary>
    public const string EmptyJson = "{}";

    /// <summary>
    /// Quote Character in Postgres
    /// </summary>
    public const string PostgresQuote = "'";

    /// <summary>
    /// RegEx for Validating UUID/GUID
    /// </summary>
    public static readonly Regex isGuid = new Regex(
        @"^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$",
        RegexOptions.Compiled
    );

    #endregion

    #region "Fields"

    private string connectionString = string.Empty;
    private string schemaName = string.Empty;
    private string roleName = string.Empty;
    private ILogger? logger;

    #endregion

    #region "CTOR"

    /// <summary>
    /// CTOR: Empty not allowd
    /// </summary>
    private PEQ() { }

    /// <summary>
    /// CTOR
    /// </summary>
    /// <param name="connectionString">(required) Postgres Connection String</param>
    /// <param name="schemaName">(required) Schema Name</param>
    /// <param name="roleName">(optional) (not used) (future) Role Name</param>
    public PEQ(ILogger logger, string connectionString, string schemaName, string roleName)
    {
        this.logger = logger;
        this.schemaName = schemaName;
        this.roleName = roleName;

        if (NpgsqlConnectionStringParser.IsPostgresFormat(connectionString))
        {
            var parser = NpgsqlConnectionStringParser.Parse(connectionString);
            parser.Pooling = false;
            connectionString = parser.ToNpgsqlConnectionString();
        }

        this.connectionString = connectionString ?? string.Empty;
    }

    #endregion

    #region "Helpers"

    /// <summary>
    /// Test if string is a valid GUID/UUID
    /// </summary>
    /// <param name="candidate"></param>
    /// <returns>True if so</returns>
    public static bool IsValidGuid(string candidate)
    {
        if (string.IsNullOrEmpty(candidate))
        {
            return false;
        }
        return isGuid.IsMatch(candidate);
    }

    /// <summary>
    /// Force Quotes around Postgres Strings
    /// </summary>
    /// <param name="text">string to quote</param>
    /// <returns>Quoted string</returns>
    public static string QuoteIt(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
            text = string.Empty;
        text = text.Trim();
        if (!text.StartsWith(PostgresQuote))
            text = PostgresQuote + text;
        if (!text.EndsWith(PostgresQuote))
            text = text + PostgresQuote;
        return text;
    }

    /// <summary>
    /// Has Rows
    /// </summary>
    /// <param name="dt">DataTable</param>
    /// <returns>True if so</returns>
    public static bool HasRows(DataTable dt)
    {
        return (dt != null) && (dt.Rows != null) && (dt.Rows.Count > 0);
    }

    /// <summary>
    /// Test if string is valid JSON
    /// </summary>
    /// <param name="jsonString">text</param>
    /// <returns>True if so</returns>
    public static bool IsValidJson(string jsonString, out JsonException? jsonValidationException)
    {
        jsonValidationException = null;

        if (string.IsNullOrWhiteSpace(jsonString))
        {
            return false;
        }

        try
        {
            // Attempt to parse the string into a JsonDocument.
            // Using a 'using' statement ensures the JsonDocument is properly disposed.
            // If parsing succeeds, it's valid JSON.
            using (JsonDocument doc = JsonDocument.Parse(jsonString))
            {
                return true;
            }
        }
        catch (JsonException ex)
        {
            // If a JsonException is caught, the string is not valid JSON.
            jsonValidationException = ex;
            return false;
        }
    }

    /// <summary>
    /// ValidateThreeFields
    /// </summary>
    /// <param name="message_id">Valid GUID/UUID</param>
    /// <param name="who_by">Who did it</param>
    /// <param name="reason_why">Why did they do it</param>
    /// <exception cref="QueueException"></exception>
    public void ValidateThreeFields(
        string message_id,
        string who_by = DefaultUser,
        string reason_why = ""
    )
    {
        if (!IsValidGuid(message_id))
            throw new QueueException("Bad ID", QueueErrorCode.BadUuid);

        if (string.IsNullOrWhiteSpace(who_by))
            throw new QueueException(
                $"{nameof(who_by)}='{who_by}' is invalid",
                QueueErrorCode.InvalidClientId
            );

        if (string.IsNullOrWhiteSpace(reason_why))
            throw new QueueException(
                $"{nameof(reason_why)}='{reason_why}' is invalid",
                QueueErrorCode.BadField
            );
    }

    #endregion

    #region "doQuery"

    /// <summary>
    /// doQuery(sql)
    /// </summary>
    /// <param name="sql">SQL Statement</param>
    /// <returns>Data Table</returns>
    public DataTable DoQuery(string sql)
    {
        var dataTable = new DataTable();

        var logMessage = $"DoQuery({sql})";
        Debug.WriteLine(logMessage);

        try
        {
            using var dataSource = NpgsqlDataSource.Create(this.connectionString);
            using var connection = dataSource.OpenConnection();
            // using var transaction = connection.BeginTransaction();
            using var command = connection.CreateCommand();
            command.CommandText = sql;
            command.CommandType = CommandType.Text;
            using var adapter = new NpgsqlDataAdapter(command);
            adapter.Fill(dataTable);
            logger?.LogInformation(logMessage);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"{logMessage}, ex: {ex}");
            logger?.LogError(ex, logMessage);
            throw new QueueException(logMessage, QueueErrorCode.QueryExecution, ex);
        }
        return dataTable;
    }
    #endregion

    /// <summary>
    /// Enqueue a message
    /// </summary>
    /// <param name="msg_json">Payload</param>
    /// <param name="message_id"></param>
    /// <param name="delay_seconds"></param>
    /// <param name="who_by"></param>
    /// <param name="item_ttl"></param>
    /// <returns></returns>
    /// <exception cref="QueueException"></exception>
    public string Enqueue(
        string msg_json,
        string message_id = "",
        int delay_seconds = 0,
        string who_by = DefaultUser,
        int item_ttl = DefaultMessageTtl
    )
    {
        JsonException? JsonError = null;
        if (string.IsNullOrWhiteSpace(msg_json) || (!IsValidJson(msg_json, out JsonError)))
            throw new QueueException(
                $"Invalid Payload {nameof(msg_json)}='{msg_json}', Ex: {((JsonError is null) ? "empty" : JsonError)}",
                QueueErrorCode.BadJson
            );

        if (string.IsNullOrWhiteSpace(message_id) || !IsValidGuid(message_id))
        {
            message_id = Guid.NewGuid().ToString();
        }

        if (string.IsNullOrWhiteSpace(who_by))
            throw new QueueException(
                $"Bad client: {nameof(who_by)}='{who_by}'",
                QueueErrorCode.InvalidClientId
            );

        if (item_ttl < MinMessageTtlMinutes)
            item_ttl = MinMessageTtlMinutes;

        string sql =
            $"call {this.schemaName}.enqueue({QuoteIt(msg_json)}, {QuoteIt(message_id)}, {delay_seconds}, {QuoteIt(who_by)}, {item_ttl});";

        _ = DoQuery(sql);

        return message_id;
    }

    /// <summary>
    /// DeQueue Message
    /// </summary>
    /// <param name="client_id"></param>
    /// <param name="lease_seconds"></param>
    /// <returns></returns>
    public QueueItem Dequeue(string client_id, int lease_seconds = DefaultLeaseSeconds)
    {
        string message_id = Guid.Empty.ToString();
        DateTime expires = DateTime.MinValue;
        string message_json = EmptyJson;

        string sql =
            $"select b.msg_id, b.expires, b.msg_json from {this.schemaName}.dequeue({QuoteIt(client_id)}, {lease_seconds}) as b;";

        var dt = DoQuery(sql);

        if (HasRows(dt))
        {
            message_id = dt.Rows[0]["msg_id"].ToString() ?? Guid.Empty.ToString();
            expires = (DateTime)dt.Rows[0]["expires"];
            message_json = dt.Rows[0]["msg_json"].ToString() ?? EmptyJson;
        }

        return new QueueItem(message_id, expires, message_json);
    }

    /// <summary>
    /// ACK
    /// </summary>
    /// <param name="message_id">Valid GUID/UUID</param>
    /// <param name="who_by">Who did it</param>
    /// <param name="reason_why">Why did they do it</param>
    public void Ack(string message_id, string who_by = DefaultUser, string reason_why = "ack")
    {
        ValidateThreeFields(message_id, who_by, reason_why);

        string sql =
            $"call {this.schemaName}.message_ack({QuoteIt(message_id)}, {QuoteIt(who_by)}, {QuoteIt(reason_why)});";
        _ = DoQuery(sql);
    }

    /// <summary>
    /// NAK
    /// </summary>
    /// <param name="message_id">Valid GUID/UUID</param>
    /// <param name="who_by">Who did it</param>
    /// <param name="reason_why">Why did they do it</param>
    public void Nak(string message_id, string who_by = DefaultUser, string reason_why = "nak")
    {
        ValidateThreeFields(message_id, who_by, reason_why);

        string sql =
            $"call {this.schemaName}.message_nak({QuoteIt(message_id)}, {QuoteIt(who_by)}, {QuoteIt(reason_why)});";
        _ = DoQuery(sql);
    }

    /// <summary>
    /// REJ(ect)
    /// </summary>
    /// <param name="message_id">Valid GUID/UUID</param>
    /// <param name="who_by">Who did it</param>
    /// <param name="reason_why">Why did they do it</param>
    public void Rej(string message_id, string who_by = DefaultUser, string reason_why = "rej")
    {
        ValidateThreeFields(message_id, who_by, reason_why);

        string sql =
            $"call {this.schemaName}.message_rej({QuoteIt(message_id)}, {QuoteIt(who_by)}, {QuoteIt(reason_why)});";
        _ = DoQuery(sql);
    }

    /// <summary>
    /// Reschedule (RSH)
    /// </summary>
    /// <param name="message_id">Valid GUID/UUID</param>
    /// <param name="delay_seconds">Defer message delivery by X seconds</param>
    /// <param name="who_by">Who did it</param>
    /// <param name="reason_why">Why did they do it</param>
    public void Rsh(
        string message_id,
        int delay_seconds = DefaultRescheduleDelaySeconds,
        string who_by = DefaultUser,
        string reason_why = "rsh"
    )
    {
        ValidateThreeFields(message_id, who_by, reason_why);

        if (delay_seconds == 0)
            delay_seconds = DefaultRescheduleDelaySeconds;

        string sql =
            $"call {this.schemaName}.message_reschedule({QuoteIt(message_id)}, {delay_seconds}, {QuoteIt(who_by)}, {QuoteIt(reason_why)});";
        _ = DoQuery(sql);
    }

    /// <summary>
    /// Queue Exists?
    /// </summary>
    /// <returns>True if so</returns>
    public bool QueueExists()
    {
        string sql =
            $"SELECT c.relname AS object_name, CASE c.relkind WHEN 'r' THEN 'TABLE' WHEN 'v' THEN 'VIEW' WHEN 'm' THEN 'MATERIALIZED_VIEW' WHEN 'S' THEN 'SEQUENCE' ELSE 'OTHER_RELATION' END AS object_type FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = '{this.schemaName}' AND c.relkind IN('r', 'v', 'm', 'S') ORDER BY object_type, object_name;";
        var dt = DoQuery(sql);
        return HasRows(dt);
    }

    /// <summary>
    /// Has Messages
    /// </summary>
    /// <returns>True if so</returns>
    public bool HasMessages()
    {
        string sql = $"select count(1) as CT from {this.schemaName}.message_queue;";
        var dt = DoQuery(sql);
        return HasRows(dt);
    }

    /// <summary>
    /// Reset Queue
    /// <para>
    /// Empties out all queue tables
    /// </para>
    /// </summary>
    public void ResetQueue()
    {
        string sql = "CALL test01.reset_queue();";
        _ = DoQuery(sql);
    }
}
