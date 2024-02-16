# Additional MDENet Epsilon Tool Functions

## Running the Tool Function
Prerequisites:
- [Maven](https://maven.apache.org/)

To build the tool functions, at the root directory of the platformtools repository  run the following commands. 

```
mvn clean
mvn install
```

To Run the additional epsilon tool function backend service locally, navigate to the `com.mde-network.ep.toolfunctions.epsilonfunction` subdirectory and run the following commands.

```
mvn function:run -Drun.functionTarget=com.mdenetnetwork.ep.toolfunctions.epsilonfunction.RunConversionFlexmiToXmi -Drun.port=9093'
```

## API

### Conversions

#### Flexmi to XMI
Convert a model that is in the Flexmi format to one that is in the XMI format.

`POST /services/FlexmiToXmi`

##### Request Body JSON 
|  Attribute    | Description           | File format |
| --------      | -------               | ------- |
| model         | The model to convert  | flexmi |
| metamodel     | The model's metamodel | ecore |



##### Example Request
```
{
    "input": "<?nsuri http://www.eclipse.org/mdt/ocl/oclinecore/...",
    "metamodel": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<ecore..."
}
```

##### Response `200` Success

|  Attribute         | Description             | File format |
| --------           | -------                 | ------- |
| output             | The converted model     | xmi |

##### Example Response `200` Success

```
{
    "output": "<?xml version=\"1.0\" encoding=\"ASCII\"?>..."
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
    "output":null,
    "error":null
}
```