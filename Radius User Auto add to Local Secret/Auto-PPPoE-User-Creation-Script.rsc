# ==========================================================
# Script Name : PPPoE Auto User Creator
# Description : Automatically creates PPPoE users from a Active tab area
# Author      : jesienazareth
# Version     : v1.0, 2025-05-17
# Target      : MikroTik RouterOS 7.x+
# Usage       : Import to System > Scripts or run via terminal
# ==========================================================

/system script
add dont-require-permissions=no name=ProfileBandwidth policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="P\
    LAN1000= 20480k/20480k 20M/20M \r\
    \nPLAN1695= 30720k/30720k 30M/30M\r\
    \nPLAN2000= 40960k/40960k 40M/40M\r\
    \nVendo= 1k/1k"
add dont-require-permissions=yes name=Auto-PPPoE-User-Creation \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source=":log info \"[AUTO-PPPOE] \?\? Auto user sync START\"\r\
    \n\r\
    \n:foreach i in=[/ppp active find] do={\r\
    \n\r\
    \n    :local user [/ppp active get \$i name]\r\
    \n    :local ip [/ppp active get \$i address]\r\
    \n    :if ([:len \$ip] = 0) do={ :log warning (\"[AUTO-PPPOE] \? No IP for\
    \_user: \" . \$user); :continue }\r\
    \n\r\
    \n    :log info (\"[AUTO-PPPOE] \?\? Checking user: \" . \$user . \" (IP: \
    \" . \$ip . \")\")\r\
    \n\r\
    \n    :local targetIP (\$ip . \"/32\")\r\
    \n    :local queueName (\"pppoe-\" . \$user)\r\
    \n    :local defaultLimit \"20480k/20480k\"\r\
    \n\r\
    \n    # Add or update simple queue\r\
    \n    :if ([/queue simple find where name=\$queueName] != \"\") do={\r\
    \n        /queue simple set [find name=\$queueName] target=\$targetIP max-\
    limit=\$defaultLimit\r\
    \n        :log info (\"[AUTO-PPPOE] \?\? Updated queue for: \" . \$queueNa\
    me)\r\
    \n    } else={\r\
    \n        /queue simple add name=\$queueName target=\$targetIP max-limit=\
    \$defaultLimit\r\
    \n        :log info (\"[AUTO-PPPOE] \? Created queue for: \" . \$queueName\
    )\r\
    \n    }\r\
    \n\r\
    \n    # Skip if already in PPP secret\r\
    \n    :if ([/ppp secret find where name=\$user] != \"\") do={\r\
    \n        :log info (\"[AUTO-PPPOE] \? PPPoE user already exists: \" . \$u\
    ser)\r\
    \n    } else={\r\
    \n\r\
    \n        :local rawLimit [/queue simple get [find name=\$queueName] max-l\
    imit]\r\
    \n        :local limitStr [:pick \$rawLimit 0 [:find \$rawLimit \" \"]]\r\
    \n        :if (\$limitStr = \"\") do={ :set limitStr \$rawLimit }\r\
    \n\r\
    \n        :local dl [:pick \$limitStr 0 [:find \$limitStr \"/\"]]\r\
    \n        :local ul [:pick \$limitStr ([:find \$limitStr \"/\"] + 1) [:len\
    \_\$limitStr]]\r\
    \n        :local bwMatch1 (\$dl . \"/\" . \$ul)\r\
    \n        :local bwMatch2 (\$ul . \"/\" . \$dl)\r\
    \n\r\
    \n        :log info (\"[AUTO-PPPOE] \?\? Bandwidth = \$dl/\$ul\")\r\
    \n\r\
    \n        :local script [/system script get [find name=\"ProfileBandwidth\
    \"] source]\r\
    \n        :local matchedPlan \"\"\r\
    \n\r\
    \n        # Plan matching\r\
    \n        :foreach line in=[:toarray \$script] do={\r\
    \n            :local eqPos [:find \$line \"=\"]\r\
    \n            :if (\$eqPos != -1) do={\r\
    \n                :local rawPlan [:pick \$line 0 \$eqPos]\r\
    \n                :local planLimits [:pick \$line (\$eqPos + 1) [:len \$li\
    ne]]\r\
    \n                :if (([:find \$planLimits \$bwMatch1] != -1) or ([:find \
    \$planLimits \$bwMatch2] != -1)) do={\r\
    \n                    :set matchedPlan [:pick \$rawPlan 0 [:len \$rawPlan]\
    ]\r\
    \n                    :log info (\"[AUTO-PPPOE] \? Matched plan: \" . \$ma\
    tchedPlan)\r\
    \n                }\r\
    \n            }\r\
    \n        }\r\
    \n\r\
    \n        :if (\$matchedPlan = \"\") do={\r\
    \n            :log warning (\"[AUTO-PPPOE] \? No plan match for \$dl/\$ul\
    \")\r\
    \n        } else={\r\
    \n\r\
    \n            # Reliable profile check (with debug log)\r\
    \n            :local profileFound false\r\
    \n            :foreach p in=[/ppp profile find] do={\r\
    \n                :local profName [/ppp profile get \$p name]\r\
    \n                :local cleanedProfile [:pick \$profName 0 [:len \$matche\
    dPlan]]\r\
    \n                :log info (\"[DEBUG] Comparing: match='\$matchedPlan' vs\
    \_profile='\$cleanedProfile'\")\r\
    \n                :if (\$matchedPlan = \$cleanedProfile) do={\r\
    \n                    :set profileFound true\r\
    \n                }\r\
    \n            }\r\
    \n\r\
    \n            :if (\$profileFound = false) do={\r\
    \n                :log warning (\"[AUTO-PPPOE] \?\? Profile missing: \" . \
    \$matchedPlan)\r\
    \n            } else={\r\
    \n\r\
    \n                :do {\r\
    \n                    /ppp secret add name=\$user password=\$user profile=\
    \$matchedPlan service=pppoe disabled=yes\r\
    \n                } on-error={\r\
    \n                    :log warning (\"[AUTO-PPPOE] \? Failed to add user: \
    \" . \$user)\r\
    \n                }\r\
    \n\r\
    \n                :log info (\"[AUTO-PPPOE] \? Created DISABLED PPPoE user\
    : \$user with profile \$matchedPlan\")\r\
    \n            }\r\
    \n        }\r\
    \n    }\r\
    \n}\r\
    \n\r\
    \n:log info \"[AUTO-PPPOE] \?\? Auto user sync COMPLETE\"\r\
    \n"
