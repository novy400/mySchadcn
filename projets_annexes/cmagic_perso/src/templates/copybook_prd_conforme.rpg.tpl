{{!-- src/templates/copybook_prd_conforme.rpg.tpl --}}
**free
// ============================================
// {{lowercase this.name}} headers - générée par cmagic v1.0
// source : {{@root.sourceFile}}  
// date : {{@root.generationDate}}
// ============================================

/if defined({{lowercase this.name}}_h_defined)       
/eof                               
/endif                             
/define {{lowercase this.name}}_h_defined  
/// ============================================
// includes standard
/// ============================================
/include 'cmagic.rpgleinc'
/include 'global.rpgleinc'
/include 'sqlstates.rpginc'
/include 'llist/llist_h.rpgle'
/include 'ckool.rpgleinc'

{{#if @root.structs}}
/// ========================================
// structures communes
/// ========================================

{{#each @root.structs}}
// structure {{lowercase this.name}} réutilisable
dcl-ds {{lowercase ../this.name}}_{{lowercase this.name}}_t qualified template;
{{#each this.fields}}
  {{lowercase this.name}} {{{toRpgType this.type}}}{{{rpgFieldConstraints this}}};
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

{{#if @root.enums}}
/// ========================================
// constantes énumération
///========================================

{{#each @root.enums}}
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
// structure de base {{lowercase this.name}} (données métier)
///
dcl-ds {{lowercase this.name}}_t qualified template;
{{#each this.fields}}
{{#if this.type.struct}}
  {{lowercase this.name}} likeds({{lowercase ../this.name}}_{{lowercase this.type.struct.ref.name}}_t);
{{else}}
  {{lowercase this.name}} {{{toRpgType this.type}}}{{{rpgFieldConstraints this}}};
{{/if}}
{{/each}}
end-ds;

///
// structure pour clé primaire
///
dcl-ds {{lowercase this.name}}_id_t qualified template;
{{#each this.fields}}
{{#if (eq this.name 'id')}}
  {{lowercase this.name}} {{{toRpgType this.type}}};
{{/if}}
{{/each}}
end-ds;

///
// structure détaillée {{lowercase this.name}} (avec métadonnées techniques)
///
dcl-ds {{lowercase this.name}}_detail_t qualified template;
  // données métier héritées de {{lowercase this.name}}_t
  detail likeds({{lowercase this.name}}_t);
  // métadonnées techniques
  audit likeds(audit_t);
end-ds;

{{#if @root.views}}
{{#each @root.views}}
{{#if (eq this.entity.ref.name ../this.name)}}
///
// {{lowercase this.name}} list item template
///
dcl-ds {{lowercase ../this.name}}_{{lowercase this.name}}_t template qualified;
{{#each this.fields}}
  {{lowercase this.field.ref.name}} like({{lowercase ../../this.name}}_t.{{lowercase this.field.ref.name}});
{{/each}}
end-ds;
{{/if}}
{{/each}}
{{/if}}

// ========================================
// api publique - procédures exportées
// ========================================

///
// Liste des opératinons supportées
//
dcl-enum {{lowercase this.name}}_listeAction qualified;
  creation 'create';
  modification 'update';
  suppression 'delete';
  consultation 'read';
end-enum;

{{#if @root.operations}}
// DEBUG: Found operations in root
{{#each @root.operations}}
// DEBUG: Processing operation for entity {{this.entity.ref.name}}
{{#if (eq this.entity.ref.name ../this.name)}}
// DEBUG: Found matching entity {{../this.name}}
{{#each this.operations}}
// DEBUG: Processing operation {{this}}
{{#if (eq this 'CREATE')}}
///
// Création d'un nouveau {{lowercase ../../this.name}}
//
// Returns the id of created {{../../this.name}}
//
// @param **in** detail {{../../this.name}} detail
// @param **out**  id {{../../this.name}} ID
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../../this.name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../../this.name}}_create ind extproc(*dclcase);
  detail likeds({{lowercase ../../this.name}}_detail_t) const;
  id likeDS({{lowercase ../../this.name}}_id_t);
  errors likeDS(GLOBAL_listError);
end-pr; 
{{/if}}

{{#if (eq this 'DISPLAY')}}
///
// display  {{lowercase ../../this.name}}
//
// - calls getByID
// - display the detail {{../../this.name}} on screen
//
// @param **in**  id {{../../this.name}} ID
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../../this.name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../../this.name}}_display ind extproc(*dclcase);
  id likeDS({{lowercase ../../this.name}}_id_t) const;
  errors likeDS(GLOBAL_listError);
end-pr; 
{{/if}}

{{#if (eq this 'CHANGE')}}
///
// Mise à jour {{lowercase ../../this.name}} existant
//
// Returns *on if ok, *off if error
//
// @param **in**  id {{../../this.name}} ID
// @param **in** detail {{../../this.name}} detail
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../../this.name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../../this.name}}_change ind extproc(*dclcase);
  id likeDS({{lowercase ../../this.name}}_id_t) const;
  detail likeds({{lowercase ../../this.name}}_detail_t) const;
  errors likeDS(GLOBAL_listError);
end-pr; 
{{/if}}

{{#if (eq this 'DELETE')}}
///
// Suppression {{lowercase ../../this.name}}
//
// Returns *on if ok, *off if error
//
// @param **in**  id {{../../this.name}} ID
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../../this.name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../../this.name}}_delete ind extproc(*dclcase);
  id likeDS({{lowercase ../../this.name}}_id_t) const;
  errors likeDS(GLOBAL_listError);
end-pr;
{{/if}}

{{#if (eq this 'SEARCH')}}
///
// Recherche {{lowercase ../../this.name}}s (liste)
//
// Returns a paginate list of found {{lowercase ../../this.name}}s
//  regarding the search critéria send in the context.
//
// @param **in**  context (pagination,sort,filter) critérias
// @param **out** itemCount count of item found based on filter critérias
// @param **out** items pointer to the linked list of item {{../../this.name}}
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../../this.name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../../this.name}}_search ind extproc(*dclcase);
   context likeDS(CMAGIC_context) const;
   totalCount like(CMAGIC_totalCount);
   items pointer;
   errors likeDS(GLOBAL_listError);
end-pr;
{{/if}}
{{/each}}

///
// Récupération {{lowercase ../this.name}} par ID
//
// Returns a detail {{../this.name}}
//
// @param **in**  id {{../this.name}} ID
// @param **out** detail {{../this.name}} detail
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../this.name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../this.name}}_getByID ind extproc(*dclcase);
  id likeDS({{lowercase ../this.name}}_id_t) const;
  detail likeds({{lowercase ../this.name}}_detail_t);
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Validation action {{lowercase ../this.name}}.
//
// Returns a list of errors if {{../this.name}} is not valid for the action
//
// @param **in**  action {{../this.name}} action
// @param **in** detail {{../this.name}} detail after action
// @param **out** errors list of errors
// @return *on if ok, *off if error
// @throws ....
// @tag {{../this.name}}
// @tag CMAGIC
///
dcl-pr {{lowercase ../this.name}}_isValid ind  extproc(*dclcase);
   action like(GLOBAL_codeAction) Const; // in {{lowercase ../this.name}}_listeAction
   beforeDetail likeds({{lowercase ../this.name}}_detail_t) Const;
   afterDetail likeds({{lowercase ../this.name}}_detail_t) Const;
   errors likeDS(GLOBAL_listError);
end-pr;

{{/if}}
{{/each}}
{{/if}}

// ========================================
