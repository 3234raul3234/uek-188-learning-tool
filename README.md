# UEK 188 Learning Tool

> 🚧 **Beta version:** this tool is still being developed. There may be bugs, and tasks may still change. Please report problems or ideas under [Issues](https://github.com/3234raul3234/uek-188-learning-tool/issues/new/choose) (you need a free GitHub account). What's new is in the [Changelog](CHANGELOG.md).

A practice program for the Swiss ICT course **UEK 188** (operate, maintain and monitor services).
You get a Windows VM with **15 tasks**. The program tells you immediately whether you solved them correctly.

---

## What your computer needs
- Windows 10 or 11, at least **16 GB RAM** (the VM gets 8 GB) and about **40 GB of free space on drive C:**
- Virtualisation enabled (already the case on most computers)
- Internet for the downloads

## Install (3 steps)

**1. Install VMware**
**VMware Workstation Pro** is free. To download it you need a free **Broadcom account**:
1. Create an account at https://support.broadcom.com and sign in (on the first download you have to accept the terms and enter your address)
2. At the top open **My Downloads** → **Free Software Downloads**
3. **VMware Workstation Pro** → **for Windows** → download and install the latest version (17.5, 25H2 or newer)
4. Open VMware once yourself and confirm **personal use**

More info: https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion

**2. Download Windows 11**
Open https://www.microsoft.com/software-download/windows11. Under **"Download Windows 11 Disk Image (ISO)"** choose **"Windows 11 (multi-edition ISO for x64 devices)"** and **any language**. Then download the ISO file (about 7 GB).
**Do not delete the ISO afterwards**: the VM needs it, and so does rebuilding.

**3. Start this tool**
- Click the green **Code** button at the top and then **Download ZIP**
- ⚠️ **Extract it first:** right-click the ZIP file → *Extract All*
- In the **extracted** folder, double-click **`START.cmd`**. (Windows often puts two folders with the same name inside each other: `START.cmd` is in the **inner** folder.) If Windows warns you, click *More info* → *Run anyway*
- Choose the Windows ISO from step 2 (the window may open behind the black console window)

**Done.** The tool copies itself to `C:\UEK188` (you can delete the extracted folder afterwards) and builds the VM. Windows now installs itself. Wait about **30 minutes** and don't click anything in the meantime. After the automatic restart, the logon screen appears.

**Open the VM again later:** start VMware → **File → Open** → `C:\UEK188\VM\UEK188-Win11Edu.vmx` → **Power on**.

---

## Use

1. Sign in to the VM. User: **Administrator**, password: **Lab188-uek**
2. Double-click **Lab Trainer UEK 188** on the desktop
3. Choose a task on the left and then:
   **Start lab** → **Open folder** → solve the task → **Check**

Green means correct, red means wrong, and below red there is a hint.
Everything you need to know for the tasks (network, users, shares) is in the VM under `C:\UEK188\Unterlagen`.

Extra buttons:
- **Create doc**: writes a text for your documentation
- **Quiz**: tests your theory knowledge
- **Update**: gets the latest version of the tasks

**Tip:** take a snapshot right after the installation: in VMware **VM → Snapshot → Take Snapshot**, name `Fresh`. That way you can reset the VM to fresh at any time.

**On your computer** (not in the VM) there is the shortcut **Lab Trainer UEK 188 (PC)**. It is only for two extra buttons; you solve the labs in the VM:
- **Update VM**: brings new tasks into the running VM (click **Update** first, then **Update VM**)
- **Reset VM**: resets the VM to the snapshot `Fresh` (if there is none yet, the button creates it)

---

## Good to know

- Windows is **not activated**, a watermark appears at the bottom right. Everything works for practising. To activate it you need your own licence.
- The password is only for this VM. Don't use it anywhere else.
- The keyboard in the VM is set to **Swiss German**. You can change it in Windows under *Settings → Time & language → Language & region*.
- Broke something? Reset the snapshot or run `C:\UEK188\START.cmd` and let it rebuild the VM.

## Licence

You may **use** the tool to learn. **Passing on copies, republishing and selling are not allowed.** Details are in [LICENSE](LICENSE).
