#!/usr/bin/env bash
# CloudFlare as DDNS

# ARG PARSER
################

# Load Default Config
interval=10
save=false
. ./config.ini
while (( "$#" )); do
	case "$1" in
		-z|--zone)
			zone=$2
			shift 2
			;;
		-k|--key)
			key=$2
			shift 2
			;;
		-e|--email)
			email=$2
			shift 2
			;;
		-c|--config)
			config_file=$2
			shift 2
			;;
		-i|--interval)
			interval=$2
			shift 2
			;;
		-s|--save)
			save=true
			shift
			;;
		-h|--help)
			printf "Usage: ./cf_ddns.sh \t[-z|--zone <zone id> 
			-e|--email <email> 
			-k|--key <API key>]
			[-c|--config <config file to load/store>] 
			[-s|--save]
			[-i|--interval <update interval in seconds>]
			[sub.primary.com]

Example:
To host current ip at test.example.com
./cf_ddns.sh --key <api key> --zone <zone id> --email <your email> --interval 60 --config config.ini --save test.example.com
			"
			exit 0
			;;
		--) 
			shift
			break 
			;;
		*)
			name=$1
			shift
			break
			;;
	esac
done


if [[ $config_file ]]; then
	if [[ $save ]]; then
		echo "Saving config..."
		echo "zone=$zone;" 	>  $config_file
		echo "key=$key;" 	>> $config_file
		echo "email=$email;" >> $config_file
		echo "name=$name;" >> $config_file
        echo "interval=$interval;" >> $config_file
	else
		. $config_file
	fi
		
fi

printf "[config] Zone:\t$zone
[config] Key:\t************
[config] Email:\t$email
[config] Name:\t$name\n"

# Main Code
###############
endpoint="https://api.cloudflare.com/client/v4/zones/$zone/dns_records/";
headers="-H Content-type:application/json -H X-Auth-Key:$key -H X-Auth-Email:$email";

# Get Current IP Address and try to find records similar to it
echo "[$(date)] INFO: Getting IP"
ip=$(curl -s http://api.ipify.org||echo 'null');
last_ip=$ip;

echo "[$(date)] INFO: Current IP:$last_ip"
echo "[$(date)] INFO: Fetchin Record"

content=$(curl -s -X GET $headers $endpoint\?content=$ip\&name=$name||echo 'null');
id=$(echo $content|jq -r '.result[0].id')	# it will be 'null' if not found. Checked in main loop.
sucess=$(echo $content|jq -r '.result[0].sucess')

# Make sure internet is working to start up
while [[ $last_ip = 'null' || sucess = 'false' ]]; do
	last_ip=$(curl -s http://api.ipify.org||echo 'null')
	content=$(curl -s -X GET $headers $endpoint\?content=$ip\&name=$name||echo 'null');
	id=$(echo $content|jq -r '.result[0].id');
	name=$(echo $content|jq -r '.result[0].name');
	sucess=$(echo $content|jq -r '.result[0].sucess');
	# We are offline
	echo "[$(date)] WARNING: Offline. Waiting for $interval s."
	sleep $interval
	continue
done

a_name=$(echo $name|cut -d'.' -f1)

while [[ true ]]; do
	# Update IP
	current_ip=$(curl -s http://api.ipify.org||echo 'null')
	echo "[$(date)] INFO: Current IP:$ip";
	
	# Check if offline
	if [[ $current_ip = 'null' ]]; then
		
		echo "[$(date)] WARNING: You are offline"
		sleep $interval
		continue
	fi

	# Check for IP Updates or if it requires creating new record.
	if [[ $current_ip = $last_ip && $id != 'null' ]]; then
	
		echo "[$(date)] INFO: No updates"
		sleep $interval
		continue
	fi
	
	# Code gets here only if IP is updated or to create new record
	last_ip=$current_ip;
	ip=$current_ip;

	if [[ $id = 'null' ]] ; then
		# Create Record
		echo "[$(date)] INFO: Creating New Record"
		content=$(curl -s -X POST $headers $endpoint -d "{\"type\":\"A\",\"name\":\"$a_name\",\"content\":\"$ip\",\"proxied\":false}");
	else
		echo "[$(date)] INFO: Updating Record"
		content=$(curl -s -X PUT $headers $endpoint -d "{\"type\":\"A\",\"name\":\"$a_name\",\"content\":\"$ip\",\"proxied\":false}");
	fi
	id=$(echo $content|jq -r '.result.id');
	echo "[$(date)] INFO: $content";
	echo "[$(date)] INFO: Record ID:$id";
	sleep $interval
done

