# Emfatic Tool Function

## Running the Tool Function
Prerequisites:
- [Maven](https://maven.apache.org/)

To build the tool functions, at the root directory of the platformtools repository  run the following commands. 

```
mvn clean
mvn install
```

To Run the emfatic tool function backend services locally, navigate to the `com.mde-network.ep.toolfunctions.emfaticfunction` subdirectory and run the following commands.

```
mvn function:run -Drun.functionTarget=com.mdenetnetwork.ep.toolfunctions.emfaticfunction.RunConversionEcoreToEmfatic -Drun.port=9091'

mvn function:run -Drun.functionTarget=com.mdenetnetwork.ep.toolfunctions.emfaticfunction.RunConversionEmfaticToDiagram -Drun.port=9092'
```


## API

### Conversions






#### Ecore to Emfatic
Convert a metamodel that is in the Ecore format into one that is in the Emfatic format.

`POST /services/EcoreToEmfatic`

##### Request Body JSON 
|  Attribute    | Description           | File format |
| --------      | -------               | ------- |
| input         | A metamodel           | ecore |


##### Example Request
```
{
    "input":  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<ecore:EPackage xmi:version=..." 
}
```

##### Response `200` Success

|  Attribute         | Description             | File format |
| --------           | -------                 | ------- |
| output             | The validation result.  | emfatic |

##### Example Response `200` Success

```
{
    "output": "@\"http://www.eclipse.org/OCL/Import\"(ecore=..."
}
```

##### Response Invalid Parameters
|  Attribute         | Description                        | File format |
| --------           | -------                            | ------- |
| output             | The terminal output from the tool. | Text |
| error              | The error that occurred.           | Text |


##### Example Response Invalid Parameters

```
{
    "output":null,
    "error":null
}
```



#### Emfatic to Ecore
Convert a metamodel that is in the Emfatic format into one that is in the Ecore format.

`POST /services/EmfaticToEcore`

##### Request Body JSON 
|  Attribute    | Description           | File format |
| --------      | -------               | ------- |
| input         | A metamodel           | emfatic |


##### Example Request
```
{
    "input": "@\"http://www.eclipse.org/OCL/Import\"(ecore=..."
}
```

##### Response `200` Success

|  Attribute         | Description             | File format |
| --------           | -------                 | ------- |
| output             | The validation result.  | ecore |

##### Example Response `200` Success

```
{
    "output": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<ecore:EPackage xmi:version=..."
}
```

##### Response Invalid Parameters
|  Attribute         | Description                        | File format |
| --------           | -------                            | ------- |
| output             | The terminal output from the tool. | Text |
| error              | The error that occurred.           | Text |


##### Example Response Invalid Parameters

```
{
    "output":null,
    "error":null
}
```