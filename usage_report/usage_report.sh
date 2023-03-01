#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: usage_report.sh YYYY-MM"
    exit 1
fi

# generate the new report
module load python/3.8.6
source env/bin/activate
python3 usage_report.py -p chen_std chen_bg2 -m $1 -o ${1}.md

# prepend the report to the history
cat <<EOF >>history.md.tmp
# Usage history

## ${1}

EOF
cat ${1}.md >> history.md.tmp
if [ -f history.md ];
then
    tail -n +3 history.md >> history.md.tmp
fi
mv history.md.tmp history.md

# don't keep the individual month's report anymore
rm ${1}.md
