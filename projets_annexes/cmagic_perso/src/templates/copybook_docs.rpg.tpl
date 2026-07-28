**free
// ============================================
// {{lowercase name}} headers - générée par cmagic v1.0
// source : {{sourceFile}}  
// date : {{generationDate}}
// ============================================

/if defined({{lowercase name}}_h_defined)       
/eof                               
/endif                             
/define {{lowercase name}}_h_defined  
/// ============================================
// includes standard
/// ============================================
/include 'cmagic.rpgleinc'
/include 'global.rpgleinc'
/include 'sqlstates.rpginc'
/include 'llist/llist_h.rpgle'
/include 'ckool.rpgleinc'

{{#if structs}}
/// ========================================
// structures communes
/// ========================================

{{#each structs}}
// structure {{lowercase this.name}} réutilisable
dcl-ds {{lowercase ../name}}_{{lowercase this.name}}_t qualified template;
{{#each this.fields}}
  {{lowercase this.name}} {{{toRpgType this.type}}};
{{/each}}
end-ds;

{{/each}}
{{/if}}

// structure audit réutilisable
dcl-ds audit_t qualified template;
  createdat timestamp;
  createdby char(10);
  updatedat timestamp;
  updateby char(10);
end-ds;

{{#if enums}}
/// ========================================
// constantes énumération
///========================================

{{#each enums}}
dcl-enum {{lowercase this.name}} qualified;
{{#each this.values}}
  {{lowercase this.name}} '{{lowercase this.name}}';
{{/each}}
end-enum;

{{/each}}
{{/if}}

///========================================
// structures entité
///========================================

///
// structure de base {{lowercase name}} (données métier)
///
dcl-ds {{lowercase name}}_t qualified template;
{{#each fields}}
{{#if (eq this.name 'id')}}
  {{lowercase this.name}} {{{toRpgType this.type}}};
{{/if}}
{{/each}}
{{#each fields}}
{{#unless (eq this.name 'id')}}
  {{lowercase this.name}} {{{toRpgTypeWithEntity this.type ../name}}};
{{/unless}}
{{/each}}
end-ds;

///
// structure pour clé primaire
///
dcl-ds {{lowercase name}}_id_t qualified template;
  id INT(10);
end-ds;

///
// structure détaillée {{lowercase name}} (avec métadonnées techniques)
///
dcl-ds {{lowercase name}}_detail_t qualified template;
  // données métier héritées de {{lowercase name}}_t
  detail likeds({{lowercase name}}_t);
  // métadonnées techniques
  audit likeds(audit_t);
end-ds;

// ========================================
// api publique - procédures exportées
// ========================================

///
// Liste des opératinons supportées
//
dcl-enum {{lowercase name}}_listeAction qualified;
  creation 'create';
  modification 'update';
  suppression 'delete';
  consultation 'read';
end-enum;

{{#if operations}}
// ========================================
// PROCÉDURES EXPORTÉES - API PUBLIQUE  
// ========================================

{{#each operations}}
{{#if (eq this 'CREATE')}}
///
// Création d'un nouveau {{lowercase ../name}}
//
// Returns the id of created {{../name}}
//
// @param **in** detail {{../name}} detail
// @param **out**  id {{../name}} ID
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../name}}_create ind extproc(*dclcase);
  detail likeds({{lowercase ../name}}_detail_t) const;
  id likeDS({{lowercase ../name}}_id_t);
  errors likeDS(GLOBAL_listError);
end-pr;
{{/if}}

{{#if (eq this 'DISPLAY')}}
///
// display  {{lowercase ../name}}
//
// - calls getByID
// - display the detail {{../name}} on screen
//
// @param **in**  id {{../name}} ID
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../name}}_display ind extproc(*dclcase);
  id likeDS({{lowercase ../name}}_id_t) const;
  errors likeDS(GLOBAL_listError);
end-pr;
{{/if}}

{{#if (eq this 'CHANGE')}}
///
// Mise à jour {{lowercase ../name}} existant
//
// Returns *on if ok, *off if error
//
// @param **in**  id {{../name}} ID
// @param **in** detail {{../name}} detail
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../name}}_change ind extproc(*dclcase);
  id likeDS({{lowercase ../name}}_id_t) const;
  detail likeds({{lowercase ../name}}_detail_t) const;
  errors likeDS(GLOBAL_listError);
end-pr;
{{/if}}

{{#if (eq this 'DELETE')}}
///
// Suppression {{lowercase ../name}}
//
// Returns *on if ok, *off if error
//
// @param **in**  id {{../name}} ID
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../name}}_delete ind extproc(*dclcase);
  id likeDS({{lowercase ../name}}_id_t) const;
  errors likeDS(GLOBAL_listError);
end-pr;
{{/if}}

{{#if (eq this 'SEARCH')}}
///
// Recherche {{lowercase ../name}}s (liste)
//
// Returns a paginate list of found {{lowercase ../name}}s
//  regarding the search critéria send in the context.
//
// @param **in**  context (pagination,sort,filter) critérias
// @param **out** itemCount count of item found based on filter critérias
// @param **out** items pointer to the linked list of item {{../name}}
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../name}}_search ind extproc(*dclcase);
   context likeDS(CMAGIC_context) const;
   totalCount like(CMAGIC_totalCount);
   items pointer;
   errors likeDS(GLOBAL_listError);
end-pr;
{{/if}}
{{/each}}

///
// Récupération {{lowercase name}} par ID
//
// Returns a detail {{name}}
//
// @param **in**  id {{name}} ID
// @param **out** detail {{name}} detail
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{name}}
// @tag CMAGIC
///
dcl-pr {{lowercase name}}_getByID ind extproc(*dclcase);
  id likeDS({{lowercase name}}_id_t) const;
  detail likeds({{lowercase name}}_detail_t);
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Validation action {{lowercase name}}.
//
// Returns a list of errors if {{name}} is not valid for the action
//
// @param **in**  action {{name}} action
// @param **in** detail {{name}} detail after action
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{name}}
// @tag CMAGIC
///
dcl-pr {{lowercase name}}_isValid ind extproc(*dclcase);
   action like(GLOBAL_codeAction) Const;
   beforeDetail likeds({{lowercase name}}_detail_t) Const;
   afterDetail likeds({{lowercase name}}_detail_t) Const;
   errors likeDS(GLOBAL_listError);
end-pr;
{{/if}}

// ========================================