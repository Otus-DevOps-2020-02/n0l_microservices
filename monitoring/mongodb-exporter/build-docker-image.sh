#!/bin/bash
git clone https://github.com/percona/mongodb_exporter.git
cd mongodb_exporter/
make docker
cd ../
rm -rf mongodb_exporter/
