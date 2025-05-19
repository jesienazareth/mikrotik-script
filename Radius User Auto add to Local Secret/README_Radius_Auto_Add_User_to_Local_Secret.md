# MikroTik Auto PPPoE User Creator Script

This MikroTik RouterOS script automatically creates **disabled** PPPoE users in `/ppp secret` based on currently active PPPoE sessions. It matches dynamic queues and assigns profiles using bandwidth detection from `/queue simple`'s `max-limit`, aligned with LibreQoS shaping plans.

> ✅ Compatible with MikroTik RouterOS **v7.1+**
> ✅ Designed for **LibreQoS integration** via `updatecsv.py` sync
> ✅ Matches users by queue name → assigns proper bandwidth profile

---

## 📦 Features

- 🧠 Auto-detect active PPPoE users (`/ppp active`)
- 📶 Match user's dynamic simple queue (e.g. `pppoe-username`)
- 🔁 Extract exact `max-limit` (e.g. `20480k/20480k`)
- 🔎 Compare against profile `comment` to determine correct plan
- 💡 Optional static global password (e.g. `pass123`)
- 📋 Adds user to `/ppp secret` as **disabled** (safe default)
- 🔄 Supports integration with **LibreQoS's `updatecsv.py`**

---

## 🔧 Prerequisites

### MikroTik Profile Setup (Required):

For this script to match correctly, each profile must include the target bandwidth string in the **`comment`** field.

| Profile Name | Comment (Required Format)      |
|--------------|-------------------------------|
| PLAN1000     | `20480k/20480k`               |
| PLAN1695     | `30720k/30720k`               |
| PLAN2000     | `40960k/40960k`               |
| Vendo        | `1k/1k`                       |

> The `comment` must match exactly what `max-limit` shows in dynamic queues.

---

## 🔧 Script Installation

### 1. Open Winbox or WebFig

- Go to: **System > Scripts**
- Create a **new script**
  - **Name:** `Auto-PPPoE-User-Creation`
  - **Policy:** Enable `read`, `write`, `policy`, `test`
  - **Paste the script below into the source**

---

## 📜 Script (Final Version)

```rsc
:local useGlobalPassword true
:local globalPassword "pass123"

:foreach u in=[/ppp active find] do={

  :local username [/ppp active get $u name]
  :local ipaddr [/ppp active get $u address]
  :local password $username

  :if ($useGlobalPassword = true) do={
    :set password $globalPassword
  }

  :log info "[AUTO-PPPoE] Checking $username ($ipaddr)"

  :if ([/ppp secret find where name="$username"] != "") do={
    :log info "[AUTO-PPPoE] ✅ Already exists: $username"
  } else={

    :local qid [/queue simple find where name="<pppoe-$username>"]
    :if ([:len $qid] = 0) do={
      :log warning "[AUTO-PPPoE] ❌ No queue for $username"
    } else={

      :local limit [/queue simple get $qid max-limit]
      :log info "[AUTO-PPPoE] Max-limit = $limit"

      :local matchedProfile ""
      :foreach p in=[/ppp profile find] do={

        :local comment [/ppp profile get $p comment]
        :if ($comment ~ $limit) do={
          :set matchedProfile [/ppp profile get $p name]
        }
      }

      :if ([:len $matchedProfile] > 0) do={
        :log info "[AUTO-PPPoE] ✅ Matched profile: $matchedProfile for $limit"
        /ppp secret add name=$username password=$password service=pppoe profile=$matchedProfile comment="AUTO-CREATED" disabled=yes
        :log info "[AUTO-PPPoE] ➕ Added $username with profile $matchedProfile"
      } else={
        :log warning "[AUTO-PPPoE] ❌ No matching profile comment for $limit"
      }
    }
  }
}
