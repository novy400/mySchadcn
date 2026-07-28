# ⚙️ Guide Configuration Outils de Développement

*Configuration complète de l'environnement de développement ArchiAPI*  
*Version 1.0 - 31 octobre 2025*

---

## 🎯 Vue d'Ensemble

Ce guide détaille la configuration complète de tous les outils nécessaires au développement d'APIs REST modernes sur IBM i avec ArchiAPI.

### **🎨 Stack Technologique**
```
Développement:  VS Code + Extensions IBM i
Plateforme:     IBM i 7.3+ (RPG ILE, ILEastic)
Build:          BOB + Make
Tests:          Bruno + PowerShell Scripts
Git:            GitHub + PowerShell Git Flow
Monitoring:     Logs + Métriques custom
```

---

## 💻 Configuration Poste Développeur

### **🖥️ Prérequis Système**

#### **Windows 10/11**
```powershell
# Vérifier version PowerShell
$PSVersionTable.PSVersion  # Requis: 5.1+

# Installer PowerShell 7 (recommandé)
winget install Microsoft.PowerShell

# Installer Git
winget install Git.Git

# Installer Node.js (pour outils)
winget install OpenJS.NodeJS
```

#### **Extensions Windows**
```powershell
# Windows Subsystem for Linux (optionnel)
wsl --install

# Windows Terminal (recommandé)
winget install Microsoft.WindowsTerminal
```

### **🎨 Visual Studio Code**

#### **Installation Base**
```powershell
# Installer VS Code
winget install Microsoft.VisualStudioCode

# Ou via Chocolatey
choco install vscode
```

#### **Extensions Essentielles**
```json
// .vscode/extensions.json
{
  "recommendations": [
    // IBM i Development
    "halcyontechltd.code-for-ibmi",
    "halcyontechltd.vscode-rpgle", 
    "halcyontechltd.vscode-db2i",
    
    // Git & Workflow
    "eamodio.gitlens",
    "github.vscode-pull-request-github",
    "ms-vscode.powershell",
    
    // API Development
    "humao.rest-client",
    "ms-vscode.vscode-json",
    
    // Documentation
    "yzhang.markdown-all-in-one",
    "bierner.markdown-preview-enhanced",
    
    // Quality
    "streetsidesoftware.code-spell-checker",
    "editorconfig.editorconfig"
  ]
}
```

#### **Configuration Workspace**
```json
// .vscode/settings.json
{
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  
  // IBM i specific
  "code-for-ibmi.showDescInLibList": true,
  "code-for-ibmi.logCompileOutput": true,
  "code-for-ibmi.autoClearTempData": true,
  
  // RPG settings
  "rpgle.indent": {
    "oneBasedColumnNumbers": false,
    "indentSize": 2
  },
  
  // Git settings
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.enableSmartCommit": true,
  
  // Files associations
  "files.associations": {
    "*.rpgle": "rpgle",
    "*.sqlrpgle": "rpgle", 
    "*.rpgleinc": "rpgle",
    "*.bnd": "rpgle"
  }
}
```

---

## 🖥️ Configuration IBM i

### **🔗 Connexion & Accès**

#### **SSH Configuration**
```bash
# Sur poste développeur - Générer clé SSH
ssh-keygen -t rsa -b 4096 -C "developer@company.com" -f ~/.ssh/ibmi_dev

# Configuration SSH
# ~/.ssh/config
Host ibmi-dev
    HostName your-ibmi-server.com
    User DEVELOPER
    IdentityFile ~/.ssh/ibmi_dev
    Port 22
    ServerAliveInterval 60
```

#### **PASE Environment Setup**
```bash
# Sur IBM i
# 1. Installer packages essentiels
/QOpenSys/pkgs/bin/yum install git nodejs npm python3 make gcc

# 2. Configuration PATH
echo 'export PATH=/QOpenSys/pkgs/bin:$PATH' >> ~/.profile

# 3. Configuration Git
git config --global user.name "Developer Name"
git config --global user.email "developer@company.com"

# 4. Créer répertoires projet
mkdir -p /home/DEVELOPER/projects/archiapi
```

### **🏗️ Environment Setup**

#### **Libraries & Objects**
```cl
/* Créer libraries développement */
CRTLIB LIB(ARCHIDEV) TEXT('ArchiAPI Development')
CRTLIB LIB(ARCHITEST) TEXT('ArchiAPI Testing')
CRTLIB LIB(ARCHIPROD) TEXT('ArchiAPI Production')

/* Configuration LIBL */
CHGLIBL LIBL(ARCHIDEV ILEASTIC QGPL QTEMP) CURLIB(ARCHIDEV)

/* Autoriser IFS development */
CHGAUT OBJ('/home/DEVELOPER') USER(DEVELOPER) DTAAUT(*RWX) OBJAUT(*ALL)
```

