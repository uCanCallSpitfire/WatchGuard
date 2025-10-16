
import requests, socket, time, os, subprocess, psutil, shutil, logging, datetime, platform, hashlib, threading, asyncio
from logging.handlers import TimedRotatingFileHandler
from datetime import datetime


TOKEN = 'YOUR_TOKEN_HERE'
CHAT_ID = 111111111


# Formatter and handler settings for logs
log_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')

log_handler = TimedRotatingFileHandler(
    filename="bot_log.txt",  # Main log file
    when="midnight",         # Rotates every midnight
    interval=1,              # Every 1 day
    backupCount=3,           # Keep up to 3 old logs
    encoding='utf-8'
)

log_handler.setFormatter(log_formatter)
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(log_handler)


# Function to rotate log files and rename as bot_log_1.txt, bot_log_2.txt, etc.
def rotate_log_file():
    log_handler.doRollover()

    # Find existing rotated logs
    log_files = sorted([f for f in os.listdir('.') if f.startswith('bot_log_') and f.endswith('.txt')])

    # Rename old logs up to 3 files
    for i in range(len(log_files), 3):
        old_log_name = f"bot_log_{i + 1}.txt"
        if os.path.exists(old_log_name):
            os.rename(old_log_name, f"bot_log_{i + 2}.txt")

    # Rename current log as bot_log_1.txt
    os.rename("bot_log.txt", "bot_log_1.txt")

    # Save last rotation time
    last_rotation_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open("last_rotated.txt", "w") as file:
        file.write(last_rotation_time)


# Check and rotate logs at 21:00
def check_and_rotate_log():
    try:
        if os.path.exists("last_rotated.txt"):
            with open("last_rotated.txt", "r") as file:
                last_rotation_time = file.read().strip()
                last_rotation_time = datetime.strptime(last_rotation_time, "%Y-%m-%d %H:%M:%S")
        else:
            last_rotation_time = datetime.now() - datetime.timedelta(days=1)

        today_9pm = datetime.now().replace(hour=21, minute=0, second=0, microsecond=0)

        if last_rotation_time < today_9pm and datetime.now() >= today_9pm:
            rotate_log_file()
            logger.info("Log file rotated at 21:00.")
    except Exception as e:
        logger.error(f"Error during log rotation: {str(e)}")


check_and_rotate_log()

# Bot startup
logger.info("🟢 Bot started.")


def internet_available(host="8.8.8.8", port=53, timeout=3):
    try:
        socket.setdefaulttimeout(timeout)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
        logger.info("Internet connection successful.")
        return True
    except Exception:
        return False


while not internet_available():
    print("No internet connection. Retrying in 30 seconds...")
    logger.warning("Internet connection failed, retrying...")
    time.sleep(30)


import telegram, platform
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes
from telegram import Update


bot = telegram.Bot(token=TOKEN)


def send_telegram_message(message):
    url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
    data = {'chat_id': CHAT_ID, 'text': message}
    response = requests.post(url, data=data)
    if response.status_code == 200:
        logger.info(f"Telegram message sent: {message}")
    else:
        print("Failed to send message:", response.text)
        logger.error(f"Telegram message failed: {response.text}")


def get_ip():
    try:
        ip = requests.get("https://api.ipify.org", timeout=5).text
        logger.info(f"IP obtained: {str(ip)}")
        return ip
    except Exception as e:
        logger.error(f"Failed to get IP: {str(e)}")
        return "IP unavailable"


def get_system_temperature():
    try:
        temps = psutil.sensors_temperatures()
        if not temps:
            return 0
        for name, entries in temps.items():
            for entry in entries:
                if entry.current is not None:
                    return round(entry.current, 1)
        return 0
    except Exception:
        return 0


