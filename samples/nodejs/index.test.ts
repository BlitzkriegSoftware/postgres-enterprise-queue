'use strict';
/**
 * Requires
 */
import * as net from 'net';
import { describe, test, expect } from '@jest/globals';
import { PEQ, QueueError, QueueErrorCode } from './queue';

/**
 * Class under test
 */
const queue = new PEQ();

/**
 * Tests if the host is connectable on port
 * @function
 * @param host {string}
 * @param port {number}
 * @returns {boolean}
 */
function checkPort(host: string, port: number): Promise<boolean> {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    socket.setTimeout(1000); // Timeout after 1 second

    socket.on('connect', () => {
      socket.destroy();
      resolve(true); // Port is open
    });

    socket.on('timeout', () => {
      socket.destroy();
      resolve(false); // Connection timed out
    });

    socket.on('error', () => {
      socket.destroy();
      resolve(false); // Error (port likely closed or unreachable)
    });

    socket.connect(port, host);
  });
}

beforeAll(async () => {
    const isValidPort=await  checkPort('localhost', 5432);
    if(! isValidPort) {
        throw new Error('Postgres not running');
    }
    if(! queue.queueExists()) {
         throw new Error('Queue not created');
    }
}, 1000);

describe('uow', () => {

    test('enqueue', () => {


    });

    test('uow', () => {

        
    });


});
