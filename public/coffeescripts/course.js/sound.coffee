slide      = undefined
codeMirror = undefined
callback   = undefined
evaluationMode    = undefined
evaluationContext = undefined

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

playTalk = (sl, mediaRoot, evalContext, clbk) ->
  slide = sl
  callback = clbk
  evaluationContext = evalContext

  unless slide.soundObjects?
    createSoundObjects slide, mediaRoot

  slide.activeSoundObjectI = -1
  slide.soundObject = ->
    this.soundObjects[this.activeSoundObjectI]
  playSound slide, 0, 0

  pageDesign.addPlayer slide.div, pauseSound, seekSound

  for i in [1...slide.soundObjects.length]
    slide.soundObjects[i].load()

createSoundObjects = (slide, mediaRoot) ->
  slide.soundObjects = []

  for sound in slide.talk
    soundFile = sound.file ? "noise"
    keyboardFile = sound.keyboard ? sound.file

    newSoundManager = soundManager.createSound
      id : sound.file
      url: mediaRoot + "/" + soundFile + ".mp3"
    slide.soundObjects.push newSoundManager

    do (sound, newSoundManager) ->
      $.getJSON mediaRoot + "/" + keyboardFile + ".json", (recordingTracks) ->
        sound.tracks = recordingTracks
        for t in tracks
          addEventsToManager slide, t, recordingTracks[t], newSoundManager

addEventsToManager = (slide, trackName, track, soundObject) ->
  $.map track, (event) =>
    soundObject.onPosition event.time, ->
      codeMirror = slide.cm
      evaluationMode = slide.lecture.mode

      playbook.playbook[trackName] event.value, {codeMirror, evaluationMode}

playSound = (slide, ith, pos) ->
  slide.activeSoundObjectI = ith

  for so in slide.soundObjects
    so.onfinish = undefined

  slide.soundObject().play(
    whileplaying: updateSeekbar
    onfinish: ->
      if ith+1 == slide.soundObjects.length and callback?
        evaluation.enableEditor evaluationContext
        callback()

      slide.div.find(".control-icon").removeClass("").addClass("icon-play")
      playSound slide, ith+1, 0
    onpause: ->
      slide.div.find(".control-icon").removeClass("icon-pause").addClass("icon-play")
    onplay: ->
      slide.div.find(".control-icon").removeClass("icon-play").addClass("icon-pause")
    onresume: ->
      slide.div.find(".control-icon").removeClass("icon-play").addClass("icon-pause")
    position: pos
  )

pauseSound = (e) ->
  if slide.soundObject().paused
    evaluation.disableEditor evaluationContext
    slide.soundObject().play()
  else
    slide.soundObject().pause()
    evaluation.enableEditor evaluationContext

totalTime = ->
  _.reduce slide.talk, ((memo, sound) -> memo+sound.time), 0

seekSound  = (e) ->
  xcord = e.pageX - slide.div.offset().left  # 22 (play icon width) -- 400 (whole slide width)
  tTime = totalTime()
  totalPos   = (xcord - 22) / (400-22) * tTime

  remaining = 0
  i = 0
  while remaining + slide.talk[i].time < totalPos
    remaining += slide.talk[i].time
    i++
  pos = totalPos - remaining

  slide.soundObject()?.stop()
  playSound slide, i, pos

  for track in tracks
    for event in slide.talk[slide.activeSoundObjectI].tracks[track]
      if event.time < slide.soundObject().position
        theEvent = event
    continue unless theEvent?

    playbook.playbook[track] theEvent.value, {codeMirror, evaluationMode}

updateSeekbar = ->
  tTime = totalTime()
  previousTime = _.reduce slide.talk.slice(0, slide.activeSoundObjectI), ((memo, sound) -> memo+sound.time), 0
  perc = (previousTime + slide.soundObject().position) * 100 / tTime
  slide.div.find(".inseek").width(perc + "%")

  connection.whenWhereDictionary.talk =
    name: slide.talk[slide.activeSoundObjectI].file
    time: slide.soundObject().position

# Only visible slides should be able to play sounds.
stopSound = (slide) ->
  if slide.soundObject()?
    slide.soundObject().stop()


@sound = {
  playTalk
  stopSound
}