#### **HTTP Server Configuration**
```apache
# /www/archiapi/conf/httpd.conf
Listen *:44000

LoadModule proxy_module /QSYS.LIB/QHTTPSVR.LIB/QZSRCORE.SRVPGM
LoadModule proxy_http_module /QSYS.LIB/QHTTPSVR.LIB/QZSRCORE.SRVPGM

<VirtualHost *:44000>
    DocumentRoot /www/archiapi/htdocs
    
    # Proxy vers applications ILEastic
    ProxyPass /api/ http://localhost:44001/api/
    ProxyPassReverse /api/ http://localhost:44001/api/
    
    # CORS Headers
    Header always set Access-Control-Allow-Origin "*"
    Header always set Access-Control-Allow-Methods "GET,POST,PUT,DELETE,OPTIONS"
    Header always set Access-Control-Allow-Headers "Content-Type,Authorization"
</VirtualHost>
```

---

## 🔧 Configuration Outils Build

### **📦 BOB Build System**

#### **Installation**
```bash
# Sur poste développeur
npm install -g @bobjs/bob-cli

# Vérifier installation
bob --version
```

#### **Configuration Projet**
```json
// bob.json
{
  "version": "1.0.0",
  "description": "ArchiAPI REST Services",
  "build": {
    "objlib": "ARCHIDEV",
    "targets": [
      {
        "name": "employee-api",
        "type": "program", 
        "source": "src/employee/employee.main.rpgle",
        "output": "EMPLOYEE",
        "dependencies": ["ILEASTIC", "CMAGIC"]
      },
      {
        "name": "customer-api",
        "type": "program",
        "source": "src/customer/customer.main.rpgle", 
        "output": "CUSTOMER",
        "dependencies": ["ILEASTIC", "CMAGIC"]
      }
    ]
  },
  "deploy": {
    "host": "ibmi-dev",
    "user": "DEVELOPER",
    "remotePath": "/home/DEVELOPER/projects/archiapi"
  }
}
```

#### **Scripts BOB Personnalisés**
```json
// package.json
{
  "scripts": {
    "build": "bob --build",
    "build:employee": "bob --build employee-api",
    "deploy:dev": "bob --deploy --env=dev",
    "test": "bob --build && npm run test:api",
    "test:api": "powershell -File scripts/Test-All-APIs.ps1"
  }
}
```

### **🔧 Makefile Configuration**

#### **Makefile Principal**
```makefile
# Makefile
.PHONY: all clean build test deploy

# Variables
OBJLIB = ARCHIDEV
SRCLIB = QRPGLESRC
INCLIB = QRPGLEINC

# Cibles principales
all: build test

build: employee customer cmagic

clean:
	-DLTOBJ OBJ($(OBJLIB)/*ALL) OBJTYPE(*PGM)
	-DLTOBJ OBJ($(OBJLIB)/*ALL) OBJTYPE(*MODULE)

# Resources
employee:
	CRTRPGMOD MODULE($(OBJLIB)/EMPLOYEE) SRCFILE($(OBJLIB)/$(SRCLIB))
	CRTPGM PGM($(OBJLIB)/EMPLOYEE) MODULE($(OBJLIB)/EMPLOYEE)

customer:
	CRTRPGMOD MODULE($(OBJLIB)/CUSTOMER) SRCFILE($(OBJLIB)/$(SRCLIB))
	CRTPGM PGM($(OBJLIB)/CUSTOMER) MODULE($(OBJLIB)/CUSTOMER)

# Tests
test:
	./scripts/Test-All-APIs.ps1

# Deployment  
deploy:
	bob --deploy --target=dev
```

---

## 🧪 Configuration Tests

### **🔍 Bruno API Testing**

#### **Installation**
```bash
# Installer Bruno CLI
npm install -g @usebruno/cli

# Initialiser collection
bruno init tests/bruno/archiapi
```

#### **Configuration Bruno**
```json
// tests/bruno/bruno.json
{
  "version": "1.0.0",
  "name": "ArchiAPI Tests",
  "type": "collection",
  "environments": {
    "dev": {
      "baseUrl": "http://your-ibmi:44000",
      "apiPath": "/api"
    },
    "test": {
      "baseUrl": "http://your-ibmi-test:44000", 
      "apiPath": "/api"
    }
  },
  "scripts": {
    "prerequest": "// Script avant chaque requête",
    "postrequest": "// Script après chaque requête"
  }
}
```

