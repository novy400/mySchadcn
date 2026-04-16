import { ResourceProps } from 'ra-core';
import { Eye } from 'lucide-react';
import { ContactSummaryList } from './ContactSummaryList';

export const contactsSummary: ResourceProps = {
  name: "contacts_summary",
  list: ContactSummaryList,
  options: { label: 'Vue contacts' },
  icon: Eye,
};
