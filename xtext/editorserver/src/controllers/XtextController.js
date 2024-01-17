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

            const build = spawn('sh', ['./build.sh', req.file.filename]);

            console.log(`started build of ${req.file.filename}`)

            build.on('close', (code) => {
                console.log(`building ${req.file.filename} completed with code ${code}`);
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
            const buildLogPath= `${config.buildFileLocation}/${editorId}/build.log`;
            const buildErrorLogPath= `${config.buildFileLocation}/${editorId}/build.err`;
            const buildStatusPath= `${config.buildFileLocation}/${editorId}/build.res`;
            const editorDeployed = fs.existsSync(filePath);
            
            let buildLog;
            let errorLog;
            let buildStatus;

            // Read the build log
            try {
                buildLog = fs.readFileSync(buildLogPath, 'utf8');
            } catch (err) {
                console.log("Error reading build log: " + buildLogPath);
                console.log(err);
            }

            // Read the error log
            try {
                errorLog = fs.readFileSync(buildErrorLogPath, 'utf8');
            } catch (err) {
                console.log("Error reading build error log: " + buildErrorLogPath);
                console.log(err);
            }

            // Read the build status
            try {
                buildStatus = Number( fs.readFileSync(buildStatusPath, 'utf8') );
            } catch (err) {
                console.log("Error reading build status: " + buildStatusPath);
                console.log(err);
            }

            let response = {};
            response.editorReady = editorDeployed;
            response.output = buildLog;

            if ( buildStatus > 0 ){
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