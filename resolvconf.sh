#!/usr/bin/env bash

realpath=$(realpath resolvconf.sh)
dirname=$(dirname "$realpath")
cd "$dirname"

needed="awk sort uniq curl"

for needed_single in $needed; do
	which "$needed_single" > /dev/null 2> /dev/null && continue
	echo "$needed_single (a necessary tool used by this script) is not installed on this computer or has not been found in your environment paths ($PATH)" 1>&2
	exit 1
done

# With our existing servers in /etc/resolv.conf we need to find out what the IP address of api.opennicproject.org is
result=$(cat /etc/resolv.conf | awk '$1 == "nameserver" {print $2}' | ./_multiexec.sh ./_dnslookup.sh 4 | egrep -v '^((^127\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.))' | sort | uniq -c | sort -rn | awk '{print $2}')
if [ "$result" == "x" ]; then
	# Our fallback is to have a static IP address configured of api.opennicproject.org
	result="173.160.58.201"
fi
apihost=$(echo "$result" | head -n 1)
echo "Using $apihost as API host ..." 1>&2

# Since we now know the IP address of api.opennicproject.org, lets query the API for some Tier2 servers we can use for testing ...
hosts=$(wget --quiet --no-check-certificate https://servers.opennic.org/ -O -|grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
#hosts=$(curl --silent --resolve "api.opennicproject.org:443:$apihost" "https://api.opennicproject.org/geoip/?bare&ipv=4&res=100000" || curl --silent --insecure --header "Host: api.opennicproject.org" "https://$apihost/geoip/?bare&ipv=4&res=1000")
hostscount=$(echo "$hosts" | wc -l)

# Alright, we have our list of Tier2 servers and will now ping them
echo "Pinging $hostscount hosts to determine the top 4 ... (this might take up to a minute... or two...)" 1>&2
pingresults=$(./_ping.sh $hosts)

# We need to throw away servers that fall below the average packet loss of all servers
# Explanation of packet loss filter:
# 5 servers, #1 received 1 response, #2 received 2 responses, #3 received 3 responses, #4 = 4, #5 = 5
# (1+2+3+4+5)/5 = 3, the average amount of responses per server is 3
# So we will now filter all servers that have a response packet count of below 3 (in this case #1 and #2 fall out of our list; #3, #4 and #5 are the servers we're going to test)
avgrcvd=$(echo "$pingresults" | awk -F/ 'BEGIN{sum=0;count=0;}{count+=1;sum+=$4}END{print sum/count;}')

# Here we will finally apply the packet loss filter and also sort the servers by their average response time
hosts=$(echo "$pingresults" | awk -F/ '$4 >= '$avgrcvd'' | sort -t/ -nk8)

# Lets build our resolv.conf
echo "$hosts" | head -n 4 | awk '{print "nameserver "$1}'
resolvconf=$(echo "$hosts" | head -n 4 | awk '{print "nameserver "$1}')$(cat /etc/resolv.conf | awk '$1 != "nameserver"')

# If we have write access to resolv.conf, lets update it
# There is currently no reliable way of building a correct resolv.conf perfectly merging into the existing resolv.conf - I will update this at a later time
#if test -w /etc/resolv.conf; then
#	read -p "I have write access to /etc/resolv.conf. Should I update it for you?" yn
#	if [ "x$yn" == "xYes" -o "x$yn" == "xyes" -o "x$yn" == "xy" -o "x$yn" == "xY" ]; then
#		echo "$resolvconf" > /etc/resolv.conf
#	fi
#fi
