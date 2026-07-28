**FREE

ctl-opt thread(*CONCURRENT)
        option(*nodebugio:*srcstmt:*nounref)
        pgminfo(*PCML:*MODULE)
        datfmt(*iso)
        alwnull(*usrctl)
        main(main)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');

/include 'ileastic/ileastic.rpgle'
/include 'emproute.rpgleinc'
/include 'emprest.rpgleinc'
/include 'servroute.rpgleinc'
/include 'servrest.rpgleinc'
/include 'ckool.rpgleinc'

// Include du plugin CORS officiel ILEastic
/include 'ileastic/cors_h.rpginc'

dcl-proc main;
  dcl-ds config likeds(il_config);
 CKOOL_logMessage('Employee API Server Starting...');
  config.port = 44000;
  config.host = '*ANY';
 CKOOL_logMessage('Server configured on port ' + %char(config.port));
  
  // Configuration CORS avec plugin officiel ILEastic
  il_addPlugin(config : %paddr('il_addCorsHeaders') : IL_PREREQUEST);
  
  // Configuration CORS pour APIs REST (permettre tout pour développement)
  il_cors_addCorsConfigurationValues('.*' : '*' : '*' : '*' : *ON);
  
  // Setup complete employee API routes
  employee_registerAPI(config);
  service_registerAPI(config);
  
 CKOOL_logMessage('Starting server...');
  il_listen(config);
 CKOOL_logMessage('Server stopped');
end-proc;

dcl-proc loadConfig;
  dcl-pi *n likeds(il_config) end-pi;

  dcl-ds config likeds(il_config) inz;

  config.port = 44000;
  config.host = '*ANY';

  return config;
end-proc;
