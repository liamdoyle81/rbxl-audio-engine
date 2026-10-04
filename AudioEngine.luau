-- Version 0.1.0 - 8/9/26

local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local AudioDeviceOutput = SoundService:WaitForChild("AudioDeviceOutput")
local AudioEngine = {}


-- FUNCTION: AUTO WIRE
-- wires the audio player through any effects and to the emitter
-- children of audio player must only be audio objects
function AudioEngine.autoWire(audioPlayer, is3DSound, emitter)
	-- get and number children
	local playerChildren = audioPlayer:GetChildren()
	local amountOfChildren = #playerChildren
	
	-- if 3d, wire to emitter, if 2d wire to audiodeviceoutput
	local function wireLastEffect(targetChain)
		-- link last wired effect to emitter
		local finalWire = Instance.new("Wire")
		finalWire.Name = "FinalWire"
		finalWire.Parent = audioPlayer
		finalWire.SourceInstance = targetChain
		if is3DSound then 
			finalWire.TargetInstance = emitter
		else
			finalWire.TargetInstance = AudioDeviceOutput
		end
	end


	-- if no AudioObjects just wire fader to emitter
	if amountOfChildren == 0 then 
		wireLastEffect(audioPlayer)
		return
	end

	-- create chain between audio player and all of its audio objects
	local sourceChain = audioPlayer
	local targetChain
	for index in playerChildren do
		local wire = Instance.new("Wire")
		wire.Parent = audioPlayer
		wire.SourceInstance = sourceChain
		sourceChain = playerChildren[index]

		targetChain = playerChildren[index]
		wire.TargetInstance = targetChain
	end
	wireLastEffect(targetChain)
end


-- FUNCTION: CREATE SOUND
-- create audio with specified audioEffect and parent
-- if autoWire is false, its expected you have already wired all sound objects through to emitter
function AudioEngine.createSound(sound, parent, tag, autoWire)
	if not sound or (sound.ClassName ~= "AudioPlayer") then
		error("sound doesnt exist or is not an audio player")
		return
	end
	-- if no audio fader provided route to default
	if tag == nil then 
		tag = "Default"
	end
	-- if no autowire peram set it to true
	if autoWire == nil then
		autoWire = true
	end
	-- figure out whether sound is 2d or 3d
	local is3DSound
	if parent == SoundService then 
		is3DSound = false
	else
		is3DSound = true
	end

	-- clone audio and wire it 
	local audioPlayer = sound:Clone()
	audioPlayer.Parent = SoundService
	-- add group tag and volume attribute to sound
	CollectionService:AddTag(audioPlayer, tag)
	audioPlayer:SetAttribute("OriginalVolume", audioPlayer.Volume)


	-- if premade emitter exists set its parent
	-- if not make default emitter
	local emitter
	if is3DSound then 
		emitter = audioPlayer:FindFirstChildOfClass("AudioEmitter")
		if emitter then 
			emitter.Parent = parent
		else
			emitter = Instance.new("AudioEmitter")
			emitter.Parent = parent

			-- set default distance to 100
			local curve = {}
			curve[0] = 1
			curve[50] = 0.5
			curve[100] = 0
			emitter:SetDistanceAttenuation(curve)
		end
		if autoWire then 
			AudioEngine.autoWire(audioPlayer, is3DSound, emitter)
		end
	else
		if autoWire then 
			AudioEngine.autoWire(audioPlayer, is3DSound)
		end
	end

	-- after emitter creation and effect wiring, play sound
	audioPlayer:Play()


	-- if audio is looped return its control to script, if not destroy it on ended
	if audioPlayer.Looping == true then
		-- allows you to destroy audio player and emitter even if looping
		return {audioPlayer, emitter}
	else
		-- cleanup emmiter and and audio player
		audioPlayer.Ended:Once(function()
			emitter:Destroy()
			audioPlayer:Destroy()
		end)
		return
	end
end


-- idea is you can do can change playing, volume, and whatever else in one function
--[[
function audioEngine.changeTagProperty(tag, property, value)
	for index, sound in CollectionService:GetTagged(tag) do
		sound[property] = value
	end
end
]]


-- FUNCTION: CHANGE VOLUME BY TAG
-- change volume of each sound with tag or change to original volume
function AudioEngine.controlAudioByTag(tag, volumeOrMethodInput)
	local sounds = CollectionService:GetTagged(tag)

	-- change each sound volume to original volume from attribute created in createSound
	if volumeOrMethodInput == "originalVolume" then
		for index, sound in sounds do
			local ogVolume = sound:GetAttribute("OriginalVolume")
			sound.Volume = ogVolume
		end
	-- if not og volume just change each volume to number given
	elseif volumeOrMethodInput == "Play" or volumeOrMethodInput == "Stop" then
		-- play or stop each sound
		for index, sound in sounds do
			sound[volumeOrMethodInput](sound)
		end
	else
		for index, sound in sounds do
			local ogVolume = sound:GetAttribute("OriginalVolume")
			sound.Volume = ogVolume * volumeOrMethodInput
			-- example:
			-- half of audio: 0.3 (og) * 0.5 (volume) = 0.15
			-- 0.3 * 2 = twice as loud
		end
	end
