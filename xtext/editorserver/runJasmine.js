import jasmine from "jasmine";
import { JUnitXmlReporter } from "jasmine-reporters";

const jasmineManager = new jasmine();

jasmineManager.loadConfigFile('spec/support/jasmine.json');

var junitReporter = new JUnitXmlReporter({
    savePath: './reports',
    consolidateAll: false,
    filePrefix: 'TESTS-'
});

jasmineManager.addReporter(junitReporter);
jasmineManager.execute();