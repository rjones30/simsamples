condor_q -run \
  -format "%d." ClusterId \
  -format "%d " ProcId \
  -format "%d " JobCurrentStartDate \
  -format "%f\n" RemoteUserCpu \
  | awk -v now=$(date +%s) -v dagman=1532 '
{
    split($1, a, ".");
    cluster = a[1];
    if (cluster == dagman) next;
    elapsed = now - $2;
    cpu = $3;
    if (elapsed < 1800) next;  # ignore jobs running less than 30 min
    ratio = cpu / elapsed;
    if (ratio < 0.05) {  # less than 5% CPU efficiency
        print $1, "elapsed=" elapsed, "cpu=" cpu, "ratio=" ratio, "ZOMBIE?"
    }
}'
