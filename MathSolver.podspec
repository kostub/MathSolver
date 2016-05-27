Pod::Spec.new do |s|
  s.name         = "MathSolver"
  s.version      = "0.2.0"
  s.summary      = "Solver for math equations."
  s.description  = <<-DESC
MathSolver is a library for solving math equations. It can
parse math equations from a string or LaTeX and then solve
them to the lowest possible form.
                   DESC
  s.homepage     = "https://github.com/kostub/MathSolver"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kostub Deshmukh" => "kostub@gmail.com" }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/kostub/MathSolver.git", :tag => s.version.to_s }
  s.source_files = 'MathSolver/**/*.{h,m}'
  s.prefix_header_file = 'Log.pch'
  s.private_header_files = 'MathSolver/**/internal/*.h', 'MathSolver/analysis/rules/*.h'
  s.dependency 'iosMath', '~> 0.7.2'
  s.requires_arc = true
end
