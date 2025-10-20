from datetime import datetime
import psycopg2
import re
import uuid
    
class peq_client:
    """
    Default connection string - the demo docker one
    """
    default_connection_string = 'postgresql://postgres:password123-@localhost:5432/postgres'

    """
    Default Schema Name
    """
    default_schema_name = 'test01'

    """
    Default Role Name
    """
    default_role_name = 'queue_role'

    """
    Default: User
    """
    default_user = 'system'

    """
    Default Lease Seconds
    """
    default_lease_seconds = -1

    """
    Default: Reschedule Delay in Seconds
    """
    default_reschedule_delay_seconds = 3600

    """
    Default Message TTL
    """
    default_message_ttl = 4320

    """
    Empty Guid
    """
    empty_guid = '00000000-0000-0000-0000-000000000000'

    """
    Empty JSON
    """
    empty_json = '{}'

    """
    Minimum size of a JSON payload
    """
    min_json_size = 2

    """
    Minimum lease duration in seconds
    """
    min_lease_seconds = 15

    """
    Minimum TTL for a message in Minutes
    """
    min_message_ttl_minutes = 1440

    """
    Postgres Quote Character
    """
    postgres_quote = "'"

    """
    CTOR
    """    
    def __init__(
        self, 
        connection_string = default_connection_string, 
        schema_name =default_schema_name, 
        role_name = default_role_name
    ):
        self.connection_string = connection_string
        self.schema_name = schema_name
        self.role_name = role_name

    """
    enqueue
    """
    def enqueue(self, 
                json:str, 
                message_id: str = "", 
                delay_seconds: int = 0,
                who_by:str = default_user, 
                item_ttl: int = default_message_ttl
        ) -> str:

        if json.__len__ <= peq_client.min_json_size:
            raise ValueError("Invalid JSON Payload")

        if not message_id or message_id.__len__ <= 0 or message_id == peq_client.empty_guid:
            message_id = str(uuid.uuid4())

        if not who_by or who_by.__len__ <= 0:
            raise ValueError("Invalid who_by")
        
        if item_ttl < peq_client.min_message_ttl_minutes:
            item_ttl = peq_client.min_message_ttl_minutes

        sql: str = f"call ${self.schema_name}.enqueue({self.quote_it(json)}, {self.quote_it(message_id)}, ${delay_seconds}, {self.quote_it(who_by)}, ${item_ttl})"
        self.do_query(sql)
        
        return message_id
    
    """
    dequeue
    """
    def dequeue(self, client_id: str, lease_seconds: int = default_lease_seconds) -> tuple[str, datetime, str]:
        msg_id: str = peq_client.empty_guid
        expires: datetime = datetime.now()
        msg_json: str = peq_client.empty_guid
        
        sql: str = f"select b.msg_id, b.expires, b.msg_json from {self.schema_name}.dequeue({peq_client.quote_it(client_id)}, {lease_seconds}) as b"
        dt = self.do_query(sql)
        if self.has_rows(dt):
            msg_id = dt[0]["msg_id"]
            expires = dt[0]["expires"]
            msg_json = dt[0]["msg_json"]
        
        return msg_id, expires, msg_json
        
    """
    Acknowledgement (ack)
    """
    def ack(self, message_id:str,  who_by:str = default_user, reason_why: str = "ack"):
        sql : str = f"call ${self.schema_name}.message_ack({self.quoteIt(message_id)}, {self.quoteIt(who_by)}, {self.quoteIt(reason_why)})"
        self.do_query(sql)
    
    """
    Negative Ack (nak)
    """
    def nak(self, message_id:str,  who_by:str = default_user, reason_why: str = "nak"):
        sql : str = f"call ${self.schema_name}.message_nak({self.quoteIt(message_id)}, {self.quoteIt(who_by)}, {self.quoteIt(reason_why)})"
        self.do_query(sql)
    
    """
    Reject (rej)
    """
    def rej(self, message_id:str,  who_by:str = default_user, reason_why: str = "rej"):
        sql : str = f"call ${self.schema_name}.message_rej({self.quoteIt(message_id)}, {self.quoteIt(who_by)}, {self.quoteIt(reason_why)})"
        self.do_query(sql)
    
    """
    Reschedule (rsh)
    """
    def rsh(self, message_id:str, delay_seconds:int = 0, who_by:str = default_user, reason_why: str = "rsh"):
        sql: str = f"call {self.schema_name}.message_reschedule({self.quote_it(message_id)}, {delay_seconds}, {self.quote_it(who_by)}, {self.quote_it(reason_why)})"
        self.do_query(sql)
    
    """
    Test to see if a queue exists
    """
    def queue_exists(self) -> bool:
        sql: str = f"SELECT c.relname AS object_name, CASE c.relkind WHEN 'r' THEN 'TABLE' WHEN 'v' THEN 'VIEW' WHEN 'm' THEN 'MATERIALIZED_VIEW' WHEN 'S' THEN 'SEQUENCE' ELSE 'OTHER_RELATION' END AS object_type FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = '{self.schema_name}' AND c.relkind IN ('r', 'v', 'm', 'S') ORDER BY object_type, object_name"
        dt = self.do_query(self, sql)
        return self.has_rows(dt)
    
    """
    Test to see if a queue has messages
    """
    def has_messages(self) -> bool:
        sql: str = f"select count(1) as CT from {self.schemaName}.message_queue"
        dt = self.do_query(self, sql)
        return self.has_rows(dt)
    
    """
    Reset a queue to empty state
    """
    def reset_queue(self):
        sql: str = f"CALL test01.reset_queue()"
        self.do_query(self, sql)

    """
    Does a query give sql returns rows
    """
    def do_query(self, sql: str) -> list[tuple[any]]:
        try:
            conn = psycopg2.connect(self.connection_string)
            cur = conn.cursor()
            cur.execute(sql)
            rows = cur.fetchall()
            return rows

        except psycopg2.Error as e:
            print(f"Error connecting to PostgreSQL: {e}")

        finally:
            if conn:
                cur.close()
                conn.close()
    
    """
    Test to see if data table has rows
    """
    def has_rows(self, dt:list[tuple[any]]) -> bool:
        if dt is None:
            return False
        
        if dt.count <= 0:
            return False
        
        return True
    
    """
    Postgres quote a string
    """
    def quote_it(self, text, delim: str = postgres_quote) -> str:
        if text is None:
            text = ""
        if not text:
            text = ""
        text = text.strip()
        if not text.startswith(delim):
            text = delim + text
        if not text.endswith(delim):
            text = text + delim
        return text
    
        """
        Test is a string a valid uuid/guid
        """
    def is_uuid(self, text: str) -> bool:
        pattern = "/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i"
        return re.match(pattern, text) is not None