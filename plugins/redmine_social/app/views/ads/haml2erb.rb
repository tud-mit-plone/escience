  con = ""
  f = File.open("/home/lordf/Documents/workspace/escience/plugins/redmine_social/app/views/ads/edit.html.haml","r")
  con = f.read 
  f.close

  File.open("/home/lordf/Documents/workspace/edit.erb","w"){|f| f.write(Haml2Erb.convert(con))}
  