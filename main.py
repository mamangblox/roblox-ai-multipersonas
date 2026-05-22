import os
import logging
import google.generativeai as genai

from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("roblox-ai")

app = FastAPI()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
else:
    logger.warning("GEMINI_API_KEY is not set")

model = genai.GenerativeModel(GEMINI_MODEL)

chat_memory = {}


class RobloxMessage(BaseModel):
    user: str
    message: str
    npc_name: str
    display_name: str = "NPC"
    system_prompt: str = ""
    greeting: str = "Halo."


@app.get("/")
async def home():
    return {"status": "online"}


@app.post("/webhook/roblox-ai")
async def webhook(data: RobloxMessage):
    npc_name = data.npc_name or data.display_name or "NPC"
    display_name = data.display_name or npc_name
    greeting = data.greeting or "Halo."
    system_prompt = (data.system_prompt or "").strip()

    memory_key = f"{data.user}_{npc_name}"

    if memory_key not in chat_memory:
        chat_memory[memory_key] = []

    history = chat_memory[memory_key]

    prompt = f"""
Kamu NPC Roblox.

Nama NPC:
{display_name}

Instruksi NPC:
{system_prompt}

Salam awal:
{greeting}

Player:
{data.user}

Riwayat:
{history}

Pesan:
{data.message}

Aturan:
- Maksimal 2 kalimat
- Jangan terlalu panjang
- Tetap sesuai karakter
"""

    try:
        if not GEMINI_API_KEY:
            raise RuntimeError("GEMINI_API_KEY belum di-set di environment.")

        response = model.generate_content(prompt)
        reply = (response.text or "").strip()
        if not reply:
            raise RuntimeError("Gemini mengembalikan teks kosong.")

    except Exception as e:
        logger.exception("Gemini request failed")
        reply = f"Server AI sedang sibuk. ({e})"

    history.append({
        "player": data.message,
        "npc": reply,
    })

    chat_memory[memory_key] = history[-10:]

    return {
        "reply": reply,
        "npc_name": npc_name,
        "display_name": display_name,
    }
