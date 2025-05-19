# ==========================================================
# Script Name : PPPoE Auto User Creator
# Description : Automatically creates PPPoE users from a Active tab area
# Author      : jesienazareth (jesync)
# Version     : v1.0, 2025-05-17
# Target      : MikroTik RouterOS 7.x+
# Usage       : Import to System > Scripts or run via terminal
# Auto-PPPoE User Creation â€“ FINAL CLEAN FIXED VERSION
# Supports toggle: username=password OR global password
# ==========================================================



/system script
add dont-require-permissions=no name=Auto-PPPoE-User-Creation owner=jnhl \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source="# Auto-PPPoE User Creation \E2\80\93 FINAL CLEAN FIXED VERSION\r\
    \n# Supports toggle: username=password OR global password\r\
    \n\r\
    \n:local useGlobalPassword false\r\
    \n:local globalPassword \"pass123\"\r\
    \n\r\
    \n:foreach u in=[/ppp active find] do={\r\
    \n\r\
    \n  :local username [/ppp active get \$u name]\r\
    \n  :local ipaddr [/ppp active get \$u address]\r\
    \n  :local password \$username\r\
    \n\r\
    \n  :if (\$useGlobalPassword = true) do={\r\
    \n    :set password \$globalPassword\r\
    \n  }\r\
    \n\r\
    \n  :log info \"[AUTO-PPPoE] Checking \$username (\$ipaddr)\"\r\
    \n\r\
    \n  # Skip if already in /ppp secret\r\
    \n  :if ([/ppp secret find where name=\"\$username\"] != \"\") do={\r\
    \n    :log info \"[AUTO-PPPoE] \E2\9C\85 Already exists: \$username\"\r\
    \n  } else={\r\
    \n\r\
    \n    # Try to find matching queue\r\
    \n    :local qid [/queue simple find where name=\"<pppoe-\$username>\"]\r\
    \n    :if ([:len \$qid] = 0) do={\r\
    \n      :log warning \"[AUTO-PPPoE] \E2\9D\8C No queue for \$username\"\r\
    \n    } else={\r\
    \n\r\
    \n      :local limit [/queue simple get \$qid max-limit]\r\
    \n      :log info \"[AUTO-PPPoE] Max-limit = \$limit\"\r\
    \n\r\
    \n      # Search profiles by comment containing \$limit\r\
    \n      :local matchedProfile \"\"\r\
    \n      :foreach p in=[/ppp profile find] do={\r\
    \n\r\
    \n        :local comment [/ppp profile get \$p comment]\r\
    \n        :if (\$comment ~ \$limit) do={\r\
    \n          :set matchedProfile [/ppp profile get \$p name]\r\
    \n        }\r\
    \n      }\r\
    \n\r\
    \n      :if ([:len \$matchedProfile] > 0) do={\r\
    \n        :log info \"[AUTO-PPPoE] \E2\9C\85 Matched profile: \$matchedPro\
    file for \$limit\"\r\
    \n        /ppp secret add name=\$username password=\$password service=pppo\
    e profile=\$matchedProfile comment=\"JESYNC-AUTO-CREATED\" disabled=yes\r\
    \n        :log info \"[AUTO-PPPoE] \E2\9E\95 Added user \$username with pr\
    ofile \$matchedProfile\"\r\
    \n      } else={\r\
    \n        :log warning \"[AUTO-PPPoE] \E2\9D\8C No matching profile commen\
    t for \$limit\"\r\
    \n      }\r\
    \n    }\r\
    \n  }\r\
    \n}"
