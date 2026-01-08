# shellcheck shell=bash

mean() { awk '{s+=$1} END{print s/NR}'; }

stddev() {
  awk '{x[NR]=$1; s+=$1}
       END{
         m=s/NR
         for(i=1;i<=NR;i++) v+=(x[i]-m)^2
         print sqrt(v/(NR-1))
       }'
}

percentile() {
  awk -v p="$1" '{a[NR]=$1}
       END{
         asort(a)
         print a[int((p/100)*(NR-1))+1]
       }'
}

ci_bounds() {
  awk -v z="$CONF_Z" '{x[NR]=$1; s+=$1}
       END{
         m=s/NR
         for(i=1;i<=NR;i++) v+=(x[i]-m)^2
         sd=sqrt(v/(NR-1))
         e=z*sd/sqrt(NR)
         print m-e, m+e
       }'
}
