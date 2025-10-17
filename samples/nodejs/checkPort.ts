import * as net from 'net';

/**
 * Tests if the host is connectable on port
 * @function
 * @param host {string}
 * @param port {number}
 * @returns {boolean}
 */
export function checkPort(host: string, port: number): Promise<boolean> {
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