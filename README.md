Deploy Railway:
1. Upload project
2. Set GEMINI_API_KEY
3. Optional: set GEMINI_MODEL if you want to override the default model
4. Deploy

Persona:
guard
merchant
wizard
robot

Catatan:
- Jangan commit API key ke repo.
- Kalau response tetap "Server AI sedang sibuk", cek log Railway untuk pesan error aslinya.
- Folder `roblox-studio/` tidak ikut deploy ke Railway karena di-ignore lewat [`.railwayignore`](./.railwayignore), tapi tetap aman disimpan di GitHub.
- Multi NPC dan persona di Roblox Studio diatur dari [ServerScriptService/NPCChatServer.legacy.luau](./roblox-studio/ServerScriptService/NPCChatServer.legacy.luau). Player cukup mendekati NPC; prompt akan membuka dialog sesuai konfigurasi server script.
- Backend Railway sekarang generik: dia hanya menerima payload dari SSS dan membaca `system_prompt` mentah dari setiap NPC.
- Riwayat chat dipisah per NPC lewat `npc_name`, jadi dua NPC tetap punya memory sendiri walau isi `system_prompt` mirip.
