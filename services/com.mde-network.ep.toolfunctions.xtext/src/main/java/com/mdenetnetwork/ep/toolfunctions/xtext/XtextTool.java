package com.mdenetnetwork.ep.toolfunctions.xtext;


import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.OutputStream;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl;
import org.eclipse.xtext.xtext.wizard.cli.CliProjectsCreatorMain;
import org.apache.hc.client5.http.HttpHostConnectException;
import org.apache.hc.client5.http.entity.mime.MultipartEntityBuilder;
import org.apache.hc.core5.http.ContentType;
import org.apache.hc.core5.http.HttpEntity;
import org.apache.hc.client5.http.entity.mime.HttpMultipartMode;
import org.apache.hc.client5.http.fluent.Request;

public class XtextTool  { 

	static final String PROJECT_PATH = "./xtext-project/" ;
	static final String PROJECT_FILENAME = "xtext-project.zip" ;
	static final String PROJECT_FILE_PATH = "./" + PROJECT_FILENAME ;
	static final String ES_JSON_RESPONSE_FIELD = "editorUrl";
	static final String ES_JSON_RESPONSE_FIELD_ID = "editorID";
	static final int FILE_BUFFER_SIZE = 1024;
	
	public XtextTool() {
		
		// Register resource factories
		Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().put("ecore", new EcoreResourceFactoryImpl());
	}


	public void run( String languageName, String baseName, String extension, 
			         String grammar, String validator, String scopeProvider, String generator, 
			         OutputStream outputStream, JsonObject response) throws Exception {

		// Create Xtext project with web editor enabled
		File projectFolder = new File(PROJECT_PATH);
		
		String[] args = new String[] {
				"-targetDir=" + projectFolder.getAbsolutePath(),
				"-languageName="+languageName,
				"-baseName="+baseName,
				"-extension="+extension,
				"-enabledProjects=UIProject,GenericIDE,RuntimeTest,UITest,Web",
				"-buildSystem=MAVEN",
				"-sourceLayout=PLAIN",
				"-languageServer=FATJAR",
				"-xtextVersion=2.30.0",
				"-projectLayout=FLAT",
				"-javaVersion=JAVA11"
			};

		
		CliProjectsCreatorMain.main(args);
		
		// Add activity files
        final String basePackage = languageName.substring(0, languageName.lastIndexOf(".")); // Everything but last segment which is the language java class
        final String shortName = languageName.substring(languageName.lastIndexOf(".") + 1); // The last segment
        final String languagePath = PROJECT_PATH + baseName + "/src/" + basePackage.replace('.', '/');

		if (grammar != null && !grammar.equals("undefined") ) {
			final String xtextGrammarPath= languagePath + "/" + shortName + ".xtext";
			recreateProjectFile(xtextGrammarPath, grammar);
		}

		if (validator != null && !validator.equals("undefined") ) {
			final String xtextValidatorPath= languagePath + "/validation/" + shortName + "Validator.xtend";
			recreateProjectFile(xtextValidatorPath, validator);		
		}
		
		if (scopeProvider != null && !scopeProvider.equals("undefined") ) {
			final String xtextScopeProviderPath= languagePath + "/scoping/" + shortName + "ScopeProvider.xtend";
			recreateProjectFile(xtextScopeProviderPath, scopeProvider);
		}
		
		if (generator != null && !generator.equals("undefined") ) {
			final String xtextGeneratorPath= languagePath + "/generator/" + shortName + "Generator.xtend";
			recreateProjectFile(xtextGeneratorPath, generator);
		}
		
		// Compress files for transfer to build server
		
		ZipOutputStream projectFileStream = new ZipOutputStream( new FileOutputStream(PROJECT_FILE_PATH) );
		
		compressDirectory(projectFolder, "", projectFileStream);
		 
		projectFileStream.flush();
		projectFileStream.close();
		 
		
		// Send to the build server
		
		final String EDITOR_SERVER_URL= "http://127.0.0.1:10001/xtext/upload";  // TODO set URL via environment variable 
		 
		 try {	 
			 postProjectToUrl(new File(PROJECT_FILE_PATH), EDITOR_SERVER_URL, response);
			 
		 } catch (HttpHostConnectException e)  {
		 
			 System.err.println("Failed to connect to editor server: " + EDITOR_SERVER_URL);
			 
		}finally {
			 // Cleanup created files
			 deleteDir(projectFolder);
			 new File(PROJECT_FILE_PATH).delete();
		 }

	}

	
	private void recreateProjectFile (String path, String contents) {
  
	    System.out.println("Re-creating file: " + path);
    
        Path filePath= Path.of(path);
		try {
            if ( !Files.exists(filePath) ){
                System.out.println("File did not exist. Created.");
                Files.createDirectories(filePath.getParent());
                Files.createFile(filePath);
            }

			Files.writeString(filePath, contents);
			
		} catch (IOException e) {
			
			System.err.println("Error "+ e.toString() +" saving file: " + path);
		}
	}

	
	private void compressDirectory(File dir, String parentDir, ZipOutputStream output )  
			throws FileNotFoundException, IOException {
		
		for (File file : dir.listFiles() ){
		
			if (file.isDirectory()) {
				
				if (file.listFiles().length == 0) {
					// Add empty folder directories
					String dirPath = file.getName() + "/";
					
					if (!parentDir.isEmpty()) {
						dirPath = parentDir + "/" + dirPath;
					}
					
					output.putNextEntry(new ZipEntry( dirPath ) );
					output.closeEntry();
				}
					
				compressDirectory(file, parentDir + "/" + file.getName(), output );
				
			} else {
				// Prepare to add file to the compressed stream
				output.putNextEntry(new ZipEntry(parentDir + "/" + file.getName()) );
				BufferedInputStream input = new BufferedInputStream(new FileInputStream(file));
				
				// Copy the file contents to the compressed stream
				long bytesRead = 0;
				byte[] bytesIn = new byte[FILE_BUFFER_SIZE];
				int read = 0;
				while((read = input.read(bytesIn)) != -1) {
					output.write(bytesIn, 0 , read);
					bytesRead += read;
				}
				output.closeEntry();
			}
		}
	}
	
	
	private void postProjectToUrl(File project, String url, JsonObject response) throws IOException {
		
		HttpEntity entity = MultipartEntityBuilder.create()
				 .setMode(HttpMultipartMode.LEGACY)
				 .setCharset(Charset.forName("UTF8"))
				 .addBinaryBody("xtextProject", project, ContentType.MULTIPART_FORM_DATA, PROJECT_FILENAME)
				 .build();
		 
		String uploadResponse = Request.post(url)
				 .body(entity)
				 .execute().returnContent().asString();

				
		JsonObject jsonObject = JsonParser.parseString(uploadResponse).getAsJsonObject();
				
		response.addProperty(ES_JSON_RESPONSE_FIELD, jsonObject.get(ES_JSON_RESPONSE_FIELD).getAsString());
		response.addProperty(ES_JSON_RESPONSE_FIELD_ID, jsonObject.get(ES_JSON_RESPONSE_FIELD_ID).getAsString());
	}
	
	private void deleteDir(File dir){
	    File[] contents = dir.listFiles();
	    if (contents != null) {
	        for (File f : contents) {
	            if (! Files.isSymbolicLink(f.toPath())) {
	                deleteDir(f);
	            }
	        }
	    }
	    dir.delete();
	}

}
	
