# -*- encoding: utf-8 -*-
# stub: russian 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "russian".freeze
  s.version = "0.6.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yaroslav Markin".freeze]
  s.autorequire = "russian".freeze
  s.date = "2011-10-23"
  s.description = "Russian language support for Ruby and Rails".freeze
  s.email = "yaroslav@markin.net".freeze
  s.extra_rdoc_files = ["README.textile".freeze, "LICENSE".freeze, "CHANGELOG".freeze, "TODO".freeze]
  s.files = ["CHANGELOG".freeze, "LICENSE".freeze, "README.textile".freeze, "TODO".freeze]
  s.homepage = "http://github.com/yaroslav/russian/".freeze
  s.rubygems_version = "1.6.2".freeze
  s.summary = "Russian language support for Ruby and Rails".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 3

  s.add_runtime_dependency(%q<i18n>.freeze, [">= 0.5.0".freeze])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 2.7.0".freeze])
end
