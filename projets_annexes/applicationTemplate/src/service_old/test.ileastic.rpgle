**FREE

ctl-opt thread(*CONCURRENT)
        option(*nodebugio:*srcstmt:*nounref)
        pgminfo(*PCML:*MODULE)
        alwnull(*usrctl)
        main(main)
        debug(*yes)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');

/include 'ileastic/ileastic.rpgle'
/include 'emproute.rpgleinc'
/include 'ckool.rpgleinc'

dcl-proc main;
  dcl-ds config likeds(il_config);
 CKOOL_logMessage('yop yopcool Debut');

//config = loadConfig();
  // Setup employee routes
  config.port = 44000;
  config.host = '*ANY';
   il_addRoute(config : %paddr('employee_getlist_rest') 
    : IL_GET : '^/api/employees/?$');
  il_addRoute(config : %paddr('employee_getone_rest') 
    : IL_GET : '^/api/employees/([0-9A-Za-z]+)$');
  il_listen (config);
 
  CKOOL_logMessage('yop yop ');
end-proc;

dcl-proc loadConfig;
  dcl-pi *n likeds(il_config) end-pi;

  dcl-ds config likeds(il_config) inz;
  clear config;

  return config;
end-proc;

// -----------------------------------------------------------------------------
// Servlet callback implementation
// -----------------------------------------------------------------------------     
dcl-proc myservlet;

    dcl-pi *n;
        request  likeds(IL_REQUEST);
        response likeds(IL_RESPONSE);
    end-pi;


    // Write the response. The default HTTP status code is 200 - OK so we
    // don't have to set it explicitly.
    il_responseWrite(response: 'Hello world. Time is ' + %char(%timestamp));
    
end-proc;
