
import {XtextController} from "../src/controllers/XtextController.js"
import multer from 'multer';

describe("XtextController", () => {

    it("XtextController can be created", () => {
        
        const upload = multer({ dest: "uploads/" });
        let xtextCtrl = new XtextController(upload);

        expect(xtextCtrl).toBeInstanceOf(XtextController);
    })        
    
})