#### **Test Templates**
```javascript
// tests/bruno/employees/get-collection.bru
meta {
  name: Get Employees Collection
  type: http
  seq: 1
}

get {
  url: {{baseUrl}}{{apiPath}}/employees
  body: none
  auth: none
}

params:query {
  _page: 1
  _limit: 10
}

headers {
  Accept: application/json
}

tests {
  test("Status should be 200", function() {
    expect(res.getStatus()).to.equal(200);
  });
  
  test("Should return array", function() {
    expect(res.getBody()).to.be.an('array');
  });
  
  test("Should have X-Total-Count header", function() {
    expect(res.getHeader('X-Total-Count')).to.exist;
  });
}
```

### **🔧 PowerShell Test Framework**

#### **Test Runner Principal**
```powershell
# scripts/Test-All-APIs.ps1
param(
    [string]$Environment = "dev",
    [string]$BaseUrl = "http://your-ibmi:44000"
)

$ErrorActionPreference = "Stop"

# Configuration
$ApiBase = "$BaseUrl/api"
$Resources = @("employees", "customers", "departments")

Write-Host "🧪 Testing ArchiAPI - Environment: $Environment" -ForegroundColor Green

foreach ($resource in $Resources) {
    Write-Host "Testing $resource..." -ForegroundColor Yellow
    
    # Test collection
    $response = Invoke-RestMethod -Uri "$ApiBase/$resource" -Method GET
    if ($response -is [array]) {
        Write-Host "  ✅ Collection returns array" -ForegroundColor Green
    } else {
        Write-Error "  ❌ Collection should return array"
    }
    
    # Test headers
    $headers = Invoke-WebRequest -Uri "$ApiBase/$resource" -Method GET
    if ($headers.Headers.'X-Total-Count') {
        Write-Host "  ✅ X-Total-Count header present" -ForegroundColor Green
    } else {
        Write-Error "  ❌ X-Total-Count header missing"
    }
    
    # Test pagination
    $paginated = Invoke-RestMethod -Uri "$ApiBase/$resource?_page=1&_limit=5" -Method GET
    if ($paginated.Count -le 5) {
        Write-Host "  ✅ Pagination working" -ForegroundColor Green
    } else {
        Write-Warning "  ⚠️ Pagination may not be working properly"
    }
}

Write-Host "🎯 All tests completed!" -ForegroundColor Green
```

---

## 🔍 Configuration Debug & Monitoring

### **📊 Logging Configuration**

#### **Log4j Style Logging**
```rpg
// includes/logging.rpgleinc
dcl-pr LOG_DEBUG export;
  module varchar(50) const;
  message varchar(500) const;
end-pr;

dcl-pr LOG_INFO export;
  module varchar(50) const; 
  message varchar(500) const;
end-pr;

dcl-pr LOG_ERROR export;
  module varchar(50) const;
  message varchar(500) const;
end-pr;

// Configuration logging
dcl-s LOG_LEVEL varchar(10) inz('INFO');
dcl-s LOG_FILE varchar(100) inz('/tmp/logs/archiapi.log');
```

#### **Implementation Logging**
```rpg
// src/logging/logging.rpgle
dcl-proc LOG_writeEntry export;
  dcl-pi *n;
    level varchar(10) const;
    module varchar(50) const;
    message varchar(500) const;
  end-pi;
  
  dcl-s timestamp char(26);
  dcl-s logEntry varchar(1000);
  dcl-s fd int(10);
  
  timestamp = %char(%timestamp());
  logEntry = %trimr(timestamp) + ' [' + %trimr(level) + '] ' + 
             %trimr(module) + ': ' + %trimr(message) + x'0A';
  
  fd = open(%trimr(LOG_FILE) : O_WRONLY + O_CREAT + O_APPEND : 
    S_IRUSR + S_IWUSR + S_IRGRP);
    
  if fd >= 0;
    write(fd : %addr(logEntry) : %len(%trimr(logEntry)));
    close(fd);
  endif;
  
end-proc;
```

### **📈 Performance Monitoring**

#### **Métriques Collection**
```rpg
// Monitoring performance API
dcl-proc METRICS_recordApiCall export;
  dcl-pi *n;
    endpoint varchar(100) const;
    method varchar(10) const;  
    responseTime int(10) const;
    statusCode int(10) const;
  end-pi;
  
  dcl-s metricsEntry varchar(500);
  
  metricsEntry = %char(%timestamp()) + '|' +
                 %trimr(endpoint) + '|' +
                 %trimr(method) + '|' +
                 %char(responseTime) + '|' +
                 %char(statusCode);
  
  // Écrire vers fichier métriques
  writeToMetricsFile(metricsEntry);
  
  // Alerting si performance dégradée
  if responseTime > 1000; // > 1 seconde
    LOG_WARN('PERFORMANCE' : 'Slow API call: ' + endpoint + 
      ' took ' + %char(responseTime) + 'ms');
  endif;
  
end-proc;
```

