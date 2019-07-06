#!/bin/bash
## This scritpt requires jq as dependency and input.json
confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}
#rm report.txt
#jq -r '.[0]."aud-cmd"'  input.json ;
#len=$(jq '. | length' input.json) ;
len=100
x=0
while [[ $x -lt $len ]]
do
echo $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."desc"' input.json) >> report.txt;
echo $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-cmd"' input.json) > temp.sh && bash temp.sh >> report.txt && rm temp.sh ;
echo $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-desc"' input.json) >> report.txt;
if [[ `jq --arg x $x -r '[.[] ] | .[$x | tonumber]."rem-exec"' input.json` -eq 1 ]] ; then echo $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."rem-cmd"' input.json) > temp.sh && bash temp.sh >> report.txt && rm temp.sh ; fi
if [[ `jq --arg x $x -r '[.[] ] | .[$x | tonumber]."rem-exec"' input.json` -eq 1 ]] ; then jq --arg x $x -r '[.[] ] | .[$x | tonumber]."rem-desc"' input.json >> report.txt;
#jq --arg x $x -r '[.[] ] | .[$x | tonumber]."desc"' input.json ;
echo $x >> report.txt ;
x=$(( $x + 1 )) ;
echo $x ;
done