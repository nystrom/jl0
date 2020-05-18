#!/bin/sh

export JULIA_PROJECT="$(cd $(dirname $0); pwd)"
julia --color=yes -e 'using Pkg; Pkg.test()'
