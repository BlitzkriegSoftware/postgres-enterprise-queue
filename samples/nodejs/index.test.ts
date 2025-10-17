'use strict';
/**
 * Requires
 */
import { checkPort } from './checkPort';
import { v4 as uuidv4 } from 'uuid';
import { describe, test, expect } from '@jest/globals';
import { emptyGuid, PEQ, QueueError, QueueErrorCode } from './queue';

const item_count: number = 10;
const empty_msg: JSON = JSON.parse('{}');

/**
 * Class under test
 */
const queue = new PEQ();
const client_id = uuidv4();

function getRandomInt(min: number, max: number): number {
  min = Math.ceil(min); // Ensure min is an integer
  max = Math.floor(max); // Ensure max is an integer
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

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
  test('enqueue', () => {
    let isOk: boolean = true;

    for (let i: number = 0; i < item_count; i++) {
      try {
        queue.enqueue(empty_msg, emptyGuid, 0, client_id);
      } catch (error) {
        isOk = false;
      }
    }

    expect(isOk).toBe(true);
  });

  test('uow', () => {});
});
