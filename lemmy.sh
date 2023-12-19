#!/usr/bin/env bash
set -Eeuo pipefail

lemmy-help -c -f -t lua/dap-probe-rs.lua > doc/dap-probe-rs.txt
