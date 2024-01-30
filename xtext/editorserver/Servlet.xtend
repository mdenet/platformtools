package DSLQNAME

import com.google.gson.Gson
import com.google.inject.Injector
import java.io.BufferedReader
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStreamReader
import java.nio.charset.Charset
import java.util.ArrayList
import java.util.List
import java.util.Set
import java.util.stream.Collectors
import javax.servlet.ServletException
import javax.servlet.annotation.WebServlet
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse
import net.sourceforge.plantuml.FileFormat
import net.sourceforge.plantuml.FileFormatOption
import net.sourceforge.plantuml.SourceStringReader
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.epsilon.egl.EglTemplateFactoryModuleAdapter
import org.eclipse.epsilon.emc.emf.InMemoryEmfModel
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.util.DisposableRegistry
import org.eclipse.xtext.web.server.IServiceContext
import org.eclipse.xtext.web.server.ISession
import org.eclipse.xtext.web.server.InvalidRequestException
import org.eclipse.xtext.web.server.XtextServiceDispatcher
import org.eclipse.xtext.web.server.generator.GeneratorService
import org.eclipse.xtext.web.servlet.HttpSessionWrapper
import org.eclipse.xtext.web.servlet.XtextServlet

/**
 * Deploy this class into a servlet container to enable DSL-specific services.
 */
@WebServlet(name="XtextServices", urlPatterns="/xtext-service/*")
class DSLNAMEServlet extends XtextServlet {

	static long serialVersionUID = 1L

	DisposableRegistry disposableRegistry

	override void init() throws ServletException {
		super.init()
		val Injector injector = new DSLNAMEWebSetup().createInjectorAndDoEMFRegistration()
		this.disposableRegistry = injector.getInstance(DisposableRegistry)
	}

	private static interface IResponse {
	}

	private static class ToXMIResponse implements IResponse {
		public String output
	}

	private static class ErrorResponse implements IResponse {
		public String error
	}

	private static class ToDiagramResponse implements IResponse {
		public String diagram
	}

	private static class GenerationResponse implements IResponse {
		public List<GeneratedFile> generatedFiles = new ArrayList
	}

	private static class GeneratedFile {
		public String path
		public String content

		static val DEFAULT_LOCATION = "DEFAULT_OUTPUT"

		new(String path, String content) {
			// Strip the weird location code Xtext web adds by default
			if (path.startsWith(DEFAULT_LOCATION)) {
				this.path = path.replaceFirst(DEFAULT_LOCATION, "src-gen/")
			} else {
				this.path = path
			}

			this.content = content
		}
	}

	private static class GenerationHttpServiceContext implements IServiceContext {

		var HttpServletRequest request
		var HttpSessionWrapper sessionWrapper
		var String serviceID

		private static class Request {
			public String fileName
			public String model
		}

		var Request reqJSON

		new(HttpServletRequest req, String serviceID) throws IOException {
			this.request = req

			reqJSON = new Gson().fromJson(request.reader, Request)
			this.serviceID = serviceID
		}

		override Set<String> getParameterKeys() {
			#["resource", "fullText", "allArtifacts", SERVICE_TYPE].toSet
		}

		override String getParameter(String key) {
			switch (key) {
				case SERVICE_TYPE: serviceID
				case "resource": reqJSON.fileName
				case "fullText": reqJSON.model
				case "allArtifacts": "true"
			}
		}

		override ISession getSession() {
			if (sessionWrapper === null) {
				sessionWrapper = new HttpSessionWrapper(request.getSession(true))
			}

			sessionWrapper
		}
	}

	private static class RequestStructure {
		public String input;
	}

	protected override void doPost(HttpServletRequest req,
		HttpServletResponse resp) throws ServletException, IOException {
		val serviceID = req.pathInfo.substring(1)
		var IResponse response = null

		if (serviceID == "to-xmi") {
			var sResult = exportXMI(req)

			if (sResult !== "") {
				response = new ToXMIResponse()
				(response as ToXMIResponse).output = sResult
			} else {
				response = new ErrorResponse()
				(response as ErrorResponse).error = "Unable to generate XMI."
			}
		} else if (serviceID == "to-diagram") {
			var sResult = exportDiagram(req)

			if (sResult !== "") {
				response = new ToDiagramResponse()
				(response as ToDiagramResponse).diagram = sResult
			} else {
				response = new ErrorResponse()
				(response as ErrorResponse).error = "Unable to generate diagram."
			}
		} else if (serviceID == "runGenerator") {
			var result = doGenerate(req)

			if (result !== null) {
				response = new GenerationResponse()

				for (file : result.artifacts) {
					(response as GenerationResponse).generatedFiles.add(
						new GeneratedFile(file.getName(), file.getContent()))
				}
			} else {
				response = new ErrorResponse()
				(response as ErrorResponse).error = "Unable to run code generator."
			}
		} else {
			super.doPost(req, resp)
			return
		}

		resp.setStatus(HttpServletResponse.SC_OK)
		resp.setContentType("application/json")
		val pw = resp.getWriter()

		pw.print(new Gson().toJson(response))

		pw.close()
	}

