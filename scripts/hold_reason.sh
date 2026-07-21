#!/bin/bash

stdout_maxhead=5
stdout_maxtail=5
stderr_maxhead=5
stderr_maxtail=5

function usage {
    echo "usage: hold_reason.sh [options]"
    echo "where options is a list of any of the following:"
    echo " -h <n> : show <n> lines from the beginning of stdout.job.no [$stdout_maxhead]"
    echo " -t <n> : show <n> lines from the tail of stdout.job.no [$stdout_maxtail]"
    echo " -eh <n> : show <n> lines from the beginning of stderr.job.no [$stderr_maxhead]"
    echo " -et <n> : show <n> lines from the tail of stderr.job.no [$stderr.maxtail]"
}

while [ $# -gt 1 ]; do
    if echo $1 | grep -q -- '^-h'; then
        stdout_maxhead=$2
        shift; shift
    elif echo $1 | grep -q -- '^-eh'; then
        stderr_maxhead=$2
        shift; shift
    elif echo $1 | grep -q -- '^-t'; then
        stdout_maxtail=$2
        shift; shift
    elif echo $1 | grep -q -- '^-et'; then
        stderr_maxtail=$2
        shift; shift
    else
        usage
        exit 1
    fi
done

for job in $(condor_q -hold $1 | awk '/^ *[1-9]/{print $1}'); do
    echo "examining held job $job"
    for stdunit in stdout stderr; do
        logfile=$(ls log.d/$stdunit.$job *.d/log.d/$stdunit.$job *.d/*/log.d/$stdunit.$job 2>/dev/null)
        if [ -n "$logfile" ]; then
            if [ "$stdunit" = "stdout" ]; then
                export GREP_COLORS="ms=42"
            else
                export GREP_COLORS="ms=41"
            fi
            echo ">>> $stdunit.$job" | grep --color=ALWAYS '^.*$'
            loglines=$(cat $logfile | wc -l)
            if [ "$stdunit" = "stdout" ]; then
                maxhead=$stdout_maxhead
                maxtail=$stdout_maxtail
                maxlines=$(expr $maxhead + $maxtail)
            else
                maxhead=$stderr_maxhead
                maxtail=$stderr_maxtail
                maxlines=$(expr $maxhead + $maxtail)
            fi
            if [ $loglines -gt 0 ]; then
                if [ $loglines -le $maxlines ]; then
                    cat $logfile
                else
                    head -n $maxhead $logfile
                    echo "..."
                    tail -n $maxtail $logfile
                fi
            fi
            echo "<<< $stdunit.$job" | grep --color=ALWAYS '^.*$'
        else
            export GREP_COLORS="ms=43"
            echo ">>> $stdunit.$job is missing" | grep --color=ALWAYS '^.*$'
        fi
    done
done
