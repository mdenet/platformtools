import { WebSocketServer } from 'ws';
import { config } from "./config.js";
import  fs from "fs";

/**
 * subscribes to updates from build files of Xtext project
 * @param {*} editorID - string unique project identifier @see controllers/XtextController.js
 */
function subscribe_to_build(editorID) {
    var response = get_response();

    const filePath = config.deployFileLocation + "/" + editorID;
    const buildPath = config.buildFileLocation + "/" + editorID;
    const buildStatusPath= `${config.buildFileLocation}/${editorID}/build.res`;
    
    var buildLog = '';
    var buildStatus = -1;

    // watch the build log file for changes
    fs.watch(buildPath, () => {
        const buildLogPath = buildPath + "/" + "build.log";

        if (fs.existsSync(buildLogPath)) {
            buildLog = fs.readFileSync(buildLogPath, 'utf8');
        }

        if (fs.existsSync(buildStatusPath)) {
            buildStatus = Number( fs.readFileSync(buildStatusPath, 'utf8') );
            if (buildStatus > 0) {
                response.error = "Please refer to the build log.";
            }
        }

        response.editorReady = fs.existsSync(filePath);
        response.output = buildLog;
        this.send(JSON.stringify(response));
    });

    // watch the deploy location to detect when the editor is depoyed
    fs.watch(config.deployFileLocation, (_, fileName) =>{   
        const filename = args[1];
        if (filename == editorID){
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

/**
 * handles pong messages
 */
function heartbeat() {
  this.isAlive = true;
}

const wss = new WebSocketServer({ port: 8000 });

wss.on('connection', function connection(ws) {
    ws.isAlive = true;
    ws.on('error', console.error);
    ws.on('pong', () => { ws.isAlive = true; });
    ws.on('message', subscribe_to_build);
});

// Ping and look for broken connections, every 3 seconds 
const interval = setInterval(function ping() {
  wss.clients.forEach(function each(ws) {
    if (ws.isAlive === false) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 3000);

wss.on('close', function close() {
  clearInterval(interval);
});