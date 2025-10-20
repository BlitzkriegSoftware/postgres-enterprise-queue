using System.Diagnostics.CodeAnalysis;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Xunit.Abstractions;

namespace queue.test.csproj;

[ExcludeFromCodeCoverage]
public class Queue_Test
{
    #region "Privates"
    Random dice = new Random();
    private readonly ITestOutputHelper _testOutputHelper;
    #endregion

    /// <summary>
    /// CTOR
    /// <para>
    /// Clear Queue Tables before every test
    /// </para>
    /// </summary>
    public Queue_Test(ITestOutputHelper testOutputHelper)
    {
        _testOutputHelper = testOutputHelper;

        var queue = MakeClient();
        queue.ResetQueue();
    }

    /// <summary>
    /// Make Client w. Console Logger
    /// </summary>
    /// <returns>PEQ Client</returns>
    PEQ MakeClient()
    {
        ILogger logger = LogFactoryHelper.CreateLogger<Queue_Test>();
        PEQ queue = new PEQ(
            logger,
            PEQ.DefaultConnectionString,
            PEQ.DefaultSchemaName,
            PEQ.DefaultRoleName
        );
        return queue;
    }

    [Fact]
    public void Simulate_UoW()
    {
        bool isOk = true;
        const int test_count = 20;
        string client_id = Guid.NewGuid().ToString();

        PEQ queue = MakeClient();

        Assert.True(queue.QueueExists());

        // Queue up some messages
        for (int i = 0; i < test_count; i++)
        {
            queue.Enqueue(PEQ.EmptyJson);
        }

        Assert.True(queue.HasMessages());

        for (int i = 0; i < test_count; i++)
        {
            try
            {
                var qi = queue.Dequeue(client_id, PEQ.DefaultLeaseSeconds);
                var roll = dice.Next(1, 80);
                switch (roll)
                {
                    case < 15:
                        queue.Rej(qi.Msg_Id, client_id);
                        break;
                    case < 30:
                        queue.Nak(qi.Msg_Id, client_id);
                        break;
                    case < 45:
                        queue.Rsh(qi.Msg_Id, PEQ.DefaultRescheduleDelaySeconds, client_id);
                        break;
                    default:
                        queue.Ack(qi.Msg_Id, client_id);
                        break;
                }
            }
            catch (Exception ex)
            {
                isOk = false;
                Console.WriteLine(ex.ToString());
            }
        }
        Assert.True(isOk);
    }

    [Fact]
    public void Bad_Enqueue()
    {
        string client_id = Guid.NewGuid().ToString();

        PEQ queue = MakeClient();

        //act
        Action act = () =>
        {
            queue.Enqueue("");
        };

        //assert
        Exception exception = Assert.Throws<QueueException>(act);

        //act
        act = () =>
        {
            queue.Enqueue(PEQ.EmptyJson, string.Empty, 0, string.Empty);
        };

        //assert
        exception = Assert.Throws<QueueException>(act);
    }

    [Fact]
    public void Dequeue_Nothing()
    {
        PEQ queue = MakeClient();
        string client_id = Guid.NewGuid().ToString();
        var qi = queue.Dequeue(client_id, PEQ.DefaultLeaseSeconds);
        Assert.Equal(Guid.Empty, Guid.Parse(qi.Msg_Id));
    }

    [Fact]
    public void Bad_Enqueue_Prop()
    {
        PEQ queue = MakeClient();
        string client_id = Guid.NewGuid().ToString();
        queue.Enqueue(PEQ.EmptyJson, string.Empty, 0, client_id, 0);
    }

    [Fact]
    public void Bad_Four_Response()
    {
        int test_count = 3;
        PEQ queue = MakeClient();
        string client_id = Guid.NewGuid().ToString();
        for (int i = 0; i < test_count; i++)
        {
            queue.Enqueue(PEQ.EmptyJson);
        }
        var qi = queue.Dequeue(client_id, PEQ.DefaultLeaseSeconds);

        Action act = () =>
        {
            queue.Ack(string.Empty, client_id);
        };
        Exception exception = Assert.Throws<QueueException>(act);

        act = () =>
        {
            queue.Ack(qi.Msg_Id, string.Empty);
        };
        exception = Assert.Throws<QueueException>(act);

        act = () =>
        {
            queue.Ack(qi.Msg_Id, client_id, string.Empty);
        };
        exception = Assert.Throws<QueueException>(act);
    }

    [Fact]
    public void Test_Parser_Bad_Url()
    {
        Action act = () =>
        {
            var parser = NpgsqlConnectionStringParser.Parse(string.Empty);
        };

        Exception exception = Assert.Throws<ArgumentNullException>(act);
    }

    [Fact]
    public void No_Rows()
    {
        Assert.False(PEQ.HasRows(new System.Data.DataTable()));
    }

    [Fact]
    public void IsValidJson_Bad()
    {
        bool flag = false;

        string json = "";
        flag = PEQ.IsValidJson(json, out _);
        Assert.False(flag);

        json = "[  }]";
        flag = PEQ.IsValidJson(json, out _);
        Assert.False(flag);
    }
}
