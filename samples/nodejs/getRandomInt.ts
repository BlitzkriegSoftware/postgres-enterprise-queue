/**
 * Get Random Number
 * @param min {number}
 * @param max {number}
 * @returns {number} - Random min (inclusive) and max (exclusive)
 */
export function getRandomInt(min: number, max: number): number {
  min = Math.ceil(min); // Ensure min is an integer
  max = Math.floor(max); // Ensure max is an integer
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