async def restart_device(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        device_name = platform.node().lower()
        input_name = ' '.join(context.args).lower() if context.args else device_name
        if input_name != device_name:
            return
        await update.message.reply_text(f"{device_name} is restarting...")
        logger.info("Reboot requested, restarting now.")
        os.system("reboot")
    except Exception as e:
        await update.message.reply_text(f"Error: {str(e)}")
        logger.error(f"Reboot failed: {str(e)}")


async def measure_internet_speed(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        device_name = platform.node().lower()
        input_name = ' '.join(context.args).lower() if context.args else device_name
        if input_name != device_name:
            return
        await update.message.reply_text("⏳ Running speed test...")
        result = subprocess.run(["speedtest", "--simple"], capture_output=True, text=True, shell=True)
        if result.returncode == 0:
            output = result.stdout.strip()
            device_label = ' '.join(context.args) if context.args else "Device"
            await update.message.reply_text(f"📶 {device_label} connection quality:\n{output}")
            logger.info(f"Speedtest result: {str(output)}")
        else:
            await update.message.reply_text("❌ Speedtest failed. Is Speedtest CLI installed?")
    except Exception as e:
        await update.message.reply_text(f"❌ Error: {str(e)}")
        logger.error(f"Speedtest error: {str(e)}")


async def status(update, context):
    try:
        device_name = platform.node().lower()
        input_name = ' '.join(context.args).lower() if context.args else device_name
        if input_name != device_name:
            return
        ip = get_ip()
        await update.message.reply_text("⏳ Running speed test...")
        result = subprocess.run(["speedtest", "--simple"], capture_output=True, text=True, shell=True)
        speed = result.stdout.strip() if result.returncode == 0 else "⚠️ Speedtest failed."
        await update.message.reply_text(
            f"📟 Device: {device_name}\n🌐 IP Address: {ip}\n🚀 Speedtest:\n{speed}")
        logger.info(f"Status result: Device: {device_name} IP: {ip} Speed: {speed}")
    except Exception as e:
        await update.message.reply_text(f"Error: {str(e)}")
        logger.error(f"Status command failed: {str(e)}")


async def detailed_status(update, context):
    try:
        device_name = platform.node().lower()
        input_name = ' '.join(context.args).lower() if context.args else device_name
        if input_name != device_name:
            return
        ip = get_ip()
        result = subprocess.run(["speedtest", "--simple"], capture_output=True, text=True, shell=True)
        total, used, free = shutil.disk_usage("/")
        ram = psutil.virtual_memory()
        total_ram = ram.total // (1024 ** 2)
        used_ram = ram.used // (1024 ** 2)
        ram_percent = int((used_ram / total_ram) * 100)
        disk_total = int(total / (1024 ** 3))
        disk_used = int(used / (1024 ** 3))
        temp = get_system_temperature()
        await update.message.reply_text(
            f"📟 Device: {device_name}\n🧠 CPU: {platform.processor()}\n💻 OS: {platform.platform()}\n🌡️ Temp: {temp} °C\n🌐 IP: {ip}\n💾 RAM: {used_ram}/{total_ram} MB (%{ram_percent})\n🗂️ Disk: {disk_used}/{disk_total} GB\n🚀 Speedtest: {result.stdout if result.returncode == 0 else 'Speedtest failed.'}")
        logger.info("Detailed status sent successfully.")
    except Exception as e:
        await update.message.reply_text(f"Error: {str(e)}")
        logger.error(f"Detailed status failed: {str(e)}")
        while not internet_available():
            time.sleep(10)
            logger.error("No internet connection. Retrying...")
        await update.message.reply_text("Internet connection restored!")
        logger.info("Internet reconnected.")


async def check(update, context):
    try:
        device_name = platform.node().lower()
        input_name = ' '.join(context.args).lower() if context.args else device_name
        if input_name != device_name:
            return
        await update.message.reply_text(f"📟 {device_name} is active")
        logger.info(f"Check command response: {device_name} active")
    except Exception as e:
        await update.message.reply_text(f"Error: {str(e)}")
        logger.error(f"Check command failed: {str(e)}")


async def send_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        device_name = platform.node().lower()
        input_name = ' '.join(context.args).lower() if context.args else device_name
        command = ' '.join(context.args[1:])

        if not command:
            await update.message.reply_text("Please enter a command.")
            return

        process = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        stdout, stderr = await process.communicate()

        if stdout:
            await update.message.reply_text(f"Output:\n{stdout.decode()}")
        if stderr:
            await update.message.reply_text(f"Error:\n{stderr.decode()}")

        await update.message.reply_text(f"📟 {device_name} active")
        logger.info(f"Command executed on {device_name}")
    except Exception as e:
        await update.message.reply_text(f"Error: {str(e)}")
        logger.error(f"Command execution failed: {str(e)}")


async def send_log(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        device_name = platform.node().lower()
        input_name = ' '.join(context.args).lower() if context.args else device_name
        if input_name != device_name:
            return

        log_files = []

        if 'all' in context.args:
            for f in os.listdir('.'):
                if f.endswith('.txt') and f.startswith('bot_log'):
                    log_files.append(f)
        elif context.args:
            for arg in context.args:
                if arg.isdigit():
                    fname = f"bot_log_{arg}.txt"
                    if os.path.exists(fname):
                        log_files.append(fname)
        else:
            if os.path.exists("bot_log.txt"):
                log_files.append("bot_log.txt")
            for i in range(1, 4):
                fname = f"bot_log_{i}.txt"
                if os.path.exists(fname):
                    log_files.append(fname)

        if not log_files:
            await update.message.reply_text("No log files found.")
            logger.error("No log files found.")
            return

        for log_file in sorted(log_files):
            with open(log_file, "rb") as f:
                await update.message.reply_document(document=f)
                logger.info(f"Log file sent: {log_file}")

    except Exception as e:
        await update.message.reply_text(f"Error: {e}")
        logger.error(f"Error sending log file: {e}")


def main():
    app = ApplicationBuilder().token(TOKEN).build()
    app.add_handler(CommandHandler("status", status))
    app.add_handler(CommandHandler("reboot", restart_device))
    app.add_handler(CommandHandler("speedtest", measure_internet_speed))
    app.add_handler(CommandHandler("details", detailed_status))
    app.add_handler(CommandHandler("check", check))
    app.add_handler(CommandHandler("log", send_log))
    app.add_handler(CommandHandler("command", send_command))
    app.run_polling()


if __name__ == '__main__':
    while not internet_available():
        print("No internet connection. Retrying in 30 seconds...")
        logger.warning("Internet connection failed, retrying...")
        time.sleep(30)

    try:
        send_telegram_message(f"📟 {platform.node()} is awake")
        logger.info(f"{platform.node()} is awake")
    except Exception as e:
        logger.error(f"Startup message failed: {str(e)}")

    try:
        main()
    except Exception as e:
        logger.error(f"Error during startup: {e}")


