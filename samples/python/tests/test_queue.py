from pytest import *
import uuid
import random
import logging
import logging.config
from datetime import datetime

import sys
sys.path.append("../peq_client/")
from peq_client import peq_client

test_count: int = 5

# Logging 
logging_config = {
    'version': 1,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'stream': sys.stdout,
            'level': 'DEBUG',
            'formatter': 'detailed',
        },
    },
    'formatters': {
        'detailed': {
            'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        },
    },
    'root': {
        'level': 'DEBUG',
        'handlers': ['console'],
    },
}
logging.config.dictConfig(logging_config)
logger = logging.getLogger(__name__)

def test_uow():
    flag : bool = True
    
    where_am_i: str = "ctor"
    
    client = peq_client.peq_client()
    assert client is not None

    client_id = str(uuid.uuid4())
    assert len(client_id) > 0
    
    try:    
    
        for i in range(test_count):
            where_am_i = "enqueue"
            msg_id = client.enqueue(client.empty_json)
            logging.info(f"{where_am_i}, Id: {msg_id}")
        
        for i in range(test_count):
            where_am_i = "dequeue"
            (msg_id, expires, msg_json) = client.dequeue(client_id)
            
            logging.info(f"{where_am_i}, Id: {msg_id}, Expires: {expires}, Json: {msg_json}")
            
            assert len(msg_id) > 0
            assert expires > datetime.now()
            assert len(str(msg_json)) > 0
            
            random_number = random.randint(1, 100)
            
            if random_number < 15:
                where_am_i = "rej"
                client.rej(msg_id, client_id, where_am_i)
            elif random_number < 30:
                where_am_i = "nak"
                client.nak(msg_id, client_id, where_am_i)
            elif random_number < 45:
                where_am_i = "rsh"
                client.rsh(msg_id, peq_client.default_reschedule_delay_seconds, client_id, where_am_i)
            else:
                where_am_i = "ack"
                client.ack(msg_id, client_id, where_am_i)
                
    except Exception as ex:
        print(f"{where_am_i}, Ex: {ex}")
        flag = False
        
    assert flag