	/**
	 * Handles the 'to-xmi' command by transforming the model code in parameter 'input', given in the Xtext format of the DSML managed by this editor, into a regular XMI file.
	 */
	private def String exportXMI(
		HttpServletRequest req) throws InvalidRequestException.UnknownLanguageException, IOException {
		val reqObj = new Gson().fromJson(req.reader, RequestStructure)

		val emfURI = URI.createURI("input.LANGUAGE_EXT")
		val resourceServiceProvider = IResourceServiceProvider.Registry.INSTANCE.getResourceServiceProvider(emfURI)
		if (resourceServiceProvider === null) {
			throw new InvalidRequestException.UnknownLanguageException("Unable to identify the Xtext language.")
		}

		val injector = resourceServiceProvider.get(Injector)

		val resourceSet = injector.getInstance(XtextResourceSet)

		val xtextResource = resourceSet.createResource(emfURI)
		xtextResource.load(new ByteArrayInputStream(reqObj.input.getBytes()), null)
		EcoreUtil.resolveAll(xtextResource)

		val xmiResource = resourceSet.createResource(URI.createFileURI("result.xmi"))
		xmiResource.getContents().add(xtextResource.getContents().get(0))
		try (val baos = new ByteArrayOutputStream()) {
			xmiResource.save(baos, null)
			return baos.toString()
		} catch (IOException e) {
			e.printStackTrace()
		}

		""
	}

	/**
	 * Handles the 'to-diagram' command by transforming the model code in parameter 'input', given in the Xtext format of the DSML managed by this editor, into an SVG object diagram generated by PlantUML.
	 */
	private def String exportDiagram(
		HttpServletRequest req) throws InvalidRequestException.UnknownLanguageException, IOException {
		val reqObj = new Gson().fromJson(req.reader, RequestStructure)

		val emfURI = URI.createURI("input.LANGUAGE_EXT")
		val resourceServiceProvider = IResourceServiceProvider.Registry.INSTANCE.getResourceServiceProvider(emfURI)
		if (resourceServiceProvider === null) {
			throw new InvalidRequestException.UnknownLanguageException("Unable to identify the Xtext language.")
		}

		val injector = resourceServiceProvider.get(Injector)

		val resourceSet = injector.getInstance(XtextResourceSet)

		val xtextResource = resourceSet.createResource(emfURI)
		xtextResource.load(new ByteArrayInputStream(reqObj.input.getBytes()), null)
		EcoreUtil.resolveAll(xtextResource)

		try {
			val module = new EglTemplateFactoryModuleAdapter()

			val eglCode = new BufferedReader(
				new InputStreamReader(getClass().getResourceAsStream("model2plantuml.egl"))).lines().collect(
				Collectors.joining("\n"))
			module.parse(eglCode)

			val model = new InMemoryEmfModel(xtextResource)
			model.setName("M")

			module.getContext().getModelRepository().addModel(model)
			val plantUml = module.execute() + ""

			val ssr = new SourceStringReader(plantUml)
			val os = new ByteArrayOutputStream()
			ssr.outputImage(os, new FileFormatOption(FileFormat.SVG))
			os.close()

			return new String(os.toByteArray(), Charset.forName("UTF-8"))
		} catch (Exception e) {
			throw new IOException(e)
		}
	}

	/**
	 * Expect to receive the following parameters:
	 * 
	 * - "fullText": text of model (xtext file)
	 * - "allArtifacts": Boolean to indicate if we need all files, should normally be true
	 * - "resource": file name of the xtext file, so that code generator can access this in the file names it generates
	 */
	private def GeneratorService.GeneratedArtifacts doGenerate(HttpServletRequest req) throws IOException {
		val context = new GenerationHttpServiceContext(req, "generate")

		val emfURI = URI.createURI("input.LANGUAGE_EXT")
		val resourceServiceProvider = IResourceServiceProvider.Registry.INSTANCE.getResourceServiceProvider(emfURI)
		if (resourceServiceProvider === null) {
			throw new InvalidRequestException.UnknownLanguageException("Unable to identify the Xtext language.")
		}

		val injector = resourceServiceProvider.get(Injector)

		val serviceDispatcher = injector.getInstance(XtextServiceDispatcher)
		val service = serviceDispatcher.getService(context)

		service.getService().apply() as GeneratorService.GeneratedArtifacts
	}

	override void destroy() {
		if (disposableRegistry !== null) {
			disposableRegistry.dispose()
			disposableRegistry = null
		}
		super.destroy()
	}
}
