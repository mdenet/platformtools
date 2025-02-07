import { WebSocketServer } from 'ws';
import { config } from "./config.js";
import  fs from "fs";

/**
 * subscribes to updates from build files of Xtext project
 * @param {*} editorID - string unique project identifier @see controllers/XtextController.js
 * @param {*} buildPathWatcher - file watch for build path
 * @param {*} deployPathWatcher -  file watch for deploy path
 */
function subscribe_to_build(editorID, buildPathWatcher, deployPathWatcher) {
    var response = get_response();

    const filePath = config.deployFileLocation + "/" + editorID;
    const buildPath = config.buildFileLocation + "/" + editorID;
    const buildStatusFile = 'build.res';
    const buildLogFile = 'build.log';

    var buildLog = '';
    var buildStatus = -1;

    // watch the build log file for changes
    buildPathWatcher = fs.watch(buildPath, (_, fileName) => {

        if (fileName == buildLogFile){
            buildLog = fs.readFileSync(buildPath + '/' + buildLogFile, 'utf8');
        }

        if (fs.existsSync(buildPath + '/' + buildStatusFile)) {
            buildStatus = Number(fs.readFileSync(buildPath + '/' + buildStatusFile, 'utf8'));
            if (buildStatus > 0) {
                response.error = "Please refer to the build log.";
            }
        }

        response.editorReady = fs.existsSync(filePath);
        response.output = buildLog;
        this.send(JSON.stringify(response));
    });

    // watch the deploy location to detect when the editor is depoyed
    deployPathWatcher = fs.watch(config.deployFileLocation, (_, fileName) =>{   
        if (fileName == editorID){
            response.editorReady = true;
            response.output = buildLog;
            this.send(JSON.stringify(response));
            this.terminate();
        }
    });
}

/**
 * get a default websocket response object
 */
function get_response(){
    return {'editorReady': false, 'output': '', 'error': ''};
}

const wss = new WebSocketServer({ port: 8000 });

wss.on('connection', function connection(ws) {
    var buildPathWatcher = deployPathWatcher = null;
    ws.isAlive = true;
    ws.on('error', () => {
        buildPathWatcher?.close();
        deployPathWatcher?.close();
    });
    ws.on('pong', () => { ws.isAlive = true; });
    ws.on('message', function(data) {
        subscribe_to_build(data, buildPathWatcher, deployPathWatcher);
    });
    ws.on('close', () => {
        buildPathWatcher?.close();
        deployPathWatcher?.close();
    });
});

// Ping and look for broken connections, every 3 seconds 
const interval = setInterval(function ping() {
    wss.clients.forEach(function each(ws) {
    if (ws.isAlive === false) {
        return ws.terminate();
    }
    ws.isAlive = false;
    ws.ping();
    });
}, 3000);

wss.on('close', function close() {
    clearInterval(interval);
});