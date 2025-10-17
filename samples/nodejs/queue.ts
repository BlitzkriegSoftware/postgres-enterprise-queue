import { v4 as uuidv4 } from 'uuid';
import * as pg from 'pg';

/**
 * Default connection string - the demo docker one
 * @constant
 */
export const defaultConnectionString =
  'postgresql://postgres:password123-@localhost:5432/postgres';

/**
 * Default Schema Name
 * @constant
 */
export const defaultSchemaName = 'test01';

/**
 * Default Role Name
 * @constant
 */
export const defaultRoleName = 'queue_role';

/**
 * Empty Guid
 * @constant
 */
export const emptyGuid: string = '00000000-0000-0000-0000-000000000000';

/**
 * Default: User
 * @constant
 */
export const defaultUser: string = 'system';

/**
 * Default: Lease in Seconds
 * @constant
 */
export const defaultLeaseSeconds: number = -1;

/**
 * Minumum size of a JSON payload
 * @constant
 */
export const minJsonSize: number = 2;

/**
 * Default: Reschedule Delay in Seconds
 * @constant
 */
export const defaultRescheduleDelaySeconds: number = 3600;

/**
 * Minumum lease duration in seconds
 * @constant
 */
export const minLeaseSeconds: number = 15;

/**
 * @type
 * QueueItem
 */
export type QueueItem = {
  /**
   * UUID/GUID of Message
   */
  msg_id: string;
  /**
   * Expire on this date/time
   */
  expires: Date;
  /**
   * JSON Payload
   */
  msg_json: JSON;
};

/**
 * @enum
 * QueueErrorCode
 */
export enum QueueErrorCode {
  Unknown,
  BadUuid,
  BadJson,
  BadField,
  NoMessageAvailable,
  LeaseExpired,
  InvalidClientId
}

/**
 * @class
 * Custom Error: Queue Error
 */
export class QueueError extends Error {
  public readonly queueErrorCode: QueueErrorCode = QueueErrorCode.Unknown;
  /**
   * CTOR
   * @constructor
   * @param message {string}
   * @param queueErrorCode {QueueErrorCode} - Custom Error Code
   */
  constructor(message: string, queueErrorCode: QueueErrorCode) {
    super(message);
    this.name = 'CustomValidationError'; // Set the name for identification
    this.queueErrorCode = queueErrorCode;
    Object.setPrototypeOf(this, QueueError.prototype);
  }
}

