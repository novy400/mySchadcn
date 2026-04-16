import { ResourceProps } from 'ra-core';
import { CheckSquare } from 'lucide-react';
import { TaskList } from './TaskList';
import { TaskEdit } from './TaskEdit';
import { TaskCreate } from './TaskCreate';

export const tasks: ResourceProps = {
  name: "tasks",
  list: TaskList,
  edit: TaskEdit,
  create: TaskCreate,
  recordRepresentation: "titre",
  icon: CheckSquare,
};
