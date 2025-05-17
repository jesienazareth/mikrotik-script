
# MikroTik Auto PPPoE User Creation Script

## 📜 Overview
This script automates the following tasks on MikroTik RouterOS v7+:
- Automatically checks active PPPoE sessions.
- Verifies if the user already exists in `/ppp secret`.
- If missing, creates a disabled PPPoE user and assigns the correct profile based on their bandwidth from `queue simple`.
- Adds or updates the corresponding `simple queue`.
- Uses a centralized `ProfileBandwidth` script for bandwidth-plan mapping.

## 🔧 What it does
1. **Creates two scripts inside MikroTik:**
   - `ProfileBandwidth`: Defines bandwidth to plan name.
   - `Auto-PPPoE-User-Creation`: Runs the user detection and creation logic.

2. **Adds a scheduler that runs the `Auto-PPPoE-User-Creation` script every 6 hours**, starting at system startup.

---

## 🚀 How to Install

### Step 1: Open Winbox or Terminal
- Login to your MikroTik router.
- Open **Terminal** window.

### Step 2: Paste the provided script
- Paste the entire provided batch script (see `Installer Script` above).
- Press **Enter**.

This will:
- Add/replace `ProfileBandwidth`.
- Add/replace `Auto-PPPoE-User-Creation`.
- Set the scheduler.

---

## 📅 How It Works (Logic Flow)
1. The script runs every **6 hours** via scheduler.
2. It reads active PPPoE users from `/ppp active`.
3. For each user:
   - Checks if they already exist in `/ppp secret`.
   - If not:
     - Creates a matching `simple queue` if missing.
     - Parses bandwidth from the queue.
     - Matches it against the `ProfileBandwidth` script.
     - Cross-checks for the correct PPP profile.
     - Adds the user as **disabled** with the matched profile.
4. Logs all actions to `/log`.

---

## ✅ Notes
- You can edit your bandwidth plans in the script `ProfileBandwidth`.
- Make sure your `/ppp profile` names exactly match the plans in `ProfileBandwidth` (no spaces, no extra characters).
- Scheduler will auto-run, but you can trigger manually:
```
/system script run Auto-PPPoE-User-Creation
```

## 🔗 Manual Triggers & Logs
- To view logs:
```
/log print where message~"[AUTO-PPPOE]"
```
- To manually run:
```
/system script run Auto-PPPoE-User-Creation
```
- To check scheduler:
```
/system scheduler print
```

---

## 📎 Important:
Always check your `ProfileBandwidth` format:
```
PLAN1000=20480k/20480k 20M/20M
PLAN1695=30720k/30720k 30M/30M
PLAN2000=40960k/40960k 40M/40M
Vendo=1k/1k
```

---

