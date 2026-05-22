Disini tempat informasi project

Persona chat:
- `guard`
- `merchant`
- `wizard`
- `robot`

Persona dan NPC diatur dari `ServerScriptService/NPCChatServer.legacy.luau`.
Tambahkan atau ubah entry di `NPC_CONFIG`, lalu pastikan nama key sama dengan nama Model NPC di Workspace.
Player cukup mendekati NPC lalu prompt akan muncul.
Backend Railway sekarang generik; memory chat dipisah per NPC lewat `npc_name` yang dikirim dari SSS.
