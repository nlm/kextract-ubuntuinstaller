#!/bin/sh
relid="${1:-00}"
reltag=$(date "+%Y.%m.%d.${relid}")
echo git tag "'v${reltag}'" -m "'version ${reltag}'"
