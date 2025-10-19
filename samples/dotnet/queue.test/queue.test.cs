using System.Linq.Expressions;
using System.Runtime.CompilerServices;
using System.Text;
using Microsoft.Extensions.Logging;
using Xunit.Abstractions;

namespace queue.test.csproj;

public class Queue_Test
{
    Random dice = new Random();
    private readonly ITestOutputHelper _testOutputHelper;

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
        const int test_count = 10;
        string client_id = Guid.NewGuid().ToString();

        PEQ queue = MakeClient();

        // Queue up some messages
        for (int i = 0; i < test_count; i++)
        {
            queue.Enqueue(PEQ.EmptyJson);
        }

        for (int i = 0; i < test_count; i++)
        {
            try
            {
                var qi = queue.Dequeue(client_id, PEQ.DefaultLeaseSeconds);
                var roll = dice.Next(1, 100);
                switch (roll)
                {
                    case < 20:
                        queue.Rej(qi.Msg_Id, client_id);
                        break;
                    case < 40:
                        queue.Nak(qi.Msg_Id, client_id);
                        break;
                    case < 60:
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
}
