import type { LanguageClientOptions, ServerOptions } from 'vscode-languageclient/node';
import type * as vscode from 'vscode';
import * as path from 'node:path';
import { LanguageClient, TransportKind } from 'vscode-languageclient/node';
import { createCmagicServices } from '../language/cmagic-module.js';
import { NodeFileSystem } from 'langium/node';
import { extractAstNode } from '../cli/cli-util.js';
import { generateCode } from '../cli/generator.js';
import type { Model } from '../language/generated/ast.js';
import * as commands from 'vscode';

let client: LanguageClient;

// This function is called when the extension is activated.
export function activate(context: vscode.ExtensionContext): void {
    client = startLanguageClient(context);

    // Register generic generate command
    context.subscriptions.push(commands.commands.registerCommand('cmagic.generate', async (uri?: vscode.Uri) => {
        let fileName: string | undefined;

        if (uri) {
            // Invoked from Explorer or with an argument
            fileName = uri.fsPath;
            // If the file is currently open in an editor, save it if dirty
            const openEditor = commands.window.visibleTextEditors.find(e => e.document.uri.toString() === uri.toString());
            if (openEditor && openEditor.document.isDirty) {
                await openEditor.document.save();
            }
        } else {
            // Invoked from Command Palette or Editor context menu
            const editor = commands.window.activeTextEditor;
            if (editor && editor.document.languageId === 'cmagic') {
                if (editor.document.isDirty) {
                    await editor.document.save();
                }
                fileName = editor.document.uri.fsPath;
            }
        }

        if (fileName) {
            try {
                const services = createCmagicServices(NodeFileSystem).Cmagic;
                const model = await extractAstNode<Model>(fileName, services);
                // Templates are in 'out/templates' relative to the extension root
                const templatesDir = context.asAbsolutePath(path.join('out', 'templates'));
                const generatedFilePath = generateCode(model, fileName, undefined, templatesDir);

                commands.window.showInformationMessage(`CMagic: Code generated successfully in ${generatedFilePath}`);
            } catch (error) {
                commands.window.showErrorMessage(`CMagic: Generation failed: ${error}`);
                console.error(error);
            }
        } else {
            commands.window.showWarningMessage('CMagic: Please open a .cmagic file or right-click one in the explorer to generate code.');
        }
    }));
}

// This function is called when the extension is deactivated.
export function deactivate(): Thenable<void> | undefined {
    if (client) {
        return client.stop();
    }
    return undefined;
}

function startLanguageClient(context: vscode.ExtensionContext): LanguageClient {
    const serverModule = context.asAbsolutePath(path.join('out', 'language', 'main.cjs'));
    // The debug options for the server
    // --inspect=6009: runs the server in Node's Inspector mode so VS Code can attach to the server for debugging.
    // By setting `process.env.DEBUG_BREAK` to a truthy value, the language server will wait until a debugger is attached.
    const debugOptions = { execArgv: ['--nolazy', `--inspect${process.env.DEBUG_BREAK ? '-brk' : ''}=${process.env.DEBUG_SOCKET || '6009'}`] };

    // If the extension is launched in debug mode then the debug server options are used
    // Otherwise the run options are used
    const serverOptions: ServerOptions = {
        run: { module: serverModule, transport: TransportKind.ipc },
        debug: { module: serverModule, transport: TransportKind.ipc, options: debugOptions }
    };

    // Options to control the language client
    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: '*', language: 'cmagic' }]
    };

    // Create the language client and start the client.
    const client = new LanguageClient(
        'cmagic',
        'cmagic',
        serverOptions,
        clientOptions
    );

    // Start the client. This will also launch the server
    client.start();
    return client;
}
