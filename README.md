# CloudFlare Dynamic DNS Client

Bare minimum bash script to use CloudFlare DNS API for Dynamic DNS. To get your domain on CloudFlare DNS for just go to https://cloudflare.com and they will walk you through the process.

## Installation

It uses [jq](https://stedolan.github.io/jq/) for JSON parsing. So you may download it from https://stedolan.github.io/jq/download/ or just copy paste the script in terminal.

### Windows

It works on Git Bash! 

````bash
git clone https://github.com/parthpower/CloudFlare-DDNS-Client.git
cd CloudFlare-DDNS-Client
chmod +x cf_ddns.sh
# Install jq for 64 bit Windows
curl https://github.com/stedolan/jq/releases/download/jq-1.5/jq-win64.exe > jq.exe
````

### Linux

```shell
git clone https://github.com/parthpower/CloudFlare-DDNS-Client.git
cd CloudFlare-DDNS-Client
chmod +x cf_ddns.sh
# Install jq for 64 bit Linux
curl https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 > jq
# sudo apt-get install jq
chmod +x jq
```

### macOS

I have no idea but it should work.

## How do I run it?

1. Get `zone id` and `API Key` from CloudFlare Dashboard.

2. First Run:

   `./cf_ddns.sh --key <api key> --zone <zone id> --email <your email> --interval 60 --config config.ini --save test.example.com | tee log.txt`

3. Once you have the config file, just `./cf_ddns.sh`

4. Done! You can find all the DNS records on the CloudFlare dashboard.

`./cf_ddns.sh -h` for help.

## Credits

- [ipify.org](https://ipify.org) for the simplest API to get IP.
- [httpbin.org](https://httpbin.org) for the debugging help.
- [Tutorial for Arg Parse](http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt)
- Ton of [StackOverflow](https://stackoverflow.com) and https://unix.stackexchange.com help.
- [CloudFlare](https://CloudFlare.com) for the awesome API.
- [GitHub](https://github.com) and [NameCheap](https://nc.me) for the free domain in education pack.

## Notes

- To save number of API calls this script updates the `A` record only when the host IP changes. It does not periodically check if the record is modified by other means. You can use `--always-update-dns` to update the record entry at the interval.

- What is DNS record? https://www.cloudflare.com/learning/dns/dns-records/ (Psst: We are just messing with `A` record here)

- Works on CloudFlare API `v4`

- Maybe use `sed` instead of `jq` in future. Pull-Requests are welcomed.

  ​