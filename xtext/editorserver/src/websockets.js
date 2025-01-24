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

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function heartbeat() {
  this.isAlive = true;
}

const wss = new WebSocketServer({ port: 8000 });

wss.on('connection', function connection(ws) {
    ws.isAlive = true;
    ws.on('error', console.error);
    ws.on('pong', heartbeat);

    ws.on('message', function message(data) {
        var response = checkEditor(data);
        var response_length = response.output.length;
            ws.send(JSON.stringify(response));
        if (response.editorReady) {
            ws.terminate()
        }
        else {
        while(!response.editorReady){
            response = checkEditor(data);
            if (response.output.length != response_length){
                response_length = response.output.length;
                ws.send(JSON.stringify(response));
            }
        }

        ws.send(JSON.stringify(response));
        }
    });

});

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