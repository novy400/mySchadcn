import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createWriteStream } from 'node:fs';
import { mkdtemp, mkdir, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { pipeline } from 'node:stream/promises';
import { createMessageConnection, StreamMessageReader, StreamMessageWriter } from 'vscode-jsonrpc/node';
import yauzl from 'yauzl';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDirectory, '..');
const projectPackage = JSON.parse(await readFile(path.join(projectRoot, 'package.json'), 'utf8'));
const vsixPath = path.resolve(
    projectRoot,
    process.argv[2] ?? `cmagic-${projectPackage.version}.vsix`
);
const fixturePath = path.join(projectRoot, 'examples', 'service-catalogue-iws.cmagic');
const temporaryRoot = await mkdtemp(path.join(tmpdir(), 'cmagic-vsix-'));

try {
    const requiredEntries = [
        'extension/package.json',
        'extension/out/language/main.cjs'
    ];
    await extractArchive(vsixPath, temporaryRoot, requiredEntries);

    const packagedRoot = path.join(temporaryRoot, 'extension');
    const packagedPackage = JSON.parse(await readFile(path.join(packagedRoot, 'package.json'), 'utf8'));
    const diagnostics = await collectDiagnostics({
        serverPath: path.join(packagedRoot, 'out', 'language', 'main.cjs'),
        serverRoot: packagedRoot,
        documentPath: fixturePath
    });

    assert.equal(
        packagedPackage.version,
        projectPackage.version,
        `Le VSIX embarque la version ${packagedPackage.version}, attendue ${projectPackage.version}.`
    );
    assert.equal(
        packagedPackage.dependencies.langium,
        projectPackage.dependencies.langium,
        `Le VSIX embarque langium ${packagedPackage.dependencies.langium}, attendu ${projectPackage.dependencies.langium}.`
    );
    assert.equal(
        packagedPackage.dependencies['vscode-languageclient'],
        projectPackage.dependencies['vscode-languageclient'],
        'La famille vscode-languageclient du VSIX ne correspond pas au projet.'
    );
    assert.equal(
        packagedPackage.dependencies['vscode-languageserver'],
        projectPackage.dependencies['vscode-languageserver'],
        'La famille vscode-languageserver du VSIX ne correspond pas au projet.'
    );
    assert.deepEqual(
        diagnostics,
        [],
        `Le serveur empaquete rejette le modele CMagic valide :\n${formatDiagnostics(diagnostics)}`
    );

    console.log(`VSIX verifie : ${path.basename(vsixPath)} (${projectPackage.dependencies.langium}, 0 diagnostic).`);
} finally {
    await rm(temporaryRoot, { recursive: true, force: true });
}

function extractArchive(archivePath, destination, expectedEntries) {
    const remaining = new Set(expectedEntries);

    return new Promise((resolve, reject) => {
        yauzl.open(archivePath, { lazyEntries: true }, (openError, zipFile) => {
            if (openError) {
                reject(openError);
                return;
            }

            zipFile.on('error', reject);
            zipFile.on('end', () => {
                if (remaining.size > 0) {
                    reject(new Error(`Entrees absentes du VSIX : ${[...remaining].join(', ')}`));
                } else {
                    resolve();
                }
            });
            zipFile.on('entry', entry => {
                const normalizedName = path.posix.normalize(entry.fileName);
                if (normalizedName.startsWith('../') || path.posix.isAbsolute(normalizedName)) {
                    reject(new Error(`Chemin interdit dans le VSIX : ${entry.fileName}`));
                    return;
                }
                if (entry.fileName.endsWith('/')) {
                    zipFile.readEntry();
                    return;
                }

                const outputPath = path.join(destination, ...normalizedName.split('/'));
                mkdir(path.dirname(outputPath), { recursive: true })
                    .then(() => new Promise((resolveEntry, rejectEntry) => {
                        zipFile.openReadStream(entry, (streamError, input) => {
                            if (streamError) {
                                rejectEntry(streamError);
                                return;
                            }
                            pipeline(input, createWriteStream(outputPath)).then(resolveEntry, rejectEntry);
                        });
                    }))
                    .then(() => {
                        remaining.delete(normalizedName);
                        zipFile.readEntry();
                    }, reject);
            });
            zipFile.readEntry();
        });
    });
}

async function collectDiagnostics({ serverPath, serverRoot, documentPath }) {
    const child = spawn(process.execPath, [serverPath, '--stdio'], {
        cwd: serverRoot,
        stdio: ['pipe', 'pipe', 'pipe']
    });
    const connection = createJsonRpcConnection(child);
    const documentUri = pathToFileURL(documentPath).href;

    try {
        await connection.request('initialize', {
            processId: process.pid,
            rootUri: pathToFileURL(serverRoot).href,
            capabilities: {},
            workspaceFolders: null
        });
        await connection.notify('initialized', {});

        const diagnosticsPromise = connection.waitForNotification(
            'textDocument/publishDiagnostics',
            parameters => normalizeUri(parameters.uri) === normalizeUri(documentUri)
        );
        await connection.notify('textDocument/didOpen', {
            textDocument: {
                uri: documentUri,
                languageId: 'cmagic',
                version: 1,
                text: await readFile(documentPath, 'utf8')
            }
        });

        const notification = await diagnosticsPromise;
        await connection.request('shutdown');
        await connection.notify('exit');
        await connection.waitForExit();
        return notification.diagnostics;
    } finally {
        connection.close();
    }
}

function createJsonRpcConnection(child) {
    const connection = createMessageConnection(
        new StreamMessageReader(child.stdout),
        new StreamMessageWriter(child.stdin)
    );
    let stderr = '';

    child.stderr.on('data', chunk => {
        stderr += chunk.toString();
    });
    connection.listen();

    return {
        request(method, params) {
            return connection.sendRequest(method, params);
        },
        notify(method, params) {
            return connection.sendNotification(method, params);
        },
        waitForNotification(method, predicate) {
            return new Promise((resolve, reject) => {
                const timeout = setTimeout(() => {
                    reject(new Error(`Timeout LSP pour ${method}.${stderr ? ` stderr: ${stderr}` : ''}`));
                }, 10_000);
                const disposable = connection.onNotification(method, parameters => {
                    if (predicate(parameters)) {
                        clearTimeout(timeout);
                        disposable.dispose();
                        resolve(parameters);
                    }
                });
            });
        },
        waitForExit() {
            if (child.exitCode !== null) {
                return Promise.resolve();
            }
            return new Promise(resolve => child.once('exit', resolve));
        },
        close() {
            connection.dispose();
            if (child.exitCode === null) {
                child.kill();
            }
        }
    };
}

function formatDiagnostics(diagnostics) {
    return diagnostics
        .map(diagnostic => `ligne ${diagnostic.range.start.line + 1}: ${diagnostic.message}`)
        .join('\n');
}

function normalizeUri(uri) {
    return decodeURIComponent(uri).toLowerCase();
}
