#!/usr/bin/sh

# Intended to wrap bin/blin.p6 for standard pre-release runs.
#
# If you have a one off need, copy this to make any changes needed (to avoid accidentally committing to git)
#
# Runs under systemd-run to avoid individual tests taking down the entire machine.

# What versions are we testing (get latest tag for OLD version)
export OLD=`curl --silent -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/rakudo/rakudo/releases?per_page=1" | grep 'tag_name' | awk -F: '{print $2}' | awk -F\" '{print $2}'`
export NEW=HEAD
echo "$OLD..$NEW"

# How often to emit diagnostics
export HEARTBEAT=60

# How many processors to use? Most
export NPROCMULT=0.875

# Cap for memory usage
export MAX_MEMORY=63.5G

# Warning in case last run crashed
echo "If system-d complains, you might need to run 'systemctl --user reset-failed'"

systemd-run -E RAKULIB=. --user --tty --wait --working-directory=/blin --unit=blin --slice=user.slice --property="CPUWeight=100" --property="MemoryMax=$MAX_MEMORY" raku --ll-exception bin/blin.p6 --old=$OLD --new=$NEW --nproc-multiplier=$NPROCMULT --heartbeat=$HEARTBEAT
