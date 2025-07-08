# coding: utf-8
Gem::Specification.new do |s|
  s.name        = "assayo"
  s.version     = "0.1.2"
  s.summary     = "Git log stat report"
  s.description = "Visualization and analysis you git log. Creates HTML report about commits statistics, employees and company. Also it parse git log and give a achievements based on git stat. In addition the typical git stats, this package can show statistics by departments, tasks or determine the location of users. It quickly parses large git log files."
  s.authors     = ["Aleksei Bakhirev"]
  s.email       = "alexey-bakhirev@yandex.ru"
  s.files       = Dir["{assayo}/**/*"] + ["ruby/assayo", "README.md"]
  s.bindir      = "ruby"
  s.executables << "assayo"
  s.homepage    = "https://github.com/bakhirev/assayo"
  s.license     = "MIT"
  s.metadata    = {
    "homepage_uri" => "https://github.com/bakhirev/assayo",
	"source_code_uri" => "https://github.com/bakhirev/assayo"
  }
end
