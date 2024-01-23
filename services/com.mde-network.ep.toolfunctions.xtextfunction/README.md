# MDENet Xtext Tool Function

Prerequisites:
- [Maven](https://maven.apache.org/)

To build the tool functions, at the root directory of the platformtools repository  run the following commands. 

```
mvn clean
mvn install
```

To Run the MDENet Xtext tool function backend service locally, navigate to the `com.mde-network.ep.toolfunctions.epsilonfunction` subdirectory and run the following commands.

```
mvn function:run -Drun.functionTarget=com.mdenetnetwork.ep.toolfunctions.xtextfunction.RunXtextFunction -Drun.port=9094'
```

To provide a usable service an editor server is required in addition to the Xtext tool function.


## Editor Server
The editor server component receives an Xtext project from an Xtext tool function, builds the project, and deploys it making a web-editor available to use by an education platform instance.

The editor server is provided as a docker file located in the following directory of this repository `xtext/`.

Upon restart, all editor instances and the contents of received projects and build paths are cleaned.

### Environment Variables
This section documents the environment variables supported by the Editor Server.

| Name                    | Type | Description | Example | 
| ---                     | ---  | ---         | --- | 
| ES_BUILD_LOCATION       | Path | The path where Xtext project build files are stored.  | /home/build  |
| ES_DEPLOY_FILE_LOCATION | Path |  The path to the tomcat webapp directory where built editor instances are deployed.  | /home/deploy  |
| ES_UPLOAD_LOCATION      | Path |  The path where received Xtext project zip archives are stored.  |  /home/uploads |
| ES_PORT                 | Int | The port of the editor server. | 1234  |
| INSTALL_DIR             | Path | The path where required tools are installed. | /usr/local |
| NODE_VERSION            | String | The version of Node.js to use. | 19.0.0 |
|  TS_PORT                | Int | The port of the education platform tool service | 1234 |
| XTEXT_ES_STOP_CRON_TIME | Cron Time | The date time to stop the editor server in unix CRON format. If unset the editor server will not stop. | `* 4 * * *` | 
