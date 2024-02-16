# Eclipse OCL Tool Function

## Running the Tool Function
Prerequisites:
- [Maven](https://maven.apache.org/)

To build the tool functions, at the root directory of the platformtools repository  run the following commands. 

```
mvn clean
mvn install
```

To Run the eclipse ocl tool function backend service locally, navigate to the `com.mde-network.ep.toolfunctions.eclipseoclfunction` subdirectory and run the following command.

```
mvn function:run -Drun.functionTarget=com.mdenetnetwork.ep.toolfunctions.eclipseoclfunction.RunEclipseOclFunction -Drun.port=9090
```

## API

### Actions

#### Function OCL
Check OCL constraints for for a given model.

`POST /services/RunOclFunction`

##### Request Body JSON 
|  Attribute    | Description           | File format |
| --------      | -------               | ------- |
| constraints   | The OCL constraints    | Complete OCL |
| metamodel     | The model's metamodel | ecore |
| model         | The model in          | XMI |
| language      | Set to `oclcomplete` for checking OCL constraints  | - |

##### Example Request
```
{
    "constraints": " import 'http://www.eclipse.org/...",
    "metamodel": "@\"http://www.eclipse.org/OCL/...",
    "model": "<?xml version=\"1.0\" encoding=...",
    "language": "oclcomplete"
}
```

##### Response `200` Success

|  Attribute         | Description             | File format |
| --------           | -------                 | ------- |
| validationResult   | The validation result.  | Text |
| output             | The validation result.  | Text |

##### Example Response `200` Success

```
{
    "validationResult": "\n2 - org.eclipse.emf.ecore: Diagnosis of ...'",
    "output": "\n2 - org.eclipse.emf.ecore: Diagnosis of ..."
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
    "output":"Cannot invoke \"com.google.gson.JsonElement...",
    "error":"Cannot invoke \"com.google.gson.JsonElement..."
}
```