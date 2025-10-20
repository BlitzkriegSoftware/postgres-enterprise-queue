import pytest
import uuid
import random

from datetime import datetime
from ..peq import PEQ 

test_count: int = 5

@pytest.fixture
def setup_tests():
    pass

def test_uow(setup_tests):
    flag : bool = True
    
    client = PEQ()
    assert client is not None

    client_id = str(uuid.uuid4())
    
    try:    
    
        for i in range(test_count):
            client.enqueue(PEQ.empty_json)
        
        for i in range(test_count):
            (msg_id, expires, msg_json) = client.dequeue(client_id)
            
            assert msg_id.__len__ > 0
            assert expires > datetime.now()
            assert msg_json.__len__ > 0
            
            random_number = random.randint(1, 100)
            
            if random_number < 15:
                client.rej(msg_id, client_id)
            elif random_number < 30:
                client.nak(msg_id, client_id)
            elif random_number < 45:
                client.rsh(msg_id, PEQ.default_reschedule_delay_seconds, client_id)
            else:
                client.ack(msg_id, client_id)
                
    except Exception as ex:
        print(ex)
        flag = False
        
    assert flag == True