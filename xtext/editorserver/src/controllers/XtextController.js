import * as express from "express";
import  { spawn } from "child_process";
import  fs from "fs";

import {asyncCatch} from "../middleware/ErrorHandlingMiddleware.js";
import { config } from "../config.js";


class XtextController {
    upload;
    router = express.Router();

    constructor(multipartHandler) {
        this.upload = multipartHandler;
        this.router.post('/upload', this.upload.single('xtextProject'), asyncCatch(this.saveProject));
        this.router.get('/editors/:editorId/status', asyncCatch(this.editorStatus));
    }

    saveProject = async (req, res, next) => {

        try {
            //TODO validate request url
            if(req.file){
                 console.log(`File '${req.file.originalname}'  received saved as  '${req.file.filename}'`);
            }

            const build = spawn('/bin/bash', ['./build.sh', req.file.filename]);

            console.log(`started build of ${req.file.filename}`)

            // Report any stdout and stderr output on the server console to aid debugging
            build.stdout.on('data', (data) => {
                console.log(`stdout: ${data}`);
            });
            build.stderr.on('data', (data) => {
                console.error(`stderr: ${data}`);
            });

            build.on('close', (code) => {
                console.log(`building ${req.file.filename} completed with code ${code}`);
            }); 

            let response = {};
            response.editorUrl= `${config.deployAddress}/${req.file.filename}/`;
            response.editorID= `${req.file.filename}`

            res.status(200).json(response);
            
        } catch (err) {
            next(err);
        }

    }

    editorStatus = async (req, res, next) => {
        try {
            const editorId = req.params.editorId;
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
            
            res.status(200).json(response);

        } catch (err) {
            next(err);
        }
    }
        

}

export { XtextController };
