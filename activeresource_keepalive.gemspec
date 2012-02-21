# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "activeresource_keepalive/version"

Gem::Specification.new do |s|
  s.name        = "activeresource_keepalive"
  s.version     = ActiveresourceKeepalive::VERSION
  s.authors     = ["Ian Ehlert"]
  s.email       = ["ehlertij@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "activeresource_keepalive"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "activeresource"
end
