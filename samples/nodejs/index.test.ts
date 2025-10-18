'use strict';
/**
 * Requires
 */
import * as pg from 'pg';
import { checkPort } from './checkPort';
import { v4 as uuidv4 } from 'uuid';
import { describe, test, expect } from '@jest/globals';
import {
  emptyGuid,
  PEQ,
  QueueError,
  QueueErrorCode,
  defaultConnectionString
} from './queue';

const item_count = 10;
const empty_msg = JSON.parse('{}');

/**
 * Class under test
 */
const queue = new PEQ();
const client_id = uuidv4();

beforeAll(async () => {
  const isPostgresRunning = await checkPort('localhost', 5432);
  if (!isPostgresRunning) {
    throw new Error('Postgres not running');
  }

  if (!queue.queueExists()) {
    throw new Error('Queue not created');
  }
}, 1000);

describe('uow', () => {
  
  test('enqueue', async () => {
    let isOk = true;

    for (let i: number = 0; i < item_count; i++) {
      try {
        const id = await queue.enqueue(empty_msg, emptyGuid, 0, client_id);
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
});
