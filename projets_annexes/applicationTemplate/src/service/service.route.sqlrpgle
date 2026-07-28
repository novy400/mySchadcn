**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
       datfmt(*iso)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');

/include 'ileastic/ileastic.rpgle'
/include 'service.rpgleinc'
/include 'servrest.rpgleinc'
/include 'servroute.rpgleinc'
/include 'ckool.rpgleinc'
// Main route setup procedure
dcl-proc service_setupRoutes export;
  dcl-pi *N;
    config likeds(il_config);
  end-pi;
  
  // Add middleware for logging all service requests
  // il_addMiddleware(config : %paddr('service_logMiddleware') : '^/api/services/.*$');
  
  // Routes CRUD compatible with React Admin simple rest data provider
  il_addRoute(config : %paddr('service_getlist_rest') 
    : IL_GET : '^/api/services/?$');
  il_addRoute(config : %paddr('service_getone_rest') 
    : IL_GET : '^/api/services/{id}$');
  il_addRoute(config : %paddr('service_create_rest') 
    : IL_POST : '^/api/services/?$');
  il_addRoute(config : %paddr('service_update_rest') 
    : IL_PUT : '^/api/services/{id}$');
  il_addRoute(config : %paddr('service_delete_rest') 
    : IL_DELETE : '^/api/services/{id}$');
  
  // // CORS preflight handling
  // il_addRoute(config : %paddr('service_options') : IL_OPTIONS : '^/api/services/.*$');
  
  // // Utility routes
  // il_addRoute(config : %paddr('service_health') : IL_GET : '^/api/services/health$');
  // il_addRoute(config : %paddr('service_apiDocs') : IL_GET : '^/api/services/docs$');
  
end-proc;

// Register complete service API with all endpoints
dcl-proc service_registerAPI export;
  dcl-pi *N;
    config likeds(il_config);
  end-pi;
  
  // Setup all service routes
  service_setupRoutes(config);
  
  // Log API registration
  CKOOL_logMessage('Service API routes registered successfully');
  
end-proc;

