import type { RaRecord } from 'ra-core';

export type TaskStatus = 'OPEN' | 'DONE';

export type Task = {
  contact_id: number;
  titre: string;
  status: TaskStatus;
  due_date: string;
} & Pick<RaRecord, 'id'>;