---

## 🔄 Configuration Git Workflow

### **⚙️ Git Configuration**

#### **Global Configuration**
```bash
# Configuration Git globale
git config --global user.name "Developer Name"
git config --global user.email "developer@company.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.autocrlf true  # Windows
```

#### **Projet Configuration**
```bash
# Configuration projet
git config core.ignorecase false
git config core.filemode false
git config branch.autosetupmerge always
git config branch.autosetuprebase always
```

#### **Git Hooks Configuration**
```bash
#!/bin/sh
# .git/hooks/pre-commit
echo "🔍 Running pre-commit checks..."

# Vérifier syntaxe PowerShell
powershell -Command "
Get-ChildItem -Path scripts -Filter '*.ps1' | ForEach-Object {
  try {
    \$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content \$_.FullName -Raw), [ref]\$null)
    Write-Host '✅ Syntax OK: ' \$_.Name
  } catch {
    Write-Error '❌ Syntax Error in ' \$_.Name ': ' \$_.Exception.Message
    exit 1
  }
}
"

echo "✅ Pre-commit checks passed"
```

### **🌿 Branch Strategy**

#### **GitFlow Configuration**
```powershell
# Configuration GitFlow avec PowerShell
function Initialize-GitFlow {
    git config gitflow.branch.master main
    git config gitflow.branch.develop employee_rest
    git config gitflow.prefix.feature feature/
    git config gitflow.prefix.release release/
    git config gitflow.prefix.hotfix hotfix/
}

function New-FeatureBranch {
    param([string]$Name)
    git checkout employee_rest
    git pull origin employee_rest
    git checkout -b "feature/$Name"
}

function Complete-FeatureBranch {
    param([string]$Name)
    git checkout employee_rest
    git merge --no-ff "feature/$Name"
    git branch -d "feature/$Name"
    git push origin employee_rest
}
```

---

## 🚀 Configuration CI/CD

### **⚙️ GitHub Actions**

#### **Workflow Build & Test**
```yaml
# .github/workflows/build-test.yml
name: Build and Test
on:
  push:
    branches: [ employee_rest, main ]
  pull_request:
    branches: [ employee_rest, main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Install BOB
      run: npm install -g @bobjs/bob-cli
      
    - name: Configure IBM i Connection
      env:
        IBMI_HOST: ${{ secrets.IBMI_HOST }}
        IBMI_USER: ${{ secrets.IBMI_USER }}
        IBMI_PRIVATE_KEY: ${{ secrets.IBMI_PRIVATE_KEY }}
      run: |
        mkdir -p ~/.ssh
        echo "$IBMI_PRIVATE_KEY" > ~/.ssh/ibmi_key
        chmod 600 ~/.ssh/ibmi_key
        
    - name: Build with BOB
      run: bob --build --remote
      
    - name: Run API Tests
      run: |
        npm install -g @usebruno/cli
        bruno run tests/bruno --env dev
```

#### **Workflow Release**
```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags: [ 'v*' ]

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Production
      run: bob --build --env=prod
      
    - name: Deploy to Production
      run: bob --deploy --env=prod
      
    - name: Create GitHub Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false
```

---

## 📚 Configuration Documentation

### **📖 Documentation Generator**

#### **Script Génération Docs**
```powershell
# scripts/Generate-Documentation.ps1
param(
    [string]$OutputPath = "docs/api"
)

Write-Host "📚 Generating API documentation..." -ForegroundColor Green

# Créer structure docs
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

# Générer OpenAPI spec
$spec = @{
    openapi = "3.0.0"
    info = @{
        title = "ArchiAPI"
        version = "1.0.0"
        description = "Modern REST APIs for IBM i"
    }
    servers = @(
        @{ url = "http://your-ibmi:44000/api"; description = "Development" }
    )
    paths = @{}
}

# Scanner resources et générer endpoints
$resources = Get-ChildItem "src" -Directory | Where-Object { $_.Name -notmatch "^(main|qclsrc|qcmdsrc)$" }

foreach ($resource in $resources) {
    $resourceName = $resource.Name
    
    # Collection endpoints
    $spec.paths["/api/$resourceName"] = @{
        get = @{
            summary = "Get $resourceName collection"
            parameters = @(
                @{ name = "_page"; in = "query"; schema = @{ type = "integer" } }
                @{ name = "_limit"; in = "query"; schema = @{ type = "integer" } }
            )
            responses = @{
                "200" = @{
                    description = "Success"
                    headers = @{
                        "X-Total-Count" = @{ schema = @{ type = "integer" } }
                    }
                }
            }
        }
    }
}

# Sauvegarder spec
$spec | ConvertTo-Json -Depth 10 | Set-Content "$OutputPath/openapi.json"

Write-Host "✅ Documentation generated in $OutputPath" -ForegroundColor Green
```

