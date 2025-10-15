# 📘 Jesync Pro Hotspot Voucher Integration Guide

## 🧩 Overview
This guide explains how to integrate **Jesync Pro Voucher Store** into your **MikroTik Hotspot login portal**, allowing users to purchase vouchers through **GCash**, **Maya**, or **Xendit**, and automatically log in after payment.

This setup ensures that the payment page, assets, and Jesync dashboard remain **accessible even before authentication** using **MikroTik Walled Garden rules**.

---

## ⚙️ Step 1: Add Jesync Voucher Button and Auto-Login Script
Paste the following section **into your Hotspot `login.html`**, ideally **below your existing login form**.

```html code below

<!-- Start Jesync Pro Voucher Store Integration -->
<div class="text-center mt-3">
  <a href="http://172.16.0.114:5000/voucher-store"
     class="btn btn-warning btn-block"
     style="font-weight:600; letter-spacing:.2px;">
    💳 Buy Voucher GCASH | MAYA
  </a>
</div>

<script>
(function () {
  // Retrieve voucher or username parameter
  function getParam(name) {
    var url = window.location.href;
    name = name.replace(/[[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return "";
    return decodeURIComponent(results[2].replace(/\+/g, " "));
  }

  var voucher = getParam("username") || getParam("voucher") || getParam("v");
  var ALREADY_TRIED_KEY = "mk_auto_login_tried";
  var alreadyTried = sessionStorage.getItem(ALREADY_TRIED_KEY) === "1";

  if (voucher && !alreadyTried) {
    var form = document.forms["login"];
    var userInput =
      (form && (form.elements["username"] || document.getElementById("voucherInput"))) || null;
    var passInput =
      (form && (form.elements["password"] || document.getElementById("passwordInput"))) || null;

    if (form && userInput) {
      userInput.value = voucher;
      if (passInput) passInput.value = "";
      sessionStorage.setItem(ALREADY_TRIED_KEY, "1");

      setTimeout(function () {
        try {
          form.submit();
        } catch (e) {
          userInput.focus();
        }
      }, 150);
    }
  }
})();
</script>
<!-- END OF JESYNC PRO VOUCHER BUTTON -->
```

💡 **Tip:**  
If your portal uses a custom voucher field ID (e.g. `voucherCode`), replace the input selectors in the script accordingly.

---

## 🌐 Step 2: Configure MikroTik Walled Garden Rules

Paste the following into your **MikroTik terminal** to whitelist the Jesync portal and payment providers.

