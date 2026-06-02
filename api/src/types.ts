export type EntityType = "playlists" | "clips" | "schedules";

export interface SyncEntity {
  id: string;
  updatedAt: string;
  [key: string]: unknown;
}

export interface PushPayload {
  deviceId: string;
  timestamp: string;
  playlists: SyncEntity[];
  clips: SyncEntity[];
  schedules: SyncEntity[];
  deletedIds: {
    playlists: string[];
    clips: string[];
    schedules: string[];
  };
}

export interface JwtPayload {
  sub: string;
  email: string;
  type: "access" | "refresh";
}

export interface ApiErrorBody {
  error: {
    code: string;
    message: string;
  };
}
