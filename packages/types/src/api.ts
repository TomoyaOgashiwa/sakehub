export type ApiResponse<T> = {
  data: T;
  message?: string;
};

export type ApiError = {
  error: string;
  message: string;
};

export type PaginatedResponse<T> = {
  data: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
};
