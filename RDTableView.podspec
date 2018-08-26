Pod::Spec.new do |s|

  s.name         = "RDTableView"
  s.version      = "1.0.0"
  s.summary      = "a customize tableview very convience to use"
  s.homepage     = "https://github.com/Radarrrrr/RDTableView"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Radar" => "imryd@163.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Radarrrrr/RDTableView.git", :tag => "1.0.0" }
  s.source_files  = "RDTableView/*"
  s.requires_arc = true

end