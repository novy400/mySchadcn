**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');

/include 'ileastic/ileastic.rpgle'
/include 'employee.rpgleinc'
/include 'emprest.rpgleinc'
/include 'emproute.rpgleinc'
/include 'ckool.rpgleinc'
// Main route setup procedure
dcl-proc employee_setupRoutes export;
  dcl-pi *N;
    config likeds(il_config);
  end-pi;
  
  // Add middleware for logging all employee requests
  // il_addMiddleware(config : %paddr('employee_logMiddleware') : '^/api/employees/.*$');
  
  // Routes CRUD compatible with React Admin simple rest data provider
  il_addRoute(config : %paddr('employee_getlist_rest') 
    : IL_GET : '^/api/employees/?$');
  il_addRoute(config : %paddr('employee_getone_rest') 
    : IL_GET : '^/api/employees/{id}$');
  il_addRoute(config : %paddr('employee_create_rest') 
    : IL_POST : '^/api/employees/?$');
  il_addRoute(config : %paddr('employee_update_rest') 
    : IL_PUT : '^/api/employees/{id}$');
  il_addRoute(config : %paddr('employee_delete_rest') 
    : IL_DELETE : '^/api/employees/{id}$');
  
  // // CORS preflight handling
  // il_addRoute(config : %paddr('employee_options') : IL_OPTIONS : '^/api/employees/.*$');
  
  // // Utility routes
  // il_addRoute(config : %paddr('employee_health') : IL_GET : '^/api/employees/health$');
  // il_addRoute(config : %paddr('employee_apiDocs') : IL_GET : '^/api/employees/docs$');
  
end-proc;

// Register complete employee API with all endpoints
dcl-proc employee_registerAPI export;
  dcl-pi *N;
    config likeds(il_config);
  end-pi;
  
  // Setup all employee routes
  employee_setupRoutes(config);
  
  // Log API registration
  CKOOL_logMessage('Employee API routes registered successfully');
  
end-proc;

