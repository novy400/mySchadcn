**free
// Generated from CatalogServerSpec with catalog-server.main.sqlrpgle.hbs. Do not edit.
ctl-opt thread(*CONCURRENT)
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        datfmt(*iso)
        main(main)
        bnddir('QC2LE':'ILEASTIC');

/include 'ileastic/ileastic.rpgle'
/include 'services.ileastic.rpgleinc'

dcl-proc main;
  dcl-ds config likeDS(IL_config) inz;

  config.port = 44000;
  config.host = '*ANY';

  service_registerRoutes(config);
  il_listen(config);
end-proc;
