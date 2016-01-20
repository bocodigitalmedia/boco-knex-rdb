Jasmine = require 'jasmine'
jasmine = new Jasmine()

jasmine.loadConfig
  spec_dir: "spec"
  spec_files: ["**/*[sS]pec.coffee"]

jasmine.execute()
