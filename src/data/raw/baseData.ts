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
  ],};

export default baseData;
