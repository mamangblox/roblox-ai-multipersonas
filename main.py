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

PERSONAS = {
    "guard": {
        "name":"Penjaga Kota",
        "personality":"Tegas, suka menjaga keamanan kota, jawab singkat."
    },
    "merchant": {
        "name":"Pedagang",
        "personality":"Ramah, suka menawarkan barang."
    },
    "wizard": {
        "name":"Penyihir",
        "personality":"Bijak, misterius, suka bicara sihir."
    },
    "robot": {
        "name":"Robot AI",
        "personality":"Logis, futuristik, sedikit kaku."
    }
}

class RobloxMessage(BaseModel):
    user:str
    message:str
    persona:str="guard"

@app.get("/")
async def home():
    return {"status":"online","personas":list(PERSONAS.keys())}

@app.post("/webhook/roblox-ai")
async def webhook(data:RobloxMessage):

    persona_key = data.persona.lower()
    persona = PERSONAS.get(persona_key, PERSONAS["guard"])

    memory_key = f"{data.user}_{persona_key}"

    if memory_key not in chat_memory:
        chat_memory[memory_key] = []

    history = chat_memory[memory_key]

    prompt = f"""
Kamu NPC Roblox.

Nama NPC:
{persona["name"]}

Kepribadian:
{persona["personality"]}

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
        "player":data.message,
        "npc":reply
    })

    chat_memory[memory_key] = history[-10:]

    return {
        "reply":reply,
        "persona":persona["name"]
    }