```bash
/ip hotspot walled-garden
add comment="Jesync Pro Style CDN Rules" disabled=yes
add comment=style dst-host=cdn.jsdelivr.net
add comment=style dst-host=fonts.googleapis.com
add comment=style dst-host=fonts.gstatic.com
add comment=style dst-host=use.fontawesome.com
add comment=style dst-host=cdnjs.cloudflare.com
add comment=style dst-host=cdn.jsdelivr.net
add comment=style dst-host="fonts.googleapis.com"
add comment=style dst-host="fonts.gstatic.com"

/ip hotspot walled-garden ip
add action=accept comment="Jesync Pro Voucher Store" disabled=no dst-address=172.16.100.4
add action=accept comment=payments.gcash.com disabled=no dst-host=payments.gcash.com
add action=accept comment=gcash-api.pulseid.com disabled=no dst-host=gcash-api.pulseid.com
add action=accept comment=beacons.gcp.gvt2.com disabled=no dst-host=beacons.gcp.gvt2.com
add action=accept comment=irisk-sea.alipay.com disabled=no dst-host=irisk-sea.alipay.com
add action=accept comment=mss.paas.mynt.xyz disabled=no dst-host=mss.paas.mynt.xyz
add action=accept comment=api.mynt.xyz disabled=no dst-host=api.mynt.xyz
add action=accept comment=login.mynt.xyz disabled=no dst-host=login.mynt.xyz
add action=accept comment=customer-segment-api.mynt.xyz disabled=no dst-host=customer-segment-api.mynt.xyz
add action=accept comment=gw.alipayobjects.com disabled=no dst-host=gw.alipayobjects.com
add action=accept comment=mdap.paas.mynt.xyz disabled=no dst-host=mdap.paas.mynt.xyz
add action=accept comment=mgs-gw.paas.mynt.xyz disabled=no dst-host=mgs-gw.paas.mynt.xyz
add action=accept comment=checkout.xendit.co disabled=no dst-host=checkout.xendit.co
add action=accept comment=checkout-ui-gateway.xendit.co disabled=no dst-host=checkout-ui-gateway.xendit.co
add action=accept comment=assets.xendit.co disabled=no dst-host=assets.xendit.co
add action=accept comment=api.xendit.co disabled=no dst-host=api.xendit.co
add action=accept comment=xqd9eal.x.incapdns.net disabled=no dst-host=xqd9eal.x.incapdns.net
add action=accept comment=45.60.160.35 disabled=no dst-host=45.60.160.35
add action=accept comment=xnd-merchant-logos.s3.amazonaws.com disabled=no dst-host=xnd-merchant-logos.s3.amazonaws.com
add action=accept comment=110.75.232.97 disabled=no dst-host=110.75.232.97
add action=accept comment=110.75.232.98 disabled=no dst-host=110.75.232.98
add action=accept comment=110.75.232.99 disabled=no dst-host=110.75.232.99
add action=accept comment=110.75.232.100 disabled=no dst-host=110.75.232.100
add action=accept comment=xen.to disabled=no dst-host=xen.to
add action=accept comment=18.138.78.193 disabled=no dst-host=18.138.78.193
add action=accept comment=3.0.107.195 disabled=no dst-host=3.0.107.195
add action=accept comment=3.1.78.74 disabled=no dst-host=3.1.78.74
add action=accept comment=traefik-public.ap-southeast-1.tidnex.com disabled=no dst-host=traefik-public.ap-southeast-1.tidnex.com
add action=accept comment=e9816.cj.akamaiedge.net disabled=no dst-host=e9816.cj.akamaiedge.net
add action=accept comment=104.67.185.229 disabled=no dst-host=104.67.185.229
add action=accept comment=payments.paymaya.com disabled=no dst-host=payments.paymaya.com
add action=accept comment="jesync-pro (voucher store)" disabled=no dst-address=172.16.100.4
add action=accept comment=hotspot-gateway disabled=no dst-address=10.0.0.1
add action=accept disabled=no dst-address=172.16.100.4
add action=accept comment=jesync-pro disabled=no dst-address=172.16.100.4
```

🧠 **Notes:**
- Replace `172.16.0.114` (voucher store) and `172.16.100.4` (Jesync server) with your actual **Jesync dashboard IP**.
- These rules ensure that:
  - The **voucher store**, **payment gateways**, and **font/CDN resources** load even before login.
  - The hotspot login page remains responsive and visually styled.

---

## ✅ Step 3: Testing Checklist
After setup, verify the following:

| Test | Expected Result |
|------|------------------|
| Open Hotspot Portal | Login page loads fully (styles, buttons visible) |
| Click “Buy Voucher” | Jesync Voucher Store opens without authentication |
| Pay via GCash/Maya | Payment completes successfully |
| Redirect after payment | Voucher auto-fills and logs in automatically |
| Refresh Portal | Does not auto-submit repeatedly (sessionStorage check works) |

---

## 🔍 Troubleshooting
- **Button not visible:** Ensure you placed the `<div>` inside the correct HTML section of `login.html`.
- **Auto-login not triggering:** Confirm that the redirect URL includes a `username` or `voucher` query parameter (e.g. `?username=ABC123`).
- **Payment page blocked:** Check `/ip hotspot walled-garden print` and verify that all required domains are added and not disabled.

---

## 💡 Recommendations
- Keep Jesync Dashboard IP static or DNS-mapped.
- Use SSL/TLS (`https://`) for production voucher portals.
- Test on **mobile captive portals** (iOS CNA, Android) to ensure auto-submission behaves correctly.
- Periodically review Xendit and GCash domain changes and update your walled-garden rules.

---

## 🏁 Credits
Developed for **Jesync Pro Unified ISP System**  
© 2025 JNHL IT Solutions
Integration and documentation by **Jesync Engineering Team**
