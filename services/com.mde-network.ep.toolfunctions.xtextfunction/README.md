# MDENet Xtext Tool Function

## Running the Tool
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


## API

### Actions

#### Function Xtext
Upload Xtext project files.

`POST /services/xtext`

##### Request Body JSON 
|  Attribute    | Description           | File format | Required |
| --------      | -------               | ------- | ---- |
| **languageName**  | Name of the language in the java class format e.g. `com.mdenet.test.MyLang` | - | Yes |
| **baseName**      | The name of the project's containing folder                                 | - | Yes |
| **extension**     |  The file extension to use for the language's files                         | - | Yes |
| **grammar**       | The Xtext grammar                                                           | Xtext grammar | Yes |
| validator     | The validator source code                                                   | Xtend | No |
| scopeprovider | The scope provider source code                                              | Xtend | No |
| generator     | The generator source code                                                   | Xtend | No |
| **language**      | Set to `xtext` for Xtext functions                                          | - | Yes |

##### Example Request
```
{
    "languageName": "uk.ac.kcl.inf.mdd1.turtles.Turtles",
    "baseName": "uk.ac.kcl.inf.mdd1.turtles",
    "extension": "turtles",
    "grammar": "grammar uk.kcl.inf.mdd1.Turtles...",
    "validator": "undefined",
    "scopeprovider": "undefined",
    "generator": "undefined",
    "language": "xtext"
}
```

##### Response `200` Success

|  Attribute         | Description             | File format |
| --------           | -------                 | ------- |
| editorUrl          | The URL to the provided project's editor that will be available once processed | - |
| editorStatusUrl    | URL of the endpoint to check for the editor's availability | - |
| output             | The terminal output from the tool  | - |

##### Example Response `200` Success

```
{
    "editorUrl": "https://mdenet-ep.sites.er.kcl.ac.uk/tools/xtext/editors/387febee5438973211d6ec302b76c251/",
    "editorStatusUrl": "https://mdenet-ep.sites.er.kcl.ac.uk/tools/xtext/project/xtext/editors/387febee5438973211d6ec302b76c251/status",
    "output": ""
}
```

##### Response Invalid Parameters
|  Attribute         | Description             | File format |
| --------           | -------                 | ------- |
| output             | The terminal output from the tool. | Text |
| error              | The error that occurred.  | Text |


##### Example Response Invalid Parameters

```
{
    "output":"Cannot invoke \"com.google.gson...",
    "error":"Cannot invoke \"com.google.gson..."
}
```

### Editors

#### Status
Returns the status of an uploaded Xtext project's editor.

`GET /project/xtext/editors/{PROJECT_ID}/status`


##### Response `200` Success

|  Attribute         | Description                        | File format |
| --------           | -------                            | ------- |
| editorReady          | True if ready                    | - |
| output             | The terminal output from the tool  | - |

##### Example Response `200` Success

```
{
    "editorReady":false,
    "output":"output":"SLF4J: Failed to load class..."
}
```

##### Response Invalid Editor ID
|  Attribute         | Description                        | File format |
| --------           | -------                            | -------     |
| editorReady        | `false` | Text                     |
| output             | The terminal output from the tool  | Text        |


##### Example Response Invalid Parameters

```
{
    "editorReady":false,
    "output":""
}
```