import { ResourceProps } from 'ra-core';
import { FileText } from 'lucide-react';
import { NoteList } from './NoteList';
import { NoteEdit } from './NoteEdit';
import { NoteCreate } from './NoteCreate';

export const notes: ResourceProps = {
  name: "notes",
  list: NoteList,
  edit: NoteEdit,
  create: NoteCreate,
  recordRepresentation: "contenu",
  icon: FileText,
};
