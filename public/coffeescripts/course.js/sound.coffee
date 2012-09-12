slide      = undefined
codeMirror = undefined
turtleDiv  = undefined

# Order matters!
tracks = [
  "evaluatedCode"
  "scrollPosition"
  "selectionRange"
  "scrollPosition"
  "bufferContents"
]

# So, what is a ''talk''? Basically, it's just a combination of a speech recording in
# mp3 or/and ogg format, and a corresponding recording of speaker's keyboard typing.
# Things get little complicated by the fact that one slide posses multiple
# tuples of speech/keyboard recording that are to be played consequently, "as one".

playTalk = (sl, mediaRoot, fullName) ->
  slide = sl
  
  unless slide.soundObjects?
    createSoundObjects slide, mediaRoot, fullName

  slide.activeSoundObjectI = -1
  slide.soundObject = ->
    this.soundObjects[this.activeSoundObjectI]
  playSound slide, 0

  pageDesign.addPlayer slide.div, pauseSound, seekSound

createSoundObjects = (slide, mediaRoot, fullName) ->
  slide.soundObjects = []
  
  for sound in slide.talk
    newSoundManager = soundManager.createSound
      id : sound.file
      url: mediaRoot + "/" + sound.file + ".mp3"
    slide.soundObjects.push newSoundManager

    ((sound, newSoundManager) -> 
      $.getJSON mediaRoot + "/" + sound.file + ".json", (recordingTracks) ->
        sound.tracks = recordingTracks
        for t in tracks
          addEventsToManager slide, t, recordingTracks[t], fullName, newSoundManager
    )(sound, newSoundManager)

addEventsToManager = (slide, trackName, track, fullName, soundObject) ->
  $.map track, (event) =>
    soundObject.onPosition event.time, ->
      playbook.playbook[trackName] event.value,
        codeMirror: codeMirror=slide.cm
        turtleDiv: turtleDiv=document.getElementById("#{fullName}#{slide.drawTo}")

playSound = (slide, ith) ->
  slide.activeSoundObjectI = ith
  if slide.activeSoundObjectI < slide.soundObjects.length
    slide.soundObject().play(
      whileplaying: updateSeekbar
      onfinish: -> playSound slide, ith+1
    )

pauseSound = (e) ->
  if slide.soundObject().paused
    slide.soundObject().play()
  else
    slide.soundObject().pause()

seekSound  = (e) ->
  xcord = e.pageX - slide.div.offset().left  # 22-420
  pos   = (xcord - 22) / 400 * slide.soundObject().duration
  slide.soundObject().setPosition pos
  
  for track in tracks
    for event in slide.talk[slide.activeSoundObjectI].tracks[track]
      if event.time < slide.soundObject().position
        theEvent = event
    continue unless theEvent?
    
    playbook.playbook[track] theEvent.value,
      codeMirror: codeMirror
      turtleDiv: turtleDiv
  
updateSeekbar = ->
  perc = slide.soundObject().position * 100 / slide.soundObject().duration
  slide.div.find(".inseek").width(perc + "%")

# Only visible slides should be able to play sounds.
stopSound = (slide) ->
  slide.soundObject().stop()


(exports ? this).sound =
  playTalk: playTalk
  stopSound: stopSound
