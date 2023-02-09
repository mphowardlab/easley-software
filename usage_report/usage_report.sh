#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: usage_report.sh YYYY-MM"
    exit 1
fi

module load python/3.8.6
source env/bin/activate

python3 usage_report.py -p chen_std chen_bg2 -m $1 -o ${1}.md
