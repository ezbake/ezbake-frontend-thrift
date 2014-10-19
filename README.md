# EzReverseProxy Thrift Definitions

## Generating the thrift code
Our build servers aren't set up to generate thrift, so we have to check it in. Run with the "gen-thrift" profile to generate the code:

    mvn generate-resources -P gen-thrift

**Note:** *This generates all thrift source files for all supported languages*
*Supported languages: java, cpp, python, nodejs, ruby*


### Generating the thrift code for specific languages

    mvn generate-resources -P gen-thrift -D languages.to.generate="<language 1> <language 2> ..."

**Example:** *To generate java and cpp files run:*

    mvn generate-resources -P gen-thrift -D languages.to.generate="java cpp"


## Creating packages
Package created uses the source files located in src/main (previously generated thrift source files)

**Creating a Jar * Nar package**

    mvn clean install


Copyright (C) 2013-2014 Computer Sciences Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
