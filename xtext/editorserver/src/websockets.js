import { WebSocketServer } from 'ws';
import { config } from "./config.js";
import  fs from "fs";

/**
 * subscribes to updates from build files of Xtext project
 * @param {*} ws - web socket object
 * @param {*} editorID - string unique project identifier @see controllers/XtextController.js
 * @param {*} fileWatchers - dictionary contains references to file watchers @see get_file_watchers()
 */
function subscribe_to_build(ws, editorID, fileWatchers) {
    var response = get_response();

    const filePath = config.deployFileLocation + "/" + editorID;
    const buildPath = config.buildFileLocation + "/" + editorID;
    const buildStatusFile = 'build.res';
    const buildLogFile = 'build.log';

    var buildLog = '';
    var buildStatus = -1;

    // watch the build log file for changes
    fileWatchers.buildPathWatcher = fs.watch(buildPath, (_, fileName) => {

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
        ws.send(JSON.stringify(response));
    });

    // watch the deploy location to detect when the editor is depoyed
    fileWatchers.deployPathWatcher = fs.watch(config.deployFileLocation, (_, fileName) =>{   
        if (fileName == editorID){
            response.editorReady = true;
            response.output = buildLog;
            ws.send(JSON.stringify(response));
            ws.terminate();
        }
    });
}

/**
 * get a default websocket response object
 */
function get_response(){
    return {'editorReady': false, 'output': '', 'error': ''};
}

/**
 * get an empty file watcher dictionary
 */
function get_file_watchers() {
    return {'buildPathWatcher': null, 'deployPathWatcher': null}
}

const wss = new WebSocketServer({ port: 8000 });

wss.on('connection', function connection(ws) {
    const fileWatchers = get_file_watchers();
    ws.isAlive = true;

    ws.on('error', () => {
        fileWatchers.buildPathWatcher?.close();
        fileWatchers.deployPathWatcher?.close();
    });
    ws.on('pong', () => { ws.isAlive = true; });
    ws.on('message', (data) => {
        subscribe_to_build(ws, data, fileWatchers)
    });
    ws.on('close', () => {
        fileWatchers.buildPathWatcher?.close();
        fileWatchers.deployPathWatcher?.close();
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