---

## 🎯 Configuration Production

### **🔒 Security Hardening**

#### **IBM i Security**
```cl
/* Sécurité système */
CHGSYSVAL SYSVAL(QPWDLVL) VALUE('3')
CHGSYSVAL SYSVAL(QPWDMINLEN) VALUE('8')
CHGSYSVAL SYSVAL(QPWDMAXLEN) VALUE('128')

/* Audit */
CHGSYSVAL SYSVAL(QAUDCTL) VALUE('*AUDLVL')
CHGSYSVAL SYSVAL(QAUDLVL) VALUE('*CREATE *DELETE *PGMADP')

/* Autorisation IFS */
CHGAUT OBJ('/www/archiapi') USER(*PUBLIC) DTAAUT(*EXCLUDE)
CHGAUT OBJ('/www/archiapi') USER(QTMHHTTP) DTAAUT(*RX)
```

#### **Application Security**
```rpg
// Headers sécurité
dcl-proc setSecurityHeaders export;
  dcl-pi *n;
    response pointer const;
  end-pi;
  
  il_addHttpHeader(response : 'X-Content-Type-Options' : 'nosniff');
  il_addHttpHeader(response : 'X-Frame-Options' : 'DENY');
  il_addHttpHeader(response : 'X-XSS-Protection' : '1; mode=block');
  il_addHttpHeader(response : 'Strict-Transport-Security' : 
    'max-age=31536000; includeSubDomains');
  il_addHttpHeader(response : 'Content-Security-Policy' : 
    'default-src ''self''; script-src ''self''');
end-proc;
```

### **📊 Production Monitoring**

#### **Health Check Endpoint**
```rpg
// Health check pour monitoring
dcl-proc healthCheckHandler export;
  dcl-pi *n ind;
    request pointer const;
    response pointer const;
  end-pi;
  
  dcl-ds health qualified;
    status varchar(20) inz('healthy');
    timestamp char(26);
    version varchar(20) inz('1.0.0');
    database varchar(20);
    services qualified;
      employee varchar(20);
      customer varchar(20);
    end-ds;
  end-ds;
  
  dcl-s healthJson varchar(1000);
  
  // Vérifier base de données
  monitor;
    exec sql SELECT CURRENT_TIMESTAMP FROM SYSIBM.SYSDUMMY1;
    health.database = 'connected';
  on-error;
    health.database = 'error';
    health.status = 'unhealthy';
  endmon;
  
  // Vérifier services
  health.services.employee = testEmployeeService();
  health.services.customer = testCustomerService();
  
  health.timestamp = %char(%timestamp());
  
  data-gen healthJson %data(health : 'doc=string case=convert');
  
  il_addHttpHeader(response : 'Content-Type' : 'application/json');
  il_responseWrite(response : %addr(healthJson) : %len(%trimr(healthJson)));
  
  return *ON;
end-proc;
```

---

## ✅ Checklist Configuration

### **📋 Validation Environnement**

```markdown
## Poste Développeur
- [ ] VS Code installé avec extensions IBM i
- [ ] PowerShell 7+ configuré
- [ ] Git configuré avec SSH keys
- [ ] Node.js et BOB installés
- [ ] Bruno CLI pour tests API

## IBM i
- [ ] SSH activé et configuré
- [ ] PASE packages installés (git, nodejs, etc.)
- [ ] Libraries créées (DEV, TEST, PROD)
- [ ] ILEastic framework installé
- [ ] HTTP server configuré

## Projet
- [ ] Repository Git initialisé
- [ ] Structure ArchiAPI en place
- [ ] BOB configuration valide
- [ ] Scripts PowerShell fonctionnels
- [ ] Tests Bruno configurés

## Production
- [ ] Sécurité système renforcée
- [ ] Monitoring configuré
- [ ] Backup strategy en place
- [ ] CI/CD pipeline actif
```

---

*Configuration complète - Équipe ArchiAPI*  
*Dernière révision : 31 octobre 2025*