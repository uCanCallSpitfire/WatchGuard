# 🛡️ PyWatchGuard

**PyWatchGuard** is an intelligent Python bot that monitors, logs, and remotely manages your system via **Telegram**.  
It tracks network connectivity, system performance, and temperature, performs scheduled log rotation, and can reboot the device when needed — all through Telegram commands.

---

## 🚀 Features

- 🌐 **Internet Monitoring** — Automatically detects and reports connectivity status.  
- 🧠 **System Overview** — Shows RAM, disk, CPU, temperature, and IP info.  
- 🗂️ **Smart Log Rotation** — Automatically rotates and stores logs daily.  
- ⚡ **Remote Commands** — Execute shell commands directly via Telegram.  
- 🔄 **Reboot Functionality** — Reboot your device remotely.  
- 📊 **Speed Test Integration** — Checks network performance using Speedtest CLI.  
- 🕒 **Daily Log Rotation** — Automatically rotates logs at 21:00 and keeps history.  

---

## ⚙️ Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/PyWatchGuard.git
   cd PyWatchGuard


Install dependencies

pip install -r requirements.txt


Edit your Telegram credentials

Open the main .py file

Replace:

TOKEN = 'YOUR_TOKEN_HERE'
CHAT_ID = 123456789


(Optional) Install Speedtest CLI
 for speed testing:

sudo apt install speedtest-cli


Run the bot

python3 pywatchguard.py

💬 Telegram Commands
Command	Description
/check	Checks if the device is active
/status	Shows IP and speed test result
/details	Detailed system info (CPU, RAM, disk, temp, etc.)
/speedtest	Runs a quick internet speed test
/reboot	Restarts the device remotely
/command <cmd>	Executes a shell command
/log	Sends log files
🧩 Example Output
📟 Device: raspberrypi
🌐 IP: 192.168.1.15
🧠 CPU: ARM Cortex-A53
💾 RAM: 512/1024 MB (50%)
🗂️ Disk: 6/16 GB
🌡️ Temp: 48.5°C
🚀 Speedtest: 35 Mbps down / 10 Mbps up

🧠 Notes

PyWatchGuard runs best on Linux, Raspberry Pi, or Windows systems.

All logs are stored and rotated automatically (bot_log.txt, bot_log_1.txt, etc.).

Telegram communication ensures secure and convenient remote control.

Use responsibly — designed for system administration and monitoring only.

📄 License

This project is released under the MIT License.
You are free to use, modify, and distribute it with attribution.

PyWatchGuard — Your lightweight, personal system watchdog.
