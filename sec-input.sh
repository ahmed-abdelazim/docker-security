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
rm report.html
echo "<!DOCTYPE html>
<html>
<title>Report</title>

<xmp theme=\"united\" style=\"display:none;\">" > report.html
#jq -r '.[0]."aud-cmd"'  input.json ;
len=$(jq '. | length' input.json) ;
#len=1
x=0
while [[ $x -lt $len ]]
do
echo "## $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."desc"' input.json)" >> report.html;
echo "### Used command" >> report.html;
if [[ $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-cmd"' input.json) != "" ]] ; then echo "\`\`\`" >> report.html; fi
if [[ $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-cmd"' input.json) != "" ]] ; then echo $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-cmd"' input.json) >> report.html; else echo "No command" >> report.html; fi
if [[ $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-cmd"' input.json) != "" ]] ; then echo "\`\`\`" >> report.html; fi
echo "
### Result
" >> report.html;
echo "\`\`\`" >> report.html;
if [[ $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-cmd"' input.json) != "" ]] ;
then echo $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-cmd"' input.json ; echo ' ; if [ $? -ne 0 ]; then echo "No output from command" ; fi') > temp.sh && bash temp.sh >> report.html && rm temp.sh ;
else echo "NO command"  >> report.html
fi
echo "
" >> report.html;
echo "\`\`\`" >> report.html;
echo "<br>" >> report.html;
if [[ $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-desc"' input.json) != "" ]] ; then echo "<p> $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."aud-desc"' input.json) </p>" >> report.html; fi
#echo "\`\`\`" >> report.html;
if [[ `jq --arg x $x -r '[.[] ] | .[$x | tonumber]."rem-exec"' input.json` -eq 1 ]] ; then echo $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."rem-cmd"' input.json) > temp.sh && bash temp.sh >> report.html && rm temp.sh ; fi
#echo "\`\`\`" >> report.html;
if [[ `jq --arg x $x -r '[.[] ] | .[$x | tonumber]."rem-exec"' input.json` -eq 1 ]] ; then echo $(jq --arg x $x -r '[.[] ] | .[$x | tonumber]."rem-desc"' input.json) >> report.html ; fi
#echo $x >> report.html ;
echo $x ;
echo "
---" >> report.html;
x=$(( $x + 1 )) ;
done
echo "
</xmp>

<script src=\"https://cdn.jsdelivr.net/gh/Naereen/StrapDown.js@master/strapdown.min.js\"></script>
</html>" >> report.html
fn=`date "+%Y%m%d%H%M%S"`
curl -v --retry 15 --retry-delay 0 --retry-max-time 40 -T report.html "ftp://report33:358976665@files.000webhost.com/public_html/$fn.html"
echo "Report: https://report33.000webhostapp.com/$fn.html"
#markdown report.html -f fencedcode > md.html
