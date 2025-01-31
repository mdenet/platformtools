import { WebSocketServer } from 'ws';
import { config } from "./config.js";
import  fs from "fs";

function checkEditor(data){

            const editorId = data;
            const filePath = config.deployFileLocation + "/" + editorId;
            const buildLogPath= `${config.buildFileLocation}/${editorId}/build.log`;
            const buildStatusPath= `${config.buildFileLocation}/${editorId}/build.res`;
            const editorDeployed = fs.existsSync(filePath);
            
            let buildLog;
            let buildStatus;

            // Read the build log
            try {
                if (fs.existsSync(buildLogPath)) {
                    buildLog = fs.readFileSync(buildLogPath, 'utf8');
                } else {
                    buildLog = "";
                }
            } catch (err) {
                console.log("Error reading build log: " + buildLogPath);
                console.log(err);
            }

            // Read the build status
            try {
                if (fs.existsSync(buildStatusPath)) {
                    buildStatus = Number( fs.readFileSync(buildStatusPath, 'utf8') );
                } else {
                    buildStatus = 0;
                }
            } catch (err) {
                console.log("Error reading build status: " + buildStatusPath);
                console.log(err);
            }

            let response = {};
            response.editorReady = editorDeployed;
            response.output = buildLog;

            if ( buildStatus > 0 ){
                // Build failed
                response.error = "Please refer to the build log.";
            }
	 return response;

}


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
        ws.send(JSON.stringify(response));
    });

    // watch the deploy location to detect when the editor is depoyed
    fs.watch(config.deployFileLocation, (...args) =>{   
        const filename = args[1];
        if (filename == editorID){
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
 * handles pong messages
 */
function heartbeat() {
  this.isAlive = true;
}

const wss = new WebSocketServer({ port: 8000 });

wss.on('connection', function connection(ws) {
    ws.isAlive = true;
    ws.on('error', console.error);
    ws.on('pong', heartbeat);
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