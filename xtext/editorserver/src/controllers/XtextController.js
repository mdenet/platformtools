import * as express from "express";
import  { spawn } from "child_process";
import  fs from "fs";

import {asyncCatch} from "../middleware/ErrorHandlingMiddleware.js";
import { config } from "../config.js";


class XtextController {
    upload;
    // Current line being assembled for the build log
    currentBuildLogLine = "";
    // Build log assembled so far
    buildLog = "";
    errorLog = "";
    exitCode = null;

    router = express.Router();

    constructor(multipartHandler) {
        this.upload = multipartHandler;
        this.router.post('/upload', this.upload.single('xtextProject'), asyncCatch(this.saveProject));
        this.router.get('/editors/:editorId/status', asyncCatch(this.editorStatus));
    }

    saveProject = async (req, res, next) => {
        this.buildLog = "";
        this.errorLog = "";
        this.exitCode = null;

        try {
            //TODO validate request url
            if(req.file){
                 console.log(`File '${req.file.originalname}'  received saved as  '${req.file.filename}'`);
            }

            const build = spawn('sh', ['./build.sh', req.file.filename]);

            console.log(`started build of ${req.file.filename}`)

            build.stdout.on('data', (data) => {
                console.log(`stdout: ${data}`);
              
                this.currentBuildLogLine += data;
                let lastEOLPos = this.currentBuildLogLine.lastIndexOf("\n");
                if (lastEOLPos > -1) {
                    // Conditionally add line to build log
                    let stuffToAdd = this.currentBuildLogLine.substring(0, lastEOLPos);
                    this.currentBuildLogLine = this.currentBuildLogLine.substring(lastEOLPos + 1);

                    // console.log(`About to add new line to build log: "${stuffToAdd}"`);

                    stuffToAdd.split("\n").forEach ((val) => {
                        // TODO: This is a bit crude: really we would want to extract only the response from Xtext proper, but it's better than sending the whole MVN log
                        if (!val.startsWith("[")) {
                            console.log(`Adding to build log: "${val}"`);
                            this.buildLog += val + "\n";
                        }
                    });
                }
            });

            build.stderr.on('data', (data) => {
                console.error(`stderr: ${data}`);
                this.errorLog += data;
            });

            build.on('close', (code) => {
                console.log(`building ${req.file.filename} completed with code ${code}`);

                // TODO: This is a bit crude: really we would want to extract only the response from Xtext proper, but it's better than sending the whole MVN log
                if (!this.currentBuildLogLine.startsWith("[")) {
                    console.log(`Adding to build log: "${this.currentBuildLogLine}"`);
                    this.buildLog += this.currentBuildLogLine;
                }

                this.exitCode = code;
            }); 

            let response = {};
            response.editorUrl= `${config.deployAddress}/${req.file.filename}/`;
            response.editorStatusUrl= `${config.address}/xtext/editors/${req.file.filename}/status`

            res.status(200).json(response);
            
        } catch (err) {
            next(err);
        }

    }

    editorStatus = async (req, res, next) => {
        try {
            const editorId = req.params.editorId;
            const filePath = config.deployFileLocation + "/" + editorId;
            const editorDeployed = fs.existsSync(filePath);

            let response = {};
            response.editorReady = editorDeployed;

            response.output = this.buildLog;

            if (this.exitCode != null && this.exitCode > 0 ){
                // Build failed
                response.error = errorLog;
            }
            
            res.status(200).json(response);

        } catch (err) {
            next(err);
        }
    }
        

}

export { XtextController };