end


--[[
-- FUNCTION 4: PLAY OR STOP BY TAG
function audioEngine.playOrStop(tag, action)
	local sounds = CollectionService:GetTagged(tag)

	-- play or stop each sound
	for index, sound in sounds do
		sound[action](sound)
	end
end
]]


-- equivalent is audio version of key value
-- this is index dependent, if each property isnt correlated positionally it doesnt work
local soundToAudio = {
	["EchoSoundEffect"] = {
		equivalent = "AudioEcho",
		soundProperties = {"Delay",     "DryLevel", "Feedback", "WetLevel", "Enabled"},
		audioProperties = {"DelayTime", "DryLevel", "Feedback", "WetLevel", "Bypass"}
	},

	["ChorusSoundEffect"] = {
		equivalent = "AudioChorus",
		soundProperties = {"Depth", "Mix", "Rate", "Enabled"},
		audioProperties = {"Depth", "Mix", "Rate", "Bypass"}
	},

	["DistortionSoundEffect"] = {
		equivalent = "AudioDistortion",
		soundProperties = {"Level"},
		audioProperties = {"Level"}
	},

	["EqualizerSoundEffect"] = {
		equivalent = "AudioEqualizer",
		soundProperties = {"HighGain", "LowGain", "MidGain", "Enabled"},
		audioProperties = {"HighGain", "LowGain", "MidGain", "Bypass"}
	},

	["PitchShiftSoundEffect"] = {
		equivalent = "AudioPitchShifter",
		soundProperties = {"Octave", "Enabled"},
		audioProperties = {"Pitch",  "Bypass"}
	},

	["ReverbSoundEffect"] = {
		equivalent = "AudioReverb",
		soundProperties = {"DecayTime", "Density", "Diffusion", "DryLevel", "WetLevel", "Enabled"},
		audioProperties = {"DecayTime", "Density", "Diffusion", "DryLevel", "WetLevel", "Bypass"}
	}
}

-- FUNCTION: CONVERT SOUND TO AUDIO OBJECTS
function AudioEngine.convertSoundToAudio(sound)
	-- for recording each property of sound to apply to new audio player
	local soundProperties = {
		["Asset"] = sound.SoundId,
		["TimePosition"] = sound.TimePosition,
		["Looping"] = sound.Looped,
		["PlaybackSpeed"] = sound.PlaybackSpeed,
		["Volume"] = sound.Volume
	}

	-- if playback and loop regions exist then add them with their values to table
	if sound.PlaybackRegionsEnabled == true then 
		soundProperties["LoopRegion"] = sound.LoopRegion
		soundProperties["PlaybackRegion"] =  sound.PlaybackRegion
	end

	-- create audio player
	local audioPlayer = Instance.new("AudioPlayer")
	audioPlayer.Parent = sound.Parent
	audioPlayer.Name = sound.Name

	-- for every value recorded in soundProperties, apply its value to audio player
	local function applyPropertiesToAudioPlayer()
		for index, value in soundProperties do
			audioPlayer[index] = value
		end
	end

	-- create sound. if no children call function to add properties
	local soundChildren = sound:GetChildren()
	if #soundChildren == 0 then 
		applyPropertiesToAudioPlayer()
	else 
	-- else if children, for each child of sound that is a key in table, create the keys value and add child's properties to it
		for index, child in (soundChildren) do
			-- if child of sound exists in soundToAudio table, create its value (audio equivalent)
			if soundToAudio[child.ClassName] then
				local key = soundToAudio[child.ClassName]
				local soundPropertiesTbl = key.soundProperties
				local audioPropertiesTbl = key.audioProperties
				local audioEffect = Instance.new(key.equivalent)
				audioEffect.Parent = audioPlayer

				-- for every property in audio effect, make it equal to the sound effect property equivalent
				for index2, value in audioPropertiesTbl do
					-- if current effect is bypass set it to the opposite of what SoundEnabeled is
					-- since if Bypass is true, it disables the effect
					if audioPropertiesTbl[index2] == "Bypass" then
						audioEffect.Bypass = not child.Enabled 
						continue
					end

					audioEffect[audioPropertiesTbl[index2]] = child[soundPropertiesTbl[index2]] 
				end
			end
		end
		applyPropertiesToAudioPlayer()
	end
end

return AudioEngine