/**
 * The Postgres Enterprise Queue - NodeJs Wrapper
 * @class
 */
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
    connectionString: string = defaultConnectionString,
    schemaname: string = defaultSchemaName,
    rolename: string = defaultRoleName
  ) {
    this.connectionString = connectionString;
    this.schemaName = schemaname;
    this.roleName = rolename;
  }

  /**
   * True if is falsy or just whitespace
   * @name #isBlank
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

  /**
   * Validate a string is a valid UUID/GUID
   * @name #isValidUuid
   * @function
   * @param uuid {String} - String to test
   * @returns {Boolean} - True if is a valid UUID/GUID
   */
  static isValidUuid(uuid: string): boolean {
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    return uuidRegex.test(uuid);
  }

  /**
   * Enqueue a message
   * @name #enqueue
   * @param msg_json {JSON}
   * @param message_id {string} - valid UUID/GUID or empty string to autogenerate one
   * @param delay_seconds {integer} - delay making message available for X seconds
   * @param who_by {string} - who enqueued message
   * @param item_ttl {number} - how long should it live, zero is take system default
   * @returns {string} - the computed message_id
   */
  enqueue(
    msg_json: JSON,
    message_id: string = uuidv4(),
    delay_seconds: number = 0,
    who_by: string = defaultUser,
    item_ttl: number = 0
  ): string {
    if (JSON.stringify(msg_json).length < minJsonSize) {
      throw new QueueError(
        'JSON Payload invalid (small)',
        QueueErrorCode.BadJson
      );
    }
    if (!PEQ.isValidUuid(message_id) || message_id == emptyGuid) {
      message_id = uuidv4();
    }
    if (PEQ.isBlank(who_by)) {
      who_by = defaultUser;
    }
    if (item_ttl <= 0) {
      throw new QueueError(
        'item_ttl must be reasonable number of minutes',
        QueueErrorCode.BadField
      );
    }

    return message_id;
  }

  /**
   * Dequeue one message
   * @name #dequeue
   * @param client_id {string} - unique client id. If in doubt have the client use a guid per thread/process
   * @param lease_seconds {number} - '-1' mean use the system default lease
   * @returns {QueueItem}
   */
  dequeue(
    client_id: string,
    lease_seconds: number = defaultLeaseSeconds
  ): QueueItem {
    let message_id: string = emptyGuid;
    let expires: Date = new Date();
    let msg_json: JSON = JSON.parse('{}');

    if (PEQ.isBlank(client_id)) {
      throw new QueueError(
        'Bad Client Id (too small)',
        QueueErrorCode.InvalidClientId
      );
    }

    return {
      msg_id: message_id,
      expires: expires,
      msg_json
    };
  }

  /**
   * Ack - Unit of Work - Success - To History
   * @name #ack
   * @function
   * @param message_id {string} - valid UUID/GUID
   * @param who_by {string}
   * @param reason_why {string}
   */
  ack(
    message_id: string,
    who_by: string = defaultUser,
    reason_why: string = 'ack'
  ) {
    if (!PEQ.isValidUuid(message_id)) {
      throw new QueueError('Bad message id', QueueErrorCode.BadUuid);
    }
    if (PEQ.isBlank(who_by)) {
      who_by = defaultUser;
    }
    if (PEQ.isBlank(reason_why)) {
      reason_why = 'ack';
    }
  }

  /**
   * Nak - Unit of Work - Can't Finish - Short Reschedule
   * @function
   * @param message_id {string} - valid UUID/GUID
   * @param who_by {string}
   * @param reason_why {string}
   */
  nak(
    message_id: string,
    who_by: string = defaultUser,
    reason_why: string = 'nak'
  ) {
    if (!PEQ.isValidUuid(message_id)) {
      throw new QueueError('Bad message id', QueueErrorCode.BadUuid);
    }
    if (PEQ.isBlank(who_by)) {
      who_by = defaultUser;
    }
    if (PEQ.isBlank(reason_why)) {
      reason_why = 'nak';
    }
  }

  /**
   * Rej - Unit of Work - Bad Message - To Dead Letter
   * @function
   * @param message_id {string} - valid UUID/GUID
   * @param who_by {string}
   * @param reason_why {string}
   */
  rej(
    message_id: string,
    who_by: string = defaultUser,
    reason_why: string = 'rej'
  ) {
    if (!PEQ.isValidUuid(message_id)) {
      throw new QueueError('Bad message id', QueueErrorCode.BadUuid);
    }
    if (PEQ.isBlank(who_by)) {
      who_by = defaultUser;
    }
    if (PEQ.isBlank(reason_why)) {
      reason_why = 'rej';
    }
  }

  /**
   * RSH - Unit of Work - Long Reschedule
   * @name #rsh
   * @function
   * @param message_id {string} - valid UUID/GUID
   * @param delay_seconds {number} - seconds to delay processing the message
   * @param who_by {string}
   * @param reason_why {string}
   */
  rsh(
    message_id: string,
    delay_seconds: number = defaultRescheduleDelaySeconds,
    who_by: string = defaultUser,
    reason_why: string = 'rsh'
  ) {
    if (!PEQ.isValidUuid(message_id)) {
      throw new QueueError('Bad message id', QueueErrorCode.BadUuid);
    }
    if (PEQ.isBlank(who_by)) {
      who_by = defaultUser;
    }
    if (delay_seconds < 0) {
      delay_seconds = defaultRescheduleDelaySeconds;
    }
    if (PEQ.isBlank(reason_why)) {
      reason_why = 'rsh';
    }
  }

  /**
   * Queue Exists
   * @function
   * @returns {boolean} - if schema contains a queue
   */
  queueExists(): boolean {
    let flag: boolean = false;

    return flag;
  }

  /**
   * Checks to see if there are messages
   * @function
   * @returns {boolean} - if there are messages
   */
  hasMessages(): boolean {
    let flag: boolean = false;

    return flag;
  }
}
