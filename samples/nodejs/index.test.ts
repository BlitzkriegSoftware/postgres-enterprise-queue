'use strict';
/**
 * Requires
 */
// import { checkPort } from './checkPort';
import { v4 as uuidv4 } from 'uuid';
import { test, expect, setDefaultTimeout } from 'bun:test';

import {
  emptyGuid,
  PEQ,
  QueueError,
  QueueErrorCode,
  defaultConnectionString,
  defaultMessageTtl
} from './queue';

const item_count = 5;
const empty_msg ='{}';

/**
 * Class under test
 */
const queue = new PEQ();
const client_id = uuidv4();

setDefaultTimeout(5000);

// beforeAll(async () => {
  
//   const isPostgresRunning = await checkPort('localhost', 5432);
//   if (!isPostgresRunning) {
//     throw new Error('Postgres not running');
//   }

//   if (!queue.queueExists()) {
//     throw new Error('Queue not created');
//   }

// });

test('enqueue', async () => {
  let isOk = true;

  for (let i = 0; i < item_count; i++) {
    try {
      const id = await queue.enqueue(empty_msg, emptyGuid, 0, client_id, defaultMessageTtl);
      console.log(`enqueued ${id}`);
    } catch (error) {
      console.log(error);
      isOk = false;
    }
  }
  expect(isOk).toBe(true);

  isOk = await queue.hasMessages();
  expect(isOk).toBe(true);
});

test('uow', () => {});
