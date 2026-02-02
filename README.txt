================================================================================
                              MyHub - Documentation
================================================================================

STRUCTURE DU PROJET
-------------------
MyHub/
├── loader.lua          # Point d'entree avec detection d'executor
├── main.lua            # Hub complet en un seul fichier (pret a l'emploi)
├── core/
│   └── init.lua        # Module central (gestion connections, loops, settings)
├── modules/
│   ├── esp.lua         # ESP complet avec Drawing API
│   ├── aimbot.lua      # Aimbot avec FOV, prediction, smoothing
│   ├── remotespy.lua   # Intercepteur de RemoteEvent/Function
│   └── movement.lua    # Fly, Noclip, Speed, Jump modifications
├── ui/
│   └── main.lua        # Integration Rayfield UI
└── games/              # Scripts specifiques par jeu (a remplir)


COMMENT UTILISER
----------------

Option 1: Fichier unique (recommande pour debuter)
- Heberge main.lua sur GitHub (raw)
- Execute: loadstring(game:HttpGet("URL_RAW"))()

Option 2: Architecture modulaire
- Heberge tous les fichiers sur GitHub
- Modifie BASE_URL dans loader.lua
- Execute: loadstring(game:HttpGet("URL_LOADER"))()


PATTERN loadstring + HttpGet EXPLIQUE
-------------------------------------

1. game:HttpGet(url)
   - Envoie une requete HTTP GET vers l'URL
   - Retourne le contenu du fichier comme string
   - Disponible uniquement via executor (pas Roblox Studio standard)

2. loadstring(code)
   - Compile la string en fonction Luau executable
   - Retourne: function (succes) ou nil, error (echec)

3. ()
   - Execute immediatement la fonction retournee

Flux: URL -> Fetch -> String -> Compile -> Execute


COMPATIBILITE MULTI-EXECUTOR
-----------------------------

Le hub detecte automatiquement:
- Seliware (v2.2.1+)
- Delta (v2.704+)
- Synapse X
- KRNL
- Fluxus
- Et autres via getexecutorname()

Fonctionnalites verifiees:
- hookmetamethod (pour silent aim, remote spy avance)
- hookfunction (pour hooks de fonctions)
- getrawmetatable (manipulation metatables)
- newcclosure (wrappers securises)
- getconnections (manipulation de signaux)
- Drawing (ESP avec Drawing API)
- writefile/readfile (sauvegarde config)


UI LIBRARIES ALTERNATIVES
--------------------------

Rayfield (utilise par defaut):
loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

Fluent:
loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

Linoria:
loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

Kavo UI:
loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()


PERSONNALISATION
----------------

1. Ajouter une nouvelle feature:
   - Cree un fichier dans modules/
   - Suit la structure: Init, Enable, Disable, Toggle, Unload
   - Ajoute les controles UI dans ui/main.lua

2. Support d'un nouveau jeu:
   - Cree games/nomjeu.lua
   - Detecte le jeu via game.PlaceId
   - Charge les features specifiques

3. Modifier les couleurs ESP:
   - ESP.Settings.Colors.Enemy = Color3.fromRGB(r, g, b)
   - Ou via le ColorPicker dans l'UI


BONNES PRATIQUES
----------------

1. Toujours utiliser pcall pour les operations risquees
2. Nettoyer les connections avec Hub:AddConnection()
3. Utiliser newcclosure() pour les hooks
4. Verifier la disponibilite des features avant utilisation
5. Sauvegarder les settings avec Hub:SaveSettings()


NOTES DE SECURITE
-----------------

- Ce hub est pour tests locaux et educatifs uniquement
- Ne pas utiliser sur des serveurs publics sans autorisation
- Les anti-cheat modernes peuvent detecter ces techniques
- Tester toujours en environnement controle d'abord


================================================================================
