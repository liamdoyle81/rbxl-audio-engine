# Roblox Audio Engine
V0.1.0
This module is currently a work in progress and is not complete. Use at your own risk, as bugs are to be expected. 

## What is rbxl-audio-engine?
* This is a module made for Roblox that utilizes their new Audio system released in 2024.
* It aims to make using audio-objects more automatic, eliminating the need to ever wire effects and change their wiring based on new effects being added or object paths being changed.



## Usage

### createSound
* Used to define what sound to be created (by providing an AudioPlayer), where its parent should be (either 2d or 3d space), what sound group it is in, and whether to automatically wire it or not
* **FORMAT:** createSound(sound [INSTANCE], parent [INSTANCE], tag [STRING], autoWire [BOOL])

example:  
`
Modules.AudioEngine.createSound(
	AudioFolder:WaitForChild("LobbyAmbient"),
	SoundService,
	"Lobby",
	true
)
`

### controlAudioByTag
* Used to control groups of audio players by the tag they are given. Any sounds not given a sound group are given the "Default" tag. You can provide an int to the function to change each audio's volume to that value, provide "Play" or "Stop" as a string to play or stop each audio, or provide "OriginalVolume" as a string to change each audio back to its original volume. 
* **FORMAT:** (tag [STRING], volumeOrMethodInput [INT OR STRING])

example:
`AudioEngine.controlAudioByTag("LobbySounds", "Stop")`

### convertSoundToAudio
* Used to convert legacy sound objects to new, modern audio objects
* **FORMAT:** convertSoundToAudio(sound []INSTANCE)

example:
`Modules.AudioEngine.createSound(game.ReplicatedStorage.Audio:WaitForChild("LobbyMusic"))`
