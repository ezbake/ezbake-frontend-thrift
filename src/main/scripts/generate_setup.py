#!/usr/bin/env python
#   Copyright (C) 2013-2014 Computer Sciences Corporation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


import os
import xml.etree.ElementTree as ElemTree
import argparse


def parse_arguments():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-p", "--pom", help="read artifactId from this pom file to use as package name")
    group.add_argument("-n", "--name", help="package name")
    group.add_argument("-v", "--version", help="package version")
    parser.add_argument("-d", "--output-dir", default=".", help="directory in which setup.py will be written")
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_arguments()
    template_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "setup.py.template")
    setup_py_file = os.path.join(os.path.abspath(args.output_dir), "setup.py")

    if os.path.exists(setup_py_file):
        print("Overwriting current setup.py file")

    if args.pom:
        tree = ElemTree.iterparse(args.pom)
        for _,el in tree:
            el.tag = el.tag.split('}', 1)[1]
        pomRoot = tree.root

    name = args.name
    version = args.version

    if not name:
        for element in pomRoot.findall("./artifactId"):
            name = element.text
    if not version:
        for element in pomRoot.findall("./version"):
            version = element.text
        if version.endswith('-SNAPSHOT'):
            version = version.replace('-SNAPSHOT','.preview', 1)

    with open(template_file, 'r') as inf, open(setup_py_file, 'w+') as outf:
        template = inf.read()
        outf.write(template.format(PACKAGE_NAME=name, PACKAGE_VERSION=version))

