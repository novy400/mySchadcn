import type { BaseData } from '../projections/buildSummaries';

const baseData: BaseData = {
  clients: [
    { id: 1, code: 'CLI001', nom: 'Dupont SA', ville: 'Paris', statut: 'ACTIF' },
    { id: 2, code: 'CLI002', nom: 'Martin SARL', ville: 'Lyon', statut: 'PROSPECT' },
  ],
  contacts: [
    { id: 1, client_id: 1, prenom: 'Jean', nom: 'Dupont', email: 'jean@dupont.fr', telephone: '0102030405' },
    { id: 2, client_id: 1, prenom: 'Claire', nom: 'Bernard', email: 'claire@dupont.fr', telephone: '0102030406' },
    { id: 3, client_id: 2, prenom: 'Sophie', nom: 'Martin', email: 'sophie@martin.fr', telephone: '0607080910' },
  ],
  tasks: [
    { id: 1, contact_id: 1, titre: 'Rappeler après devis', status: 'OPEN', due_date: '2026-04-03' },
    { id: 2, contact_id: 1, titre: 'Envoyer documentation', status: 'DONE', due_date: '2026-03-28' },
    { id: 3, contact_id: 3, titre: 'Planifier démonstration', status: 'OPEN', due_date: '2026-04-05' },
  ],
  notes: [
    { id: 1, contact_id: 1, contenu: 'Intéressé par une refonte de l’application.', date: '2026-03-27' },
    { id: 2, contact_id: 3, contenu: 'Souhaite un rappel début avril.', date: '2026-03-29' },
  ], 
  customers: [
    { id: 1, name: "Aviation Corp", type: "Sarl" },
    { id: 2, name: "Global Logistics", type: "SA" }
  ],
  customerSignalietiques: [
    { id: 1, adresse: "123 Rue de l'Air, Paris", phone: "0102030405", email: "contact@aviation.fr" },
    { id: 2, adresse: "45 Ave du Port, Marseille", phone: "0405060708", email: "info@globallog.com" }
  ],
  customerRisques: [
    { id: 1, score: 85, statut: "OK", lastReview: "2024-12-01" },
    { id: 2, score: 40, statut: "SURVEILLANCE", lastReview: "2024-12-20" }
  ],
  fournisseurs: [
    { id: 1, nom: 'Fournitures Pro', adresse: '12 rue des Ateliers', ville: 'Lille', telephone: '0320123456', email: 'contact@fourniturespro.fr' },
    { id: 2, nom: 'Logis Transport', adresse: '8 avenue du Port', ville: 'Marseille', telephone: '0491123456', email: 'info@logistransport.fr' },
  ],
  orders: [
    {
      id: 1,
      reference: 'CMD-2026-0001',
      date: '2026-04-01',
      customer_id: 1,
      basket: [
        { product_id: 101, quantity: 2 },
        { product_id: 203, quantity: 1 },
      ],
      total_ex_taxes: 580,
      delivery_fees: 24,
      tax_rate: 0.2,
      taxes: 120.8,
      total: 724.8,
      status: 'ordered',
      returned: false,
    },
    {
      id: 2,
      reference: 'CMD-2026-0002',
      date: '2026-03-28',
      customer_id: 2,
      basket: [
        { product_id: 305, quantity: 5 },
      ],
      total_ex_taxes: 1250,
      delivery_fees: 0,
      tax_rate: 0.2,
      taxes: 250,
      total: 1500,
      status: 'delivered',
      returned: false,
    },
    {
      id: 3,
      reference: 'CMD-2026-0003',
      date: '2026-03-20',
      customer_id: 1,
      basket: [
        { product_id: 101, quantity: 1 },
      ],
      total_ex_taxes: 290,
      delivery_fees: 18,
      tax_rate: 0.2,
      taxes: 61.6,
      total: 369.6,
      status: 'canceled',
      returned: false,
    },
    {
      id: 4,
      reference: 'CMD-2026-0004',
      date: '2026-03-18',
      customer_id: 2,
      basket: [
        { product_id: 407, quantity: 3 },
        { product_id: 512, quantity: 2 },
      ],
      total_ex_taxes: 860,
      delivery_fees: 32,
      tax_rate: 0.2,
      taxes: 178.4,
      total: 1070.4,
      status: 'delivered',
      returned: true,
    },
  ],
};

export default baseData;
