'use strict';
/**
 * Requires
 */
// import { checkPort } from './checkPort';
import { v4 as uuidv4 } from 'uuid';
import { test, expect, setDefaultTimeout, beforeEach } from 'bun:test';

import {
  emptyGuid,
  PEQ,
  QueueError,
  QueueErrorCode,
  defaultConnectionString,
  defaultMessageTtl,
  defaultLeaseSeconds,
  defaultRescheduleDelaySeconds
} from './queue';
import { getRandomInt } from './getRandomInt';

const item_count = 5;
const empty_msg = '{}';

/**
 * Class under test
 */
const queue = new PEQ();

/**
 * Unique client id
 */
const client_id = uuidv4();

/**
 * Increase test time
 */
setDefaultTimeout(5000);

/**
 * Reset Queue in between tests
 */
beforeEach(async () => {
  await queue.ResetQueue();
});

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
      const id = await queue.enqueue(
        empty_msg,
        emptyGuid,
        0,
        client_id,
        defaultMessageTtl
      );
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

test('uow', async () => {
  let isOk = true;
  for (let i = 0; i < item_count; i++) {
    try {
      const id = await queue.enqueue(
        empty_msg,
        emptyGuid,
        0,
        client_id,
        defaultMessageTtl
      );
      console.log(`enqueued ${id}`);
    } catch (error) {
      console.log(error);
      isOk = false;
    }
  }

  for (let i = 0; i < item_count; i++) {
    try {
      var qi = await queue.dequeue(client_id, defaultLeaseSeconds);
      console.log(`${qi.msg_id}, ${qi.expires}, ${qi.msg_json}`);
      const die_roll = getRandomInt(1, 100);
      if (die_roll < 20) {
        await queue.rej(qi.msg_id, client_id, 'REJ-Test');
      } else if (die_roll < 40) {
        await queue.nak(qi.msg_id, client_id, 'NAK-Test');
      } else if (die_roll < 60) {
        await queue.rsh(
          qi.msg_id,
          defaultRescheduleDelaySeconds,
          client_id,
          'RSH-Test'
        );
      } else {
        await queue.ack(qi.msg_id, client_id, 'ACK-Test');
      }
    } catch (error) {
      console.log(`UOW. Error: ${error}`);
      isOk = false;
    }
  }

  expect(isOk).toBe(true);
});
