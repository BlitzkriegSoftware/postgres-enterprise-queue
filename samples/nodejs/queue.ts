import type crypto = require('crypto');
import type Guid = require('./Guid.ts');

import * as pg from 'pg';

export type QueueItem = {
    Id: crypto.UUID,
    Expires: Date,
    Message: JSON
};

export const emptyGuid: string = "00000000-0000-0000-0000-000000000000";

export class PEQ {

  /**
   * @field
   * Connection String - To Postgres SQL Server
   */
  private connectionString: string;
  /**
   * @field
   * Schema Name
   */
  private schemaName: string;
  /**
   * @field
   * Role Name (unused)
   */
  private roleName: string;

  /**
   * CTOR
   * @constructor
   * @param connectionString
   * @param schema
   * @param rolename
   */
  constructor(
    connectionString: string = 'postgresql://postgres:password123-@localhost:5432/postgres',
    schemaname: string = 'test01',
    rolename: string = ''
  ) {
    this.connectionString = connectionString;
    this.schemaName = schemaname;
    this.roleName = rolename;
  }

  /**
   * True if is falsy or just whitespace
   * @name isBlank
   * @function
   * @param {String} str
   * @returns {Boolean} isNullOrWhitespace
   */
  static isBlank(text: any) {
    return !text || /^\s*$/.test(text);
  }

  /**
   * Tests to see if passed argument is a number
   * @name #isNumber
   * @function
   * @param {*} value
   * @returns {boolean}
   */
  static isNumber(value: any) {
    return typeof value === 'number';
  }

  enqueue() {

  }

  dequeue() : QueueItem {
    msg_id: 
  }

  ack() {}

  nak() {}

  rej() {}

  rsh() {}


}
