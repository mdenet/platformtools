package com.mdenetnetwork.ep.toolfunctions.xtextfunction;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.mdenetnetwork.ep.toolfunctions.core.MdeNetToolFunction;
import com.mdenetnetwork.ep.toolfunctions.xtext.ProjectFile;
import com.mdenetnetwork.ep.toolfunctions.xtext.XtextTool;


public class RunXtextFunction extends MdeNetToolFunction {

	@Override
	public void serviceImpl(JsonObject request, JsonObject response) throws Exception {
		
		ByteArrayOutputStream bos = new ByteArrayOutputStream();
		
        String validator = request.get("validator") != null ? request.get("validator").getAsString() : null;
        String scopeprovider = request.get("scopeprovider") != null ? request.get("scopeprovider").getAsString() : null;
        String generator = request.get("generator") != null ? request.get("generator").getAsString() : null;

		new XtextTool().
			run( request.get("languageName").getAsString() , 
				 request.get("baseName").getAsString(), 
				 request.get("extension").getAsString(),
				 request.get("grammar").getAsString(),
				 validator,
				 scopeprovider,
				 generator,
				 bos, response);
			
		response.addProperty("output", bos.toString());
	}
	
	private List<ProjectFile> parseProjectFiles(String projectFileValue) {
		List<ProjectFile> projectFiles = null;
		
		if (projectFileValue.equals("\"undefined\"") || projectFileValue.equals("\"null\"")) {
				projectFiles = new ArrayList<ProjectFile>();
						
		} else {
			Gson json = new Gson(); 
			
			ProjectFile[] projectFilesParsed = json.fromJson(projectFileValue, ProjectFile[].class);
			projectFiles = new ArrayList<ProjectFile>(Arrays.asList(projectFilesParsed));
		}
		
		return projectFiles;
	}
	
// mvn function:run -Drun.functionTarget=com.mdenetnetwork.ep.toolfunctions.xtextfunction.RunXtextFunction -Drun.port=9090
 
}
