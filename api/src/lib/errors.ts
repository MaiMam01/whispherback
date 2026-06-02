import type { Context } from "hono";
import type { ContentfulStatusCode } from "hono/utils/http-status";
import { ZodError } from "zod";
import type { ApiErrorBody } from "../types.js";

export class ApiError extends Error {
  constructor(
    public code: string,
    message: string,
    public status: ContentfulStatusCode = 400,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export function errorResponse(c: Context, code: string, message: string, status: ContentfulStatusCode = 400) {
  const body: ApiErrorBody = { error: { code, message } };
  return c.json(body, status);
}

export function handleError(c: Context, err: unknown) {
  if (err instanceof ApiError) {
    return errorResponse(c, err.code, err.message, err.status);
  }
  if (err instanceof ZodError) {
    const message = err.errors.map((e) => `${e.path.join(".")}: ${e.message}`).join("; ");
    return errorResponse(c, "VALIDATION_ERROR", message, 400);
  }
  console.error(err);
  return errorResponse(c, "INTERNAL_ERROR", "An unexpected error occurred", 500);
}
