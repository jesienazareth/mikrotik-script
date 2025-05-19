# MikroTik Auto Radius PPPoE User Add to Secrets Local Script

This MikroTik RouterOS script automatically creates **disabled** Radius PPPoE users in `/ppp secret` based on currently active PPPoE sessions. It matches dynamic queues and assigns profiles using bandwidth detection from `/queue simple`'s `max-limit`, aligned with LibreQoS shaping plans.

> ✅ Compatible with MikroTik RouterOS **v7.1+**
> ✅ Designed for **LibreQoS integration** via `updatecsv.py` sync
> ✅ Matches users by queue name → assigns proper bandwidth profile

---

## 📦 Features

- 🧠 Auto-detect active PPPoE users (`/ppp active`)
- 📶 Match user's dynamic simple queue (e.g. `pppoe-username`)
- 🔁 Extract exact `max-limit` (e.g. `20480k/20480k`)
- 🔎 Compare against profile `comment` to determine correct plan
- 🔐 Optional static global password (e.g. `pass123`)
- 📋 Adds user to `/ppp secret` as **disabled** (safe default)
- 🔄 Supports integration with **LibreQoS's `updatecsv.py`**

---

## 🔧 Prerequisites

### MikroTik PPPoE Profile Setup

Each PPPoE plan must have the exact `max-limit` string in its **`comment`** field:
This profile name is example only use your own profile names, no need to copy this profile names
this is only example that in the comment section required to add the format below, 
To ensure that each PPPoE user is assigned the correct bandwidth profile automatically,
you must define the exact max-limit string in the comment field of each PPP profile.
|--------------|-------------------------------|
| PLAN1000     | `20480k/20480k`               |
| PLAN1695     | `30720k/30720k`               |
| PLAN2000     | `40960k/40960k`               |
| Vendo        | `1k/1k`                       |

---

## ✅ How It Works

1. The script scans all active PPPoE sessions.
2. For each user:
   - It checks if they exist in `/ppp secret`.
   - If not, it reads their Simple Queue `max-limit`.
   - It then searches for a PPP profile with a **comment** that matches that exact `max-limit` string.
   - If a match is found, it creates the user in `/ppp secret` (disabled) using the matched profile.

---

## ⚠️ Profile Comment Requirement

Each PPP profile must have the exact bandwidth string (as used in `max-limit`) written in its **comment** field.

This is the only way to correctly identify and assign the right bandwidth plan.

### Example Profile Table

| **PPP Profile Name** | **Comment (Exact Bandwidth)** |
|----------------------|-------------------------------|
| PLAN1000             | `20480k/20480k`               |
| PLAN1695             | `30720k/30720k`               |
| PLAN2000             | `40960k/40960k`               |

> **Note:** The **profile name** can be anything you prefer.  
> What matters is the **exact match** of the `comment` to the user's queue bandwidth.

---

## 📦 Integration with LibreQoS / Jesync

- This script helps Jesync's `updatecsv.py` sync the correct users and bandwidth to `ShapedDevices.csv`.
- Users are added locally as disabled PPP secrets so Jesync can extract bandwidth data and sync it to LibreQoS.
- This ensures proper shaping and monitoring in Jesync + LibreQoS environments.

---

## ⚙️ Optional: Username = Password Toggle

Inside the script, you can control whether:
- Username and password are the same (default)
- Or define your own password logic

Modify this section in the script:
```routeros
# Set password same as username or define custom password logic
:local password $username

## 🛠 Installation Instructions

### 1. Create the Script

- Open **Winbox** or **WebFig**
- Go to: **System > Scripts**
- Create a new script:
  - **Name**: `Auto-PPPoE-User-Creation`
  - **Policy**: Enable `read`, `write`, `policy`, `test`
  - **Paste the script source code** from below

---

## 📜 Script Source Code

```rsc
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
        /ppp secret add name=$username password=$password service=pppoe profile=$matchedProfile comment="JESYNC-AUTO-CREATED" disabled=yes
        :log info "[AUTO-PPPoE] ➕ Added user $username with profile $matchedProfile"
      } else={
        :log warning "[AUTO-PPPoE] ❌ No matching profile comment for $limit"
      }
    }
  }
}
