/**
 * @fileoverview Centralized error handling middleware for Express applications.
 *
 * This module provides robust error handling that:
 * - Normalizes all errors to a consistent format
 * - Distinguishes between application errors and unexpected exceptions
 * - Provides appropriate error responses based on environment
 * - Maintains trace IDs for distributed debugging
 * - Handles 404 Not Found responses
 *
 * @module middleware/error
 */

import { randomUUID } from 'crypto';

import { Request, Response, NextFunction } from 'express';

import config from '../config';
import { AppError, ErrorCode, createError } from '../errors';

<<<<<<< HEAD
const UNKNOWN_ERROR_FALLBACK = 'Unknown error';

/**
 * Centralized holder for regex patterns used by the error middleware.
 * Ensures patterns are compiled once and reused.
 */
export class ErrorCleanupPatterns {
  // Matches ANSI escape sequences to strip terminal color/style codes from error messages
  public static readonly ansiEscapePattern: RegExp = /\x1B\[[0-?]*[ -/]*[@-~]/g;

  public static sanitizeMessage(message: string): string {
    const sanitized = message.replace(ErrorCleanupPatterns.ansiEscapePattern, '').trim();
    return sanitized || UNKNOWN_ERROR_FALLBACK;
  }
}

/**
 * Safely converts any thrown value to an Error object.
 *
 * JavaScript allows throwing any value, not just Error objects. This function
 * ensures that any caught value is converted to a proper Error instance for
 * consistent error handling and logging.
 *
 * Conversion rules:
 * - Error instances: returned as-is
 * - null/undefined: returns Error with 'Unknown error' message
 * - strings: wraps in Error with the string as message
 * - numbers/booleans: converts to string, wraps in Error
 * - objects: attempts JSON.stringify, wraps result in Error
 * - other types (symbol, bigint, function): returns Error with type indicator
 *
 * @param err - Any value that was thrown
 * @returns A proper Error object
 *
 * @example
 * try {
 *   throw 'Something went wrong'; // Bad practice, but supported
 * } catch (e) {
 *   const error = convertToError(e);
 *   console.log(error.message); // 'Something went wrong'
 * }
 *
 * @example
 * try {
 *   throw { code: 'ERR_001', reason: 'Invalid input' };
 * } catch (e) {
 *   const error = convertToError(e);
 *   console.log(error.message); // '{"code":"ERR_001","reason":"Invalid input"}'
 * }
 */
const convertToError = (err: unknown): Error => {
  if (err instanceof Error) {
    return err;
  }
  if (err === null || err === undefined) {
    return new Error(UNKNOWN_ERROR_FALLBACK);
=======
/**
 * File path pattern configuration for error message sanitization.
 * Extracting these into named constants improves maintainability and prevents
 * divergence between Unix and Windows path handling.
 */
class FilePathPatterns {
  /**
   * Common file extensions that may appear in error messages and should be redacted.
   * This shared configuration ensures consistency across platforms.
   */
  private static readonly FILE_EXTENSIONS = 'js|ts|py|java|go|rb|json|yaml|yml|env|config';

  /**
   * Unix-style file path pattern (forward slashes).
   * Matches paths like: /app/src/file.ts, /utils/helper.js
   * Requires at least one directory separator to avoid false positives.
   */
  static readonly UNIX_FILE_PATH = new RegExp(
    `\\/(?:[\\w\\-.]+\\/)+[\\w\\-.]+\\.(?:${FilePathPatterns.FILE_EXTENSIONS})`,
    'gi'
  );

  /**
   * Windows-style file path pattern (backslashes with optional drive letter).
   * Matches paths like: C:\Users\App\file.ts, \\server\share\file.js
   * Requires at least one directory separator to avoid false positives.
   */
  static readonly WINDOWS_FILE_PATH = new RegExp(
    `(?:[a-zA-Z]:)?\\\\(?:[\\w\\-.]+\\\\)+[\\w\\-.]+\\.(?:${FilePathPatterns.FILE_EXTENSIONS})`,
    'gi'
  );
}

/**
 * Pre-compiled regex patterns for error message sanitization.
 * These patterns are compiled once at module load time for optimal performance.
 */
class ErrorSanitizationPatterns {
  /**
   * Whitelist of safe error message patterns that can be exposed to clients.
   * These are generic messages that don't reveal internal implementation details.
   */
  static readonly SAFE_PATTERNS: ReadonlyArray<RegExp> = Object.freeze([
    /^Invalid input/i,
    /^Validation failed/i,
    /^Authentication required/i,
    /^Access denied/i,
    /^Resource not found/i,
    /^Too many requests/i,
    /^Service unavailable/i,
    /^Unauthorized/i,
    /^Forbidden/i,
    /^Bad request/i,
    /^Conflict/i,
    /^Request timeout/i,
  ]);

  /**
   * Patterns that indicate sensitive information that should be removed.
   * These patterns use the global flag (g) for efficiency with String.prototype.replace(),
   * which creates a new regex iteration context for each call, making them safe to reuse.
   */
  static readonly SENSITIVE_PATTERNS: ReadonlyArray<RegExp> = Object.freeze([
    /at\s+[^\n:]+:\d+(?::\d+)?/gi, // Stack trace locations (at file.ts:10:5 or at file.ts:10)
    FilePathPatterns.UNIX_FILE_PATH, // Unix file paths (require at least one directory)
    FilePathPatterns.WINDOWS_FILE_PATH, // Windows file paths (require drive or UNC and at least one directory)
    /\/(?:etc|proc|var|usr|home)\/[^\s]*/gi, // System paths
    /Error:\s+[\w\s]+\n\s+at/gi, // Stack trace beginnings
    /\w+:\/\/[^\s]+/gi, // Generic connection strings (mongodb://, postgres://, etc.)
    /password[=:]\s*\S+/gi, // Password parameters
    /token[=:]\s*\S+/gi, // Token parameters
    /api[_-]?key[=:]\s*\S+/gi, // API key parameters
    /secret[=:]\s*\S+/gi, // Secret parameters
  ]);
}

/**
 * Maximum length for error messages exposed to clients
 * Messages longer than this are replaced with a generic message to prevent information disclosure
 */
const MAX_SAFE_ERROR_MESSAGE_LENGTH = 100;

/**
 * Sanitizes error messages to prevent leakage of sensitive information
 * @param message - The error message to sanitize
 * @returns Sanitized error message safe for client exposure
 */
function sanitizeErrorMessage(message: string): string {
  if (!message) {
    return 'Internal server error';
  }

  // Check if message matches any safe pattern
  const isSafe = ErrorSanitizationPatterns.SAFE_PATTERNS.some((pattern) => pattern.test(message));
  if (isSafe) {
    return message;
>>>>>>> origin/alert-autofix-37
  }

  // Remove sensitive information using pre-compiled patterns
  let sanitized = message;
  for (const pattern of ErrorSanitizationPatterns.SENSITIVE_PATTERNS) {
    sanitized = sanitized.replace(pattern, '[REDACTED]');
  }
<<<<<<< HEAD
  return new Error(ErrorCleanupPatterns.sanitizeMessage(message));
};
=======

  // If message was redacted or is too short after redaction, use generic message
  if (sanitized.includes('[REDACTED]')) {
    return 'Internal server error';
  }

  // Limit message length to prevent information disclosure through long error messages
  if (sanitized.length > MAX_SAFE_ERROR_MESSAGE_LENGTH) {
    return 'Internal server error';
  }

  return sanitized;
}
>>>>>>> origin/alert-autofix-37

/**
 * Global error handling middleware for Express applications.
 *
 * This middleware catches all errors passed to `next(error)` and provides
 * consistent error responses. It differentiates between:
 *
 * 1. **AppError instances**: Custom application errors with structured data
 *    - Uses the error's status code, message, and trace ID
 *    - Includes validation errors if present
 *    - Logs at appropriate level based on status code
 *
 * 2. **Unexpected errors**: All other errors (programming errors, etc.)
 *    - Returns 500 Internal Server Error
 *    - Hides internal details in production (security)
 *    - Shows full details in development for debugging
 *    - Generates new trace ID if not present
 *
 * Response format:
 * ```json
 * {
 *   "error": {
 *     "code": "ERROR_CODE",
 *     "message": "Human-readable message",
 *     "status": 400,
 *     "traceId": "uuid-v4",
 *     "timestamp": "2025-12-01T00:00:00.000Z",
 *     "details": {} // Optional validation errors
 *   }
 * }
 * ```
 *
 * @param err - The error that was thrown or passed to next()
 * @param req - Express request object
 * @param res - Express response object
 * @param _next - Express next function (unused but required for error middleware signature)
 *
 * @example
 * // Usage in Express app
 * app.use(errorMiddleware);
 *
 * // In route handlers, throw AppError for expected errors:
 * throw createError.badRequest('Invalid user ID');
 *
 * // Or pass to next() for unexpected errors:
 * try {
 *   await riskyOperation();
 * } catch (error) {
 *   next(error);
 * }
 */
export const errorMiddleware = (
  err: Error | AppError,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  const traceId = req.traceId || randomUUID();
  let logLevel: 'error' | 'warn' = 'error';

  // Handle null, undefined, or non-Error objects
  if (!err || !(err instanceof Error)) {
    const errorResponse = {
      error: {
        code: ErrorCode.INTERNAL_ERROR,
        message: 'Internal server error',
        traceId,
        timestamp: new Date().toISOString(),
      },
    };
    res.status(500).json(errorResponse);
    console.error('Application error:', {
      traceId,
      error: { message: 'Non-error object passed to error middleware', value: err },
      request: {
        method: req.method,
        url: req.url,
        userAgent: req.get('user-agent'),
        ip: req.ip,
      },
      timestamp: new Date().toISOString(),
    });
    return;
  }

  if (err instanceof AppError) {
    const errorResponse = {
      error: {
        code: err.code,
<<<<<<< HEAD
        message: ErrorCleanupPatterns.sanitizeMessage(err.message || UNKNOWN_ERROR_FALLBACK),
        status: err.statusCode,
=======
        message: err.message,
>>>>>>> origin/alert-autofix-37
        traceId: err.traceId,
        timestamp: err.timestamp,
      },
    };
    if (err.statusCode < 500) {
      logLevel = 'warn';
    }
    res.status(err.statusCode).json(errorResponse);
  } else {
<<<<<<< HEAD
    const sanitizedMessage = ErrorCleanupPatterns.sanitizeMessage(
      safeError.message || UNKNOWN_ERROR_FALLBACK
    );
    const errorResponse = {
      error: {
        code: ErrorCode.INTERNAL_ERROR,
        message:
          config.NODE_ENV === 'production' ? 'Internal server error' : sanitizedMessage,
        status: 500,
=======
    // Sanitize error message to prevent sensitive information leakage
    const sanitizedMessage =
      config.NODE_ENV === 'production'
        ? 'Internal server error'
        : sanitizeErrorMessage(err.message || 'Internal server error');

    const errorResponse = {
      error: {
        code: ErrorCode.INTERNAL_ERROR,
        message: sanitizedMessage,
>>>>>>> origin/alert-autofix-37
        traceId,
        timestamp: new Date().toISOString(),
      },
    };
    res.status(500).json(errorResponse);
  }

  const errorLog = {
    traceId,
    error: {
<<<<<<< HEAD
      name: safeError.name,
      message: ErrorCleanupPatterns.sanitizeMessage(
        safeError.message || UNKNOWN_ERROR_FALLBACK
      ),
      code: isAppError ? err.code : ErrorCode.INTERNAL_ERROR,
      stack: config.NODE_ENV !== 'production' ? safeError.stack : undefined,
=======
      name: err.name,
      message: err.message,
      code: err instanceof AppError ? err.code : ErrorCode.INTERNAL_ERROR,
      stack: config.NODE_ENV !== 'production' ? err.stack : undefined,
>>>>>>> origin/alert-autofix-37
    },
    request: {
      method: req.method,
      url: req.url,
      userAgent: req.get('user-agent'),
      ip: req.ip,
    },
    timestamp: new Date().toISOString(),
  };

  if (logLevel === 'error') {
    console.error('Application error:', errorLog);
  } else {
    console.warn('Client error:', errorLog);
  }
};

/**
 * Middleware to handle requests to undefined routes (404 Not Found).
 *
 * This middleware should be registered AFTER all valid routes but BEFORE
 * the error handling middleware. It catches any requests that don't match
 * defined routes and returns a standardized 404 response.
 *
 * Response format:
 * ```json
 * {
 *   "error": {
 *     "code": "NOT_FOUND",
 *     "message": "Route GET /undefined-path not found",
 *     "traceId": "uuid-v4",
 *     "timestamp": "2025-12-01T00:00:00.000Z"
 *   }
 * }
 * ```
 *
 * @param req - Express request object
 * @param res - Express response object
 * @param _next - Express next function (unused, responds directly)
 *
 * @example
 * // Correct middleware ordering in Express app:
 * app.use('/api', apiRoutes);           // 1. Define routes first
 * app.use(notFoundMiddleware);           // 2. Catch undefined routes
 * app.use(errorMiddleware);              // 3. Handle errors last
 *
 * @example
 * // Response for GET /undefined-route:
 * // HTTP 404
 * // {
 * //   "error": {
 * //     "code": "NOT_FOUND",
 * //     "message": "Route GET /undefined-route not found",
 * //     "traceId": "a1b2c3d4-...",
 * //     "timestamp": "2025-12-01T10:00:00.000Z"
 * //   }
 * // }
 */
export const notFoundMiddleware = (req: Request, res: Response, _next: NextFunction): void => {
  const error = createError.notFound(`Route ${req.method} ${req.url} not found`);
  const traceId = req.traceId || randomUUID();

  res.status(404).json({
    error: {
      code: error.code,
      message: error.message,
      traceId,
      timestamp: new Date().toISOString(),
    },
  });
};

export default errorMiddleware;
