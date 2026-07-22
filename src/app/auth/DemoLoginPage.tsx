import { useState } from 'react';
import { Form, required, useLogin, useNotify } from 'ra-core';
import type { FieldValues, SubmitHandler } from 'react-hook-form';
import { TextInput } from '@/components/admin';
import { Notification } from '@/components/admin/notification';
import { Button } from '@/components/ui/button';
import { demoAccountHints } from './demoIdentityAdapter';

export const DemoLoginPage = ({ redirectTo }: { redirectTo?: string }) => {
  const login = useLogin();
  const notify = useNotify();
  const [isPending, setIsPending] = useState(false);

  const handleSubmit: SubmitHandler<FieldValues> = async (values) => {
    setIsPending(true);
    try {
      await login(values, redirectTo);
    } catch (error) {
      notify(error instanceof Error ? error.message : 'Connexion impossible', { type: 'error' });
    } finally {
      setIsPending(false);
    }
  };

  return (
    <main className="flex min-h-screen items-center justify-center bg-muted p-6">
      <section className="w-full max-w-md space-y-6 rounded-lg border bg-background p-8 shadow-sm">
        <header className="space-y-2 text-center">
          <h1 className="text-2xl font-semibold">Connexion</h1>
          <p className="text-sm text-muted-foreground">Prototype CRM — comptes de démonstration</p>
        </header>

        <Form className="space-y-4" onSubmit={handleSubmit}>
          <TextInput source="email" label="E-mail" type="email" validate={required()} />
          <TextInput source="password" label="Mot de passe" type="password" validate={required()} />
          <Button type="submit" className="w-full" disabled={isPending}>
            Se connecter
          </Button>
        </Form>

        <div className="space-y-2 rounded-md border p-3 text-sm">
          <p className="font-medium">Accès de démonstration</p>
          <ul className="space-y-1 text-muted-foreground">
            {demoAccountHints.map((account) => (
              <li key={account.email}>
                {account.label} : <code>{account.email}</code> / <code>{account.password}</code>
              </li>
            ))}
          </ul>
          <p className="text-xs text-muted-foreground">
            Ces identifiants sont publics et ne doivent jamais être utilisés en production.
          </p>
        </div>
      </section>
      <Notification />
    </main>
  );
};
