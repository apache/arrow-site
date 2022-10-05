# -*- ruby -*-
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

def production?
  ENV["JEKYLL_ENV"] == "production"
end

webpacked_js = "javascript/main.js"
installed_package_lock_json = "node_modules/.package-lock.json"

file installed_package_lock_json => ["package.json", "package-lock.json"] do
  if production?
    sh("npm", "ci")
  else
    sh("npm", "install", "--no-save")
  end
end

file webpacked_js => ["_webpack/main.js", installed_package_lock_json] do
  rm_f(webpacked_js)
  command_line = ["npx", "webpack"]
  command_line << "--mode=production" if production?
  sh(*command_line)
end

desc "Serve site locally"
task :serve => webpacked_js do
  sh("jekyll",
     "serve",
     "--incremental",
     "--livereload",
     "--host", ENV["HOST"] || "127.0.0.1")
end

task :default => :serve

desc "Generate site"
task :generate => webpacked_js do
  command_line = ["jekyll", "build"]
  base_url = ENV["JEKYLL_BASE_URL"]
  command_line << "--baseurl=#{base_url}" if base_url
  extra_config = ENV["JEKYLL_EXTRA_CONFIG"]
  command_line << "--config=_config.yml,#{extra_config}" if extra_config
  destination = ENV["JEKYLL_DESTINATION"]
  command_line << "--destination=#{destination}" if destination
  sh(*command_line)
end
