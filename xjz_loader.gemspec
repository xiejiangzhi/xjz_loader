
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "xjz_loader/version"

Gem::Specification.new do |spec|
  spec.name          = "xjz_loader"
  spec.version       = XjzLoader::VERSION
  spec.authors       = ["jiangzhi.xie"]
  spec.email         = ["xiejiangzhi@gmail.com"]

  spec.summary       = %q{Package and load code}
  spec.description   = %q{Package and load code}
  spec.homepage      = "https://github.com/xiejiangzhi/xjz_loader"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", '~> 0.12.2'
end
