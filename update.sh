#!/bin/bash
rm -rf css
rm -rf js
rm index.html
wget --page-requisites --convert-links --no-host-directories http://localhost:8081
