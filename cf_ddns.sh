#!/usr/bin/env bash
# CloudFlare as DDNS

# ARG PARSER
################

# Load Default Config
interval=10
save=false
always_update_dns=false
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
		--always-update-dns)
			always_update_dns=true
			shift
			;;
		-h|--help)
			printf "Usage: ./cf_ddns.sh \t[-z|--zone <zone id> 
			-e|--email <email> 
			-k|--key <API key>]
			[-c|--config <config file to load/store>] 
			[-s|--save]
			[--always-update-dns]
			[-i|--interval <update interval in seconds>]
			[sub.primary.com]
	
	Use --alway-update-dns will match DNS record with the machine IP at every interval. Not recommended for free tier DNS.
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
		echo "Saving config...";
		echo "zone=$zone;" 	>  $config_file;
		echo "key=$key;" 	>> $config_file;
		echo "email=$email;" >> $config_file;
		echo "name=$name;" >> $config_file;
        echo "interval=$interval;" >> $config_file;
	else
		. $config_file
	fi
		
fi

printf "[config] Zone:\t$zone
[config] Key:\t************
[config] Email:\t$email
[config] Name:\t$name\n";

# Main Code
###############
endpoint="https://api.cloudflare.com/client/v4/zones/$zone/dns_records";
headers="-H Content-type:application/json -H X-Auth-Key:$key -H X-Auth-Email:$email";
id="null";
last_ip="null";

while [[ true ]]; do
	# Update IP
	current_ip=$(curl -s http://api.ipify.org||echo 'null')
	
	# Check if offline
	if [[ $current_ip = 'null' ]]; then
		echo "[$(date)] WARNING: Failed to get your IP.";
		sleep $interval
		continue
	else
		echo "[$(date)] INFO: Current IP:$current_ip";
	fi

	if [[ $always_update_dns = 'false' ]] ; then
		# Skip to start if there is no updates in IP
		if [[ $current_ip = $last_ip ]]; then
			echo "[$(date)] INFO: Host IP Unchanged. Not checking DNS Records.";
			sleep $interval;
			continue;
		else
			last_ip=$current_ip; 
		fi
	fi

	for cur_name in $(echo $name | tr ";" "\n")
	do
		a_name=$(echo $cur_name|cut -d'.' -f1)
		# Check if DNS Record Exist
		echo "[$(date)] INFO: Checking for existing DNS Record $cur_name.";
		content=$(curl -s -X GET $headers $endpoint\?\&name=$cur_name||echo 'null');
		id=$(echo $content|jq -r '.result[0].id');
		ip_on_record=$(echo $content|jq -r '.result[0].content');
		echo "[$(date)] INFO: DNS Record ID:$id";
		echo "[$(date)] INFO: IP on DNS Record $ip_on_record";

		if [[ $id = 'null' ]] ; then
			# Create Record
			echo "[$(date)] INFO: Creating New Record"
			content=$(curl -s -X POST $headers $endpoint -d "{\"type\":\"A\",\"name\":\"$a_name\",\"content\":\"$current_ip\",\"proxied\":false}");
			id=$(echo $content|jq -r '.result.id');
			
			echo "[$(date)] INFO: $content";
			echo "[$(date)] INFO: Record ID:$id";
			
			if [[ $(echo $content | jq -r '.success') != 'true' ]]; then
				echo "[$(date)] ERROR: Failed with errors $(echo $content | jq -r '.errors')";
				continue;
			fi
		else
			if [[ $ip_on_record != $current_ip ]]; then
				# Update Existing DNS Record
				echo "[$(date)] INFO: Updating Existing Record ID: $id";
				content=$(curl -s -X PUT $headers $endpoint/$id -d "{\"type\":\"A\",\"name\":\"$a_name\",\"content\":\"$current_ip\",\"proxied\":false}");
				id=$(echo $content|jq -r '.result.id');
				
				echo "[$(date)] INFO: $content";
				echo "[$(date)] INFO: Record ID:$id";
				
				if [[ $(echo $content | jq -r '.success') != 'true' ]]; then
					echo "[$(date)] ERROR: Failed with errors $(echo $content | jq -r '.errors')";
					continue;
				fi

			else
				echo "[$(date)] INFO: Not updating A record because IP on record is same as host ip.";
			fi
		fi
        done

	sleep $interval
done

