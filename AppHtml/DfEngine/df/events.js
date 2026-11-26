/*
Name:
    df.events
Type:
    Library (object)
Contains:
    df.events.DOMHandler   (Class)
    df.events.DOMEvent     (Class)    
    df.events.JSHandler    (Class)
    df.events.JSEvent      (Class)

The events library supplies a special event system for handling and throwing events within the 
framework. It supports the handling of DOM events and custom JavaScript events which can be handled 
in a consistent way across the different browsers.
    
Revisions:
    2007/12/14  Created the new event system framework based on experiences 
    with the event handling methods in previous releases. (HW, DAE)
*/


/*
The AJAX Library has its own event system that works on top of the browsers 
events system and allows custom events to be created and thrown. This layer 
straightens out the differences between browsers and works easier. Events 
thrown by the AJAX Library itself work almost the same as browser events so the 
developer doesn't have to deal with the differences.

Browser/DOM events are attached using a set of global functions. The DOMEvent 
prototype defines the interface of the objects that are given as parameters to 
the listener methods. A set of global methods can be used to attach and remove 
listeners for the DOM events. For events thrown by the framework we have the 
JSHandler prototype that is actually used to instantiate the events. Listeners 
are attached using the addListener method of the JSHandler and will get an 
instantiation of the JSEvent as the parameter. Event specific properties are 
added to this event.

Example of a DOM event:
@code
function initialize(){
     df.events.addDomListener("click", document.getElementById("myButton"), myButton_click, this);
}

function myButton_click(oEvent){
     if(confirm("Sure you clicked the button?")){
        oEvent.eSource.value = "Clicked!"; // Use oEvent.oSource property to get a reference to the button
    }else{
        oEvent.stop(); // Make sure no other listeners are called
    }
}
@code

Example of a framework event:
@code
function initMyForm(oForm){
      oForm.getDD("customer").onBeforeDelete.addListener(confirmdelete, this);
}

function confirmdelete(oEvent){
     return confirm("Are you sure that you want to delete this record?"); // Returning false also stops the event
}
@code
*/
/* global df */
export const events = {

    keys: {
        modifier: [
            "Alt", //The Alt (Alternative) key. This key enables the alternate modifier function for interpreting concurrent or subsequent keyboard input. .This key value is also used for the Apple Option key.
            "AltGraph", //The Alternate Graphics (AltGr or AltGraph) key.	This key is used enable the ISO Level 3 shift modifier (the standard Shift key is the level 2 modifier). See  [ISO9995-1].
            "CapsLock", //The Caps Lock (Capital) key.	Toggle capital character lock function for interpreting subsequent keyboard input event.
            "Control", //The Control or Ctrl key, to enable control modifier function for interpreting concurrent or subsequent keyboard input.
            "Fn", //The Function switch Fn key. Activating this key simultaneously with another key changes that key’s value to an alternate character or function. This key is often handled directly in the keyboard hardware and does not usually generate key events.
            "FnLock", //The Function-Lock (FnLock or F-Lock) key.	Activating this key switches the mode of the keyboard to changes some keys' values to an alternate character or function. This key is often handled directly in the keyboard hardware and does not usually generate key events.
            "Meta", //The Meta key, to enable meta modifier function for interpreting concurrent or subsequent keyboard input.	This key value is used for the Windows Logo key and the Apple Command or ⌘ key.
            "NumLock", //The NumLock or Number Lock key, to toggle numpad mode function for interpreting subsequent keyboard input.
            "ScrollLock", //The Scroll Lock key, to toggle between scrolling and cursor movement modes.
            "Shift", //The Shift key, to enable shift modifier function for interpreting concurrent or subsequent keyboard input.
            "Symbol",     //The Symbol modifier key (used on some virtual keyboards).
            "SymbolLock" //The Symbol Lock key.
        ],
        legacyModifier: [
            "Hyper", //The Hyper key.
            "Super" //The Super key.
        ],
        whiteSpace: [
            "Enter", //The Enter or ↵ key, to activate current selection or accept current input. This key value is also used for the Return (Macintosh numpad) key. This key value is also used for the Android KEYCODE_DPAD_CENTER.
            "Tab" //The Horizontal Tabulation Tab key. The space or spacebar key is encoded as " ".
        ],
        navigation: [
            "ArrowDown", //The down arrow key, to navigate or traverse downward. (KEYCODE_DPAD_DOWN)
            "Down", // IE/Edge 
            "ArrowLeft", //The left arrow key, to navigate or traverse leftward. (KEYCODE_DPAD_LEFT)
            "Left", // IE/Edge 
            "ArrowRight", //The right arrow key, to navigate or traverse rightward. (KEYCODE_DPAD_RIGHT)
            "Right", // IE/Edge 
            "ArrowUp", //The up arrow key, to navigate or traverse upward. (KEYCODE_DPAD_UP)
            "Up", // IE/Edge 
            "End", //The End key, used with keyboard entry to go to the end of content (KEYCODE_MOVE_END).
            "Home", //The Home key, used with keyboard entry, to go to start of content (KEYCODE_MOVE_HOME). For the mobile phone Home key (which goes to the phone’s main screen), use "GoHome".
            "PageDown", //The Page Down key, to scroll down or display next page of content.
            "PageUp" //The Page Up key, to scroll up or display previous page of content.
        ],
        editing: [
            "Backspace", //The Backspace key. This key value is also used for the key labeled Delete on MacOS keyboards.
            "Clear", //Remove the currently selected input.
            "Copy", //Copy the current selection. (APPCOMMAND_COPY)
            "CrSel", //The Cursor Select (Crsel) key.
            "Cut", //Cut the current selection. (APPCOMMAND_CUT)
            "Delete", //The Delete (Del) Key.	This key value is also used for the key labeled Delete on MacOS keyboards when modified by the Fn key.
            "Del", // IE/Edge 
            "EraseEof", //The Erase to End of Field key. This key deletes all characters from the current cursor position to the end of the current field.
            "ExSel", //The Extend Selection (Exsel) key.
            "Insert", //The Insert (Ins) key, to toggle between text modes for insertion or overtyping. (KEYCODE_INSERT)
            "Paste", //The Paste key. (APPCOMMAND_PASTE)
            "Redo", //Redo the last action. (APPCOMMAND_REDO)
            "Undo" //Undo the last action. (APPCOMMAND_UNDO)
        ],
        ui: [
            "Accept", //The Accept (Commit, OK) key. Accept current option or input method sequence conversion.
            "Again", //The Again key, to redo or repeat an action.
            "Attn", //The Attention (Attn) key.
            "Cancel", //The Cancel key.
            "ContextMenu", //Show the application’s context menu.	This key is commonly found between the right Meta key and the right Control key.
            "Escape", //The Esc key. This key was originally used to initiate an escape sequence, but is now more generally used to exit or "escape" the current context, such as closing a dialog or exiting full screen mode.
            "Esc", // IE/Edge 
            "Execute", //The Execute key.
            "Find", //Open the Find dialog. (APPCOMMAND_FIND)
            "Help", //Open a help dialog or toggle display of help information. (APPCOMMAND_HELP, KEYCODE_HELP)
            "Pause", //Pause the current state or application (as appropriate). Do not use this value for the Pause button on media controllers. Use "MediaPause" instead.
            "Play", //Play or resume the current state or application (as appropriate). Do not use this value for the Play button on media controllers. Use "MediaPlay" instead.
            "Props", //The properties (Props) key.
            "Select", //The Select key.
            "ZoomIn", //The ZoomIn key. (KEYCODE_ZOOM_IN)
            "ZoomOut" //The ZoomOut key. (KEYCODE_ZOOM_OUT)
        ],
        device: [
            "BrightnessDown", //The Brightness Down key. Typically controls the display brightness. (KEYCODE_BRIGHTNESS_DOWN)
            "BrightnessUp", //The Brightness Up key. Typically controls the display brightness. (KEYCODE_BRIGHTNESS_UP)
            "Eject", //Toggle removable media to eject (open) and insert (close) state. (KEYCODE_MEDIA_EJECT)
            "LogOff", //The LogOff key.
            "Power", //Toggle power state. (KEYCODE_POWER) Note: Some devices might not expose this key to the operating environment.
            "PowerOff", //The PowerOff key. Sometime called PowerDown.
            "PrintScreen", //The Print Screen or SnapShot key, to initiate print-screen function.
            "Hibernate", //The Hibernate key.	This key saves the current state of the computer to disk so that it can be restored. The computer will then shutdown.
            "Standby", //The Standby key.	This key turns off the display and places the computer into a low-power mode without completely shutting down. It is sometimes labelled Suspend or Sleep key. (KEYCODE_SLEEP)
            "WakeUp" //The WakeUp key. (KEYCODE_WAKEUP)
        ],
        imeCompositionKeys: [
            "AllCandidates", //The All Candidates key, to initate the multi-candidate mode.
            "Alphanumeric", //The Alphanumeric key.
            "CodeInput", //The Code Input key, to initiate the Code Input mode to allow characters to be entered by their code points.
            "Compose", //The Compose key, also known as Multi_key on the X Window System. This key acts in a manner similar to a	dead key, triggering a mode where subsequent key presses are combined to produce a different character.
            "Convert", //The Convert key, to convert the current input method sequence.
            "Dead", //A dead key combining key. It may be any combining key from any keyboard layout. For example, on a	PC/AT French keyboard, using a French mapping and without any modifier activiated, this is the key value U+0302 COMBINING CIRCUMFLEX ACCENT. In another layout this might be a different unicode combining key. For applications that need to differentiate between specific combining characters, the associated compositionupdate event’s data attribute provides the specific key value.
            "FinalMode", //The Final Mode Final key used on some Asian keyboards, to enable the final mode for IMEs.
            "GroupFirst", //Switch to the first character group. (ISO/IEC 9995)
            "GroupLast", //Switch to the last character group. (ISO/IEC 9995)
            "GroupNext", //Switch to the next character group. (ISO/IEC 9995)
            "GroupPrevious", //Switch to the previous character group. (ISO/IEC 9995)
            "ModeChange", //The Mode Change key, to toggle between or cycle through input modes of IMEs.
            "NextCandidate", //The Next Candidate function key.
            "NonConvert", //The NonConvert ("Don’t Convert") key, to accept current input method sequence without conversion in IMEs.
            "PreviousCandidate", //The Previous Candidate function key.
            "Process", //The Process key.
            "SingleCandidate" //The Single Candidate function key.
        ],
        koreanSpecific: [
            "HangulMode", //The Hangul (Korean characters) Mode key, to toggle between Hangul and English modes.
            "HanjaMode", //The Hanja (Korean characters) Mode key.
            "JunjaMode" //The Junja (Korean characters) Mode key.
        ],
        japaneseSpecific: [
            "Eisu", //The Eisu key. This key may close the IME, but its purpose	is defined by the current IME. (KEYCODE_EISU)
            "Hankaku", //The (Half-Width) Characters key.
            "Hiragana", //The Hiragana (Japanese Kana characters) key.
            "HiraganaKatakana", //The Hiragana/Katakana toggle key. (KEYCODE_KATAKANA_HIRAGANA)
            "KanaMode", //The Kana Mode (Kana Lock) key. This key is used to enter	hiragana mode (typically from romaji mode).
            "KanjiMode", //The Kanji (Japanese name for ideographic characters of Chinese origin) Mode key.	This key is typically used to switch to a hiragana keyboard for the purpose of converting input into kanji. (KEYCODE_KANA)
            "Katakana", //The Katakana (Japanese Kana characters) key.
            "Romaji", //The Roman characters function key.
            "Zenkaku", //The Zenkaku (Full-Width) Characters key.
            "ZenkakuHankaku" //The Zenkaku/Hankaku (full-width/half-width) toggle key. (KEYCODE_ZENKAKU_HANKAKU)
        ],
        // The exact number of these general purpose function keys varies on different platforms, and only the first few are defined explicitly here. Additional function key names are implicitly defined by incrementing the base-10 index at the end of the function key name. Thus, "F24" and "Soft8" are all valid key values.
        commonFunction: [
            "F1", //The F1 key, a general purpose function key, as index 1.
            "F2", //The F2 key, a general purpose function key, as index 2.
            "F3", //The F3 key, a general purpose function key, as index 3.
            "F4", //The F4 key, a general purpose function key, as index 4.
            "F5", //The F5 key, a general purpose function key, as index 5.
            "F6", //The F6 key, a general purpose function key, as index 6.
            "F7", //The F7 key, a general purpose function key, as index 7.
            "F8", //The F8 key, a general purpose function key, as index 8.
            "F9", //The F9 key, a general purpose function key, as index 9.
            "F10", //The F10 key, a general purpose function key, as index 10.
            "F11", //The F11 key, a general purpose function key, as index 11.
            "F12", //The F12 key, a general purpose function key, as index 12.
            "Soft1", //General purpose virtual function key, as index 1.
            "Soft2", //General purpose virtual function key, as index 2.
            "Soft3", //General purpose virtual function key, as index 3.
            "Soft4" //General purpose virtual function key, as index 4.
        ],
        // These are extra keys found on "multimedia" keyboards.
        multimedia: [
            "ChannelDown", //Select next (numerically or logically) lower channel. (APPCOMMAND_MEDIA_CHANNEL_DOWN, KEYCODE_CHANNEL_DOWN)
            "ChannelUp", //Select next (numerically or logically) higher channel. (APPCOMMAND_MEDIA_CHANNEL_UP, KEYCODE_CHANNEL_UP)
            "Close", //Close the current document or message (Note: This doesn’t close the application). (APPCOMMAND_CLOSE)
            "MailForward", //Open an editor to forward the current message. (APPCOMMAND_FORWARD_MAIL)
            "MailReply", //Open an editor to reply to the current message. (APPCOMMAND_REPLY_TO_MAIL)
            "MailSend", //Send the current message. (APPCOMMAND_SEND_MAIL)
            "MediaClose", //Close the current media, for example to close a CD or DVD tray. (KEYCODE_MEDIA_CLOSE)
            "MediaFastForward", //Initiate or continue forward playback at faster than normal speed, or increase speed if already fast forwarding. (APPCOMMAND_MEDIA_FAST_FORWARD, KEYCODE_MEDIA_FAST_FORWARD)
            "MediaPause", //Pause the currently playing media. (APPCOMMAND_MEDIA_PAUSE, KEYCODE_MEDIA_PAUSE) Media controller devices should use this value rather than "Pause" for their pause keys.
            "MediaPlay", //Initiate or continue media playback at normal speed, if not currently playing at normal speed. (APPCOMMAND_MEDIA_PLAY, KEYCODE_MEDIA_PLAY)
            "MediaPlayPause", //Toggle media between play and pause states. (APPCOMMAND_MEDIA_PLAY_PAUSE, KEYCODE_MEDIA_PLAY_PAUSE)
            "MediaRecord", //Initiate or resume recording of currently selected media. (APPCOMMAND_MEDIA_RECORD, KEYCODE_MEDIA_RECORD)
            "MediaRewind", //Initiate or continue reverse playback at faster than normal speed, or increase speed if already rewinding. (APPCOMMAND_MEDIA_REWIND, KEYCODE_MEDIA_REWIND)
            "MediaStop", //Stop media playing, pausing, forwarding, rewinding, or recording, if not already stopped. (APPCOMMAND_MEDIA_STOP, KEYCODE_MEDIA_STOP)
            "MediaTrackNext", //Seek to next media or program track. (APPCOMMAND_MEDIA_NEXTTRACK, KEYCODE_MEDIA_NEXT)
            "MediaTrackPrevious", //Seek to previous media or program track. (APPCOMMAND_MEDIA_PREVIOUSTRACK, KEYCODE_MEDIA_PREVIOUS)
            "New", //Open a new document or message. (APPCOMMAND_NEW)
            "Open", //Open an existing document or message. (APPCOMMAND_OPEN)
            "Print", //Print the current document or message. (APPCOMMAND_PRINT)
            "Save", //Save the current document or message. (APPCOMMAND_SAVE)
            "SpellCheck" //Spellcheck the current document or selection. (APPCOMMAND_SPELL_CHECK)
        ],
        // The normal 0 ... 9 numpad keys are encoded as "0" ... "9", but some multimedia keypads have buttons numbered from 1 ... 12. In these instances, the 10 key is often labeled 10 /0. Note: The 10 or 10 /0 key MUST be assigned a key value of "0".
        multimediaNumpad: [
            "Key11", //The 11 key found on media numpads that	have buttons from 1 ... 12.
            "Key12" //The 12 key found on media numpads that	have buttons from 1 ... 12.
        ],
        // Multimedia keys related to audio.
        audio: [
            "AudioBalanceLeft", //Adjust audio balance leftward. (VK_AUDIO_BALANCE_LEFT)
            "AudioBalanceRight", //Adjust audio balance rightward. (VK_AUDIO_BALANCE_RIGHT)
            "AudioBassBoostDown", //Decrease audio bass boost or cycle down through bass boost states. (APPCOMMAND_BASS_DOWN, VK_BASS_BOOST_DOWN)
            "AudioBassBoostToggle", //Toggle bass boost on/off. (APPCOMMAND_BASS_BOOST)
            "AudioBassBoostUp", //Increase audio bass boost or cycle up through bass boost states. (APPCOMMAND_BASS_UP, VK_BASS_BOOST_UP)
            "AudioFaderFront", //Adjust audio fader towards front. (VK_FADER_FRONT)
            "AudioFaderRear", //Adjust audio fader towards rear. (VK_FADER_REAR)
            "AudioSurroundModeNext", //Advance surround audio mode to next available mode. (VK_SURROUND_MODE_NEXT)
            "AudioTrebleDown", //Decrease treble. (APPCOMMAND_TREBLE_DOWN)
            "AudioTrebleUp", //Increase treble. (APPCOMMAND_TREBLE_UP)
            "AudioVolumeDown", //Decrease audio volume. (APPCOMMAND_VOLUME_DOWN, KEYCODE_VOLUME_DOWN)
            "AudioVolumeUp", //Increase audio volume. (APPCOMMAND_VOLUME_UP, KEYCODE_VOLUME_UP)
            "AudioVolumeMute", //Toggle between muted state and prior volume level. (APPCOMMAND_VOLUME_MUTE, KEYCODE_VOLUME_MUTE)
            "MicrophoneToggle", //Toggle the microphone on/off. (APPCOMMAND_MIC_ON_OFF_TOGGLE)
            "MicrophoneVolumeDown", //Decrease microphone volume. (APPCOMMAND_MICROPHONE_VOLUME_DOWN)
            "MicrophoneVolumeUp", //Increase microphone volume. (APPCOMMAND_MICROPHONE_VOLUME_UP)
            "MicrophoneVolumeMute" //Mute the microphone. (APPCOMMAND_MICROPHONE_VOLUME_MUTE, KEYCODE_MUTE)
        ],
        // Multimedia keys related to speech recognition.
        speech: [
            "SpeechCorrectionList", //Show correction list when a word is incorrectly identified. (APPCOMMAND_CORRECTION_LIST)
            "SpeechInputToggle" //Toggle between dictation mode and command/control mode. (APPCOMMAND_DICTATE_OR_COMMAND_CONTROL_TOGGLE)
        ],
        // The Application Keys are special keys that are assigned to launch a particular application. Additional application key names can be defined by concatenating "Launch" with the name of the application.
        application: [
            "LaunchApplication1", //The first generic "LaunchApplication" key. This is commonly associated with launching "My Computer", and may have a computer symbol on the key. (APPCOMMAND_LAUNCH_APP1)
            "LaunchApplication2", //The second generic "LaunchApplication" key. This is commonly associated with launching "Calculator", and may have a calculator symbol on the key. (APPCOMMAND_LAUNCH_APP2, KEYCODE_CALCULATOR)
            "LaunchCalendar", //The "Calendar" key. (KEYCODE_CALENDAR)
            "LaunchContacts", //The "Contacts" key. (KEYCODE_CONTACTS)
            "LaunchMail", //The "Mail" key. (APPCOMMAND_LAUNCH_MAIL)
            "LaunchMediaPlayer", //The "Media Player" key. (APPCOMMAND_LAUNCH_MEDIA_SELECT)
            "LaunchMusicPlayer", //The "Music Player" key.
            "LaunchPhone", //The "Phone" key.
            "LaunchScreenSaver", //The "Screen Saver" key.
            "LaunchSpreadsheet", //The "Spreadsheet" key.
            "LaunchWebBrowser", //The "Web Browser" key.
            "LaunchWebCam", //The "WebCam" key.
            "LaunchWordProcessor" //The "Word Processor" key.
        ],
        browser: [
            "BrowserBack", //Navigate to previous content or page in current history. (APPCOMMAND_BROWSER_BACKWARD)
            "BrowserFavorites", //Open the list of browser favorites. (APPCOMMAND_BROWSER_FAVORITES)
            "BrowserForward", //Navigate to next content or page in current history. (APPCOMMAND_BROWSER_FORWARD)
            "BrowserHome", //Go to the user’s preferred home page. (APPCOMMAND_BROWSER_HOME)
            "BrowserRefresh", //Refresh the current page or content. (APPCOMMAND_BROWSER_REFRESH)
            "BrowserSearch", //Call up the user’s preferred search page. (APPCOMMAND_BROWSER_SEARCH)
            "BrowserStop" //Stop loading the current page or content. (APPCOMMAND_BROWSER_STOP)
        ],
        mobilePhone: [
            "AppSwitch", //The Application switch key, which provides a list of recent apps to switch between. (KEYCODE_APP_SWITCH)
            "Call", //The Call key. (KEYCODE_CALL)
            "Camera", //The Camera key. (KEYCODE_CAMERA)
            "CameraFocus", //The Camera focus key. (KEYCODE_FOCUS)
            "EndCall", //The End Call key. (KEYCODE_ENDCALL)
            "GoBack", //The Back key. (KEYCODE_BACK)
            "GoHome", //The Home key, which goes to the phone’s main screen. (KEYCODE_HOME)
            "HeadsetHook", //The Headset Hook key. (KEYCODE_HEADSETHOOK)
            "LastNumberRedial", //The Last Number Redial key.
            "Notification", //The Notification key. (KEYCODE_NOTIFICATION)
            "MannerMode", //Toggle between manner mode state: silent, vibrate, ring, ... (KEYCODE_MANNER_MODE)
            "VoiceDial" //The Voice Dial key.
        ],
        tv: [
            "TV", //Switch to viewing TV. (KEYCODE_TV)
            "TV3DMode", //TV 3D Mode. (KEYCODE_3D_MODE)
            "TVAntennaCable", //Toggle between antenna and cable input. (KEYCODE_TV_ANTENNA_CABLE)
            "TVAudioDescription", //Audio description. (KEYCODE_TV_AUDIO_DESCRIPTION)
            "TVAudioDescriptionMixDown", //Audio description mixing volume down. (KEYCODE_TV_AUDIO_DESCRIPTION_MIX_DOWN)
            "TVAudioDescriptionMixUp", //Audio description mixing volume up. (KEYCODE_TV_AUDIO_DESCRIPTION_MIX_UP)
            "TVContentsMenu", //Contents menu. (KEYCODE_TV_CONTENTS_MENU)
            "TVDataService", //Contents menu. (KEYCODE_TV_DATA_SERVICE)
            "TVInput", //Switch the input mode on an external TV. (KEYCODE_TV_INPUT)
            "TVInputComponent1", //Switch to component input #1. (KEYCODE_TV_INPUT_COMPONENT_1)
            "TVInputComponent2", //Switch to component input #2. (KEYCODE_TV_INPUT_COMPONENT_2)
            "TVInputComposite1", //Switch to composite input #1. (KEYCODE_TV_INPUT_COMPOSITE_1)
            "TVInputComposite2", //Switch to composite input #2. (KEYCODE_TV_INPUT_COMPOSITE_2)
            "TVInputHDMI1", //Switch to HDMI input #1. (KEYCODE_TV_INPUT_HDMI_1)
            "TVInputHDMI2", //Switch to HDMI input #2. (KEYCODE_TV_INPUT_HDMI_2)
            "TVInputHDMI3", //Switch to HDMI input #3. (KEYCODE_TV_INPUT_HDMI_3)
            "TVInputHDMI4", //Switch to HDMI input #4. (KEYCODE_TV_INPUT_HDMI_4)
            "TVInputVGA1", //Switch to VGA input #1. (KEYCODE_TV_INPUT_VGA_1)
            "TVMediaContext", //Media context menu. (KEYCODE_TV_MEDIA_CONTEXT_MENU)
            "TVNetwork", //Toggle network. (KEYCODE_TV_NETWORK)
            "TVNumberEntry", //Number entry. (KEYCODE_TV_NUMBER_ENTRY)
            "TVPower", //Toggle the power on an external TV. (KEYCODE_TV_POWER)
            "TVRadioService", //Radio. (KEYCODE_TV_RADIO_SERVICE)
            "TVSatellite", //Satellite. (KEYCODE_TV_SATELLITE)
            "TVSatelliteBS", //Broadcast Satellite. (KEYCODE_TV_SATELLITE_BS)
            "TVSatelliteCS", //Communication Satellite. (KEYCODE_TV_SATELLITE_CS)
            "TVSatelliteToggle", //Toggle between available satellites. (KEYCODE_TV_SATELLITE_SERVICE)
            "TVTerrestrialAnalog", //Analog Terrestrial. (KEYCODE_TV_TERRESTRIAL_ANALOG)
            "TVTerrestrialDigital", //Digital Terrestrial. (KEYCODE_TV_TERRESTRIAL_DIGITAL)
            "TVTimer" //Timer programming. (KEYCODE_TV_TIMER_PROGRAMMING)
        ],
        // The key attribute values for media controllers (e.g. remote controls for television, audio systems, and set-top boxes) are derived in part from the consumer electronics technical specifications:
        mediaControls: [
            "AVRInput", //Switch the input mode on an external AVR (audio/video receiver). (KEYCODE_AVR_INPUT)
            "AVRPower", //Toggle the power on an external AVR (audio/video receiver). (KEYCODE_AVR_POWER)
            "ColorF0Red", //General purpose color-coded media function key, as index 0 (red). (VK_COLORED_KEY_0, KEYCODE_PROG_RED)
            "ColorF1Green", //General purpose color-coded media function key, as index 1 (green). (VK_COLORED_KEY_1, KEYCODE_PROG_GREEN)
            "ColorF2Yellow", //General purpose color-coded media function key, as index 2 (yellow). (VK_COLORED_KEY_2, KEYCODE_PROG_YELLOW)
            "ColorF3Blue", //General purpose color-coded media function key, as index 3 (blue). (VK_COLORED_KEY_3, KEYCODE_PROG_BLUE)
            "ColorF4Grey", //General purpose color-coded media function key, as index 4 (grey). (VK_COLORED_KEY_4)
            "ColorF5Brown", //General purpose color-coded media function key, as index 5 (brown). (VK_COLORED_KEY_5)
            "ClosedCaptionToggle", //Toggle the display of Closed Captions. (VK_CC, KEYCODE_CAPTIONS)
            "Dimmer", //Adjust brightness of device, by toggling between or cycling through states. (VK_DIMMER)
            "DisplaySwap", //Swap video sources. (VK_DISPLAY_SWAP)
            "DVR", //Select Digital Video Rrecorder. (KEYCODE_DVR)
            "Exit", //Exit the current application. (VK_EXIT)
            "FavoriteClear0", //Clear program or content stored as favorite 0. (VK_CLEAR_FAVORITE_0)
            "FavoriteClear1", //Clear program or content stored as favorite 1. (VK_CLEAR_FAVORITE_1)
            "FavoriteClear2", //Clear program or content stored as favorite 2. (VK_CLEAR_FAVORITE_2)
            "FavoriteClear3", //Clear program or content stored as favorite 3. (VK_CLEAR_FAVORITE_3)
            "FavoriteRecall0", //Select (recall) program or content stored as favorite 0. (VK_RECALL_FAVORITE_0)
            "FavoriteRecall1", //Select (recall) program or content stored as favorite 1. (VK_RECALL_FAVORITE_1)
            "FavoriteRecall2", //Select (recall) program or content stored as favorite 2. (VK_RECALL_FAVORITE_2)
            "FavoriteRecall3", //Select (recall) program or content stored as favorite 3. (VK_RECALL_FAVORITE_3)
            "FavoriteStore0", //Store current program or content as favorite 0. (VK_STORE_FAVORITE_0)
            "FavoriteStore1", //Store current program or content as favorite 1. (VK_STORE_FAVORITE_1)
            "FavoriteStore2", //Store current program or content as favorite 2. (VK_STORE_FAVORITE_2)
            "FavoriteStore3", //Store current program or content as favorite 3. (VK_STORE_FAVORITE_3)
            "Guide", //Toggle display of program or content guide. (VK_GUIDE, KEYCODE_GUIDE)
            "GuideNextDay", //If guide is active and displayed, then display next day’s content. (VK_NEXT_DAY)
            "GuidePreviousDay", //If guide is active and displayed, then display previous day’s content. (VK_PREV_DAY)
            "Info", //Toggle display of information about currently selected context or media. (VK_INFO, KEYCODE_INFO)
            "InstantReplay", //Toggle instant replay. (VK_INSTANT_REPLAY)
            "Link", //Launch linked content, if available and appropriate. (VK_LINK)
            "ListProgram", //List the current program. (VK_LIST)
            "LiveContent", //Toggle display listing of currently available live content or programs. (VK_LIVE)
            "Lock", //Lock or unlock current content or program. (VK_LOCK)
            "MediaApps", //Show a list of media applications: audio/video players and image viewers. (VK_APPS) Do not confuse this key value with the Windows' VK_APPS / VK_CONTEXT_MENU key, which is encoded as "ContextMenu".
            "MediaAudioTrack", //Audio track key. (KEYCODE_MEDIA_AUDIO_TRACK)
            "MediaLast", //Select previously selected channel or media. (VK_LAST, KEYCODE_LAST_CHANNEL)
            "MediaSkipBackward", //Skip backward to next content or program. (KEYCODE_MEDIA_SKIP_BACKWARD)
            "MediaSkipForward", //Skip forward to next content or program. (VK_SKIP, KEYCODE_MEDIA_SKIP_FORWARD)
            "MediaStepBackward", //Step backward to next content or program. (KEYCODE_MEDIA_STEP_BACKWARD)
            "MediaStepForward", //Step forward to next content or program. (KEYCODE_MEDIA_STEP_FORWARD)
            "MediaTopMenu", //Media top menu. (KEYCODE_MEDIA_TOP_MENU)
            "NavigateIn", //Navigate in. (KEYCODE_NAVIGATE_IN)
            "NavigateNext", //Navigate to next key. (KEYCODE_NAVIGATE_NEXT)
            "NavigateOut", //Navigate out. (KEYCODE_NAVIGATE_OUT)
            "NavigatePrevious", //Navigate to previous key. (KEYCODE_NAVIGATE_PREVIOUS)
            "NextFavoriteChannel", //Cycle to next favorite channel (in favorites list). (VK_NEXT_FAVORITE_CHANNEL)
            "NextUserProfile", //Cycle to next user profile (if there are multiple user profiles). (VK_USER)
            "OnDemand", //Access on-demand content or programs. (VK_ON_DEMAND)
            "Pairing", //Pairing key to pair devices. (KEYCODE_PAIRING)
            "PinPDown", //Move picture-in-picture window down. (VK_PINP_DOWN)
            "PinPMove", //Move picture-in-picture window. (VK_PINP_MOVE)
            "PinPToggle", //Toggle display of picture-in-picture window. (VK_PINP_TOGGLE)
            "PinPUp", //Move picture-in-picture window up. (VK_PINP_UP)
            "PlaySpeedDown", //Decrease media playback speed. (VK_PLAY_SPEED_DOWN)
            "PlaySpeedReset", //Reset playback to normal speed. (VK_PLAY_SPEED_RESET)
            "PlaySpeedUp", //Increase media playback speed. (VK_PLAY_SPEED_UP)
            "RandomToggle", //Toggle random media or content shuffle mode. (VK_RANDOM_TOGGLE)
            "RcLowBattery", //Not a physical key, but this key code is sent when the remote control battery is low. (VK_RC_LOW_BATTERY)
            "RecordSpeedNext", //Toggle or cycle between media recording speeds. (VK_RECORD_SPEED_NEXT)
            "RfBypass", //Toggle RF (radio frequency) input bypass mode (pass RF input directly to the RF output). (VK_RF_BYPASS)
            "ScanChannelsToggle", //Toggle scan channels mode. (VK_SCAN_CHANNELS_TOGGLE)
            "ScreenModeNext", //Advance display screen mode to next available mode. (VK_SCREEN_MODE_NEXT)
            "Settings", //Toggle display of device settings screen. (VK_SETTINGS, KEYCODE_SETTINGS)
            "SplitScreenToggle", //Toggle split screen mode. (VK_SPLIT_SCREEN_TOGGLE)
            "STBInput", //Switch the input mode on an external STB (set top box). (KEYCODE_STB_INPUT)
            "STBPower", //Toggle the power on an external STB (set top box). (KEYCODE_STB_POWER)
            "Subtitle", //Toggle display of subtitles, if available. (VK_SUBTITLE)
            "Teletext", //Toggle display of teletext, if available (VK_TELETEXT, KEYCODE_TV_TELETEXT).
            "VideoModeNext", //Advance video mode to next available mode. (VK_VIDEO_MODE_NEXT)
            "Wink", //Cause device to identify itself in some manner, e.g., audibly or visibly. (VK_WINK)
            "ZoomToggle" //Toggle between full-screen and scaled content, or alter magnification level. (VK_ZOOM, KEYCODE_TV_ZOOM_MODE)
        ]
    },

    allKeys: null,

    insertInputTypes: [
        "insertText", // 	insert typed plain text 	No 	Undefined 	Any
        "insertReplacementText", // 	replace existing text by means of a spell checker, auto-correct or similar 	No 	Undefined 	Any
        "insertLineBreak", // 	insert a line break 	No 	Undefined 	Any
        "insertParagraph", // 	insert a paragraph break 	No 	Undefined 	Any
        "insertOrderedList", // 	insert a numbered list 	No 	Yes 	Any
        "insertUnorderedList", // 	insert a bulleted list 	No 	Yes 	Any
        "insertHorizontalRule", // 	insert a horizontal rule 	No 	Yes 	Any
        "insertFromYank", // 	replace the current selection with content stored in a kill buffer 	No 	Yes 	Any
        "insertFromDrop", // 	insert content into the DOM by means of drop 	No 	Yes 	Any
        "insertFromPaste",          // 	paste 	No 	Yes 	Any
        "insertFromPasteAsQuotation", // paste content as a quotation 	No 	Yes 	Any
        "insertTranspose",          // 	transpose the last two characters that were entered 	No 	Yes 	Any
        "insertCompositionText",    // 	replace the current composition string 	Yes 	No 	Any
        "insertLink"                // 	insert a link 	No 	Yes 	Any 
    ],

    /*
    Keycode for the tab key.
    
    @private
    */
    KEY_CODE_TAB: 9,

    /*
    Keycodes that do not edit a value.
    
    @private
    */
    KEY_CODE_NON_EDIT: { 37: 1, 38: 1, 39: 1, 40: 1, 35: 1, 36: 1, 9: 1 },

    /*
    Special keys that are almost always allowed.
    
    @private
    */
    KEY_CODE_SPECIAL: { 37: 1, 38: 1, 39: 1, 40: 1, 35: 1, 36: 1, 46: 1, 8: 1, 9: 1 },
    //  37, 38, 39, 40 cursor keys
    //  35  end
    //  36  home
    //  46  delete
    //  8   backspace
    //  9   tab

    /*
    Adds a capturing listener to a DOM element. This function is only supported by 
    browsers that implement the W3C event model. Please do not use this method if 
    you don't know what event capturing is because it can places the event listener
    before any other event. It works by adding a "capture_" prefix to the event 
    name for W3C browsers so the DOMHandler recognizes this as a different event.
    
    @param  sEvent          Name of the event to listen to.
    @param  eElement        Reference to the DOM element that fires the event.
    @param  fListener       Reference to the function that will handle the event.
    @param  oEnvironment    (optional) Reference to the environment of the handler 
            ('this' will reference to this object when the handler is called).
    */
    addDomCaptureListener(sEvent, eElement, fListener, oEnvironment) {
        //  Attach the listener
        if (window.addEventListener) { // W3C
            sEvent = "capture_" + sEvent;
        }

        this.addDomListener(sEvent, eElement, fListener, oEnvironment);
    },

    /*
    Removes a capturing listener to of a DOM element.
    
    @param  sEvent      Name of the event.
    @param  eElement    Reference to the DOM element.
    @param  fListener   Reference to the function that is attached to the event.
    @param  oEnvironment    (optional) Reference to the environment of the handler 
            ('this' will reference to this object when the handler is called).
    */
    removeDomCaptureListener(sEvent, eElement, fListener, oEnvironment) {
        //  Attach the listener
        if (window.addEventListener) { // W3C
            sEvent = "capture_" + sEvent;
        }

        this.removeDomListener(sEvent, eElement, fListener, oEnvironment);
    },

    /*
    Adds a listener to an event of a DOM element in a browser independent way using
    the df.events.DOMHandler object. The name of the event is according to the W3C
    specifications (so without the microsoft "on") usage. Note that for some 
    special events like the mousewheel event special methods are available.
    
    @param  sEvent          Name of the event to listen to.
    @param  eElement        Reference to the DOM element that fires the event.
    @param  fListener       Reference to the function that will handle the event.
    @param  oEnvironment    (optional) Reference to the environment of the handler 
            ('this' will reference to this object when the handler is called).
    */
    addDomListener(sEvent, eElement, fListener, oEnvironment) {
        let oDOMHandler;

        //  Find or create DOM Handler
        if (eElement._oDfDomH === undefined || !eElement._oDfDomH[sEvent]) {
            oDOMHandler = new events.DOMHandler(sEvent, eElement);
        } else {
            oDOMHandler = eElement._oDfDomH[sEvent];
        }

        //  Add listener to handler
        oDOMHandler.addListener(fListener, oEnvironment);
    },

    /*
    Removes the event listener from the DOM element so it won't be called any more 
    if the event occurs.
    
    @param  sEvent      Name of the event to which the handler listened.
    @param  eElement    Reference to the element that fired the event.
    @param  fListener   Reference to the method that was handling the event.
    @param  oEnvironment    (optional) Reference to the environment of the handler 
            ('this' will reference to this object when the handler is called).
    */
    removeDomListener(sEvent, eElement, fListener, oEnvironment) {
        //  Find handler and call remove method
        if (eElement._oDfDomH !== undefined && eElement._oDfDomH[sEvent]) {
            eElement._oDfDomH[sEvent].removeListener(fListener, oEnvironment);
        }
    },

    /*
    Adds a key listener to the DOM elements. The Internet Explorer only sends the 
    correct key information on the keydown event instead of with the keypress 
    event.
    
    @param  eElement        Reference to the DOM element that fires the event.
    @param  fListener       Reference to the function that will handle the event.
    @param  oEnvironment    (optional) Reference to the environment of the handler 
            ('this' will reference to this object when the handler is called).    
    */
    addDomKeyListener(eElement, fListener, oEnvironment) {
        // if(window.addEventListener){ // W3C
        // events.addDomListener("keypress", eElement, fListener, oEnvironment);
        // }else{ // IE
        events.addDomListener("keydown", eElement, fListener, oEnvironment);
        // }
    },

    /*
    Removes the key listener from the DOM element.
    
    @param  eElement    Reference to the element that fired the event.
    @param  fListener   Reference to the method that was handling the event.
    @param  oEnvironment    (optional) Reference to the environment of the handler 
            ('this' will reference to this object when the handler is called).   
    */
    removeDomKeyListener(eElement, fListener, oEnvironment) {
        // if(window.addEventListener){ // W3C
        // events.removeDomListener("keypress", eElement, fListener);
        // }else{ // IE
        events.removeDomListener("keydown", eElement, fListener, oEnvironment);
        // }
    },

    /*
    Adds a listener to the mousewheel event which has different names for the 
    different browsers.
    
    @param  eElement        Reference to the DOM element that fires the event.
    @param  fListener       Reference to the function that will handle the event.
    @param  oEnvironment    (optional) Reference to the environment of the handler 
                        ('this' will reference to this object when the handler is 
                        called).       
    */
    addDomMouseWheelListener(eElement, fListener, oEnvironment) {
        if (df.sys.isMoz) { //   Mozilla
            events.addDomListener("DOMMouseScroll", eElement, fListener, oEnvironment);
        } else { // IE, WebKit
            events.addDomListener("mousewheel", eElement, fListener, oEnvironment);
        }
    },

    /*
    Removes the mousewheel listener from the DOM element.
    
    @param  eElement    Reference to the element that fired the event.
    @param  fListener   Reference to the method that was handling the event.
    @param  oEnvironment    (optional) Reference to the environment of the handler 
                        ('this' will reference to this object when the handler is 
                        called).       
    */
    removeDomMouseWheelListener(eElement, fListener, oEnvironment) {
        if (df.sys.isMoz) {  //  Mozilla
            events.removeDomListener("DOMMouseScroll", eElement, fListener, oEnvironment);
        } else { // IE, WebKit
            events.removeDomListener("mousewheel", eElement, fListener, oEnvironment);
        }
    },

    /*
    Generic event listener used to cancel events directly.
    
    @param  oEvent  Event object.
    */
    stop(oEvent) {
        oEvent.stop();
    },


    /*
    @private
    
    Administration used to clear the event listeners on window unload.
    */
    iDOMHandlers: 0,
    /*
    @private
    */
    oDOMHandlers: {},


    /*
    @private
    
    Clears all the event handlers to prevent memory leaks.
    */
    clearDomHandlers() {

        for (const iHandlerId in events.oDOMHandlers) {
            if (events.oDOMHandlers.hasOwnProperty(iHandlerId)) {
                if (events.oDOMHandlers[iHandlerId].__DOMHandler) {
                    events.oDOMHandlers[iHandlerId].clear();
                }
            }
        }
    },

    /*
    This method clears all the event listeners that are attached to the given DOM 
    element. The listeners need to be attached using the AJAX Library event system. 
    If bRecursive is true it will move into the child elements and clear those event 
    listeners as well. Clearing the listeners is important because these connections 
    between the browsers DOM environment and the JavaScript environment can cause 
    problems with the garbage collector which can cause memory leaks.
    
    @param  eElement    Reference to the DOM element.
    @param  bRecursive  (optional) If true child elements are also cleared.
    */
    clearDomListeners(eElement, bRecursive) {

        //  Loop through DOM handlers and remove them
        if (eElement._oDfDomH) {
            for (const sEvent in eElement._oDfDomH) {
                if (eElement._oDfDomH.hasOwnProperty(sEvent)) {
                    eElement._oDfDomH[sEvent].clear();
                }
            }
        }

        //  Move into children
        if (bRecursive) {
            df.dom.visit(eElement, function (eChild) {
                events.clearDomListeners(eChild, true);
            });
        }
    }
};




/*
The handler for one event that can contain multiple listeners. Contains the 
functionality to attach to the event and to call the registered listeners. 
Detaches itself if the last listener is unregistered (or if the page is 
unloaded). The _oDfDomH property is added to the element that contains 
references (as a named array) to all the handlers for that element.

@private
*/
events.DOMHandler = class DOMHandler {
    /*
    Constructor that gets the important properties.

    @param  sEvent      Name of the event.
    @param  eElement    Reference to the DOM element.
    @private
    */
    constructor(sEvent, eElement) {
        //  @privates
        this.sEvent = sEvent;
        this.eElement = eElement;


        this.aListeners = [];
        this.aRemoveListeners = [];
        this.bFiring = false;
        this.fHandler = null;
        this.__DOMHandler = true;

        this.iHandlerId = events.iDOMHandlers++;

        this.attach();
    }

    /*
    @private
    
    Attaches itself to the event using an inline anonymous function that calls the 
    fire method with the correct envirioment. Registers itself on the element and 
    globally.
    */
    attach() {
        let fHandler;
        const oDOMHandler = this;

        //  Create inline method that calls the handling method with the correct environment
        fHandler = function (e) {
            return oDOMHandler.fire(e);
        };

        //  Attach the listener
        if (window.addEventListener) { // W3C
            if (this.sEvent.substr(0, 8) === "capture_") {
                this.eElement.addEventListener(this.sEvent.substr(8), fHandler, true);
            } else {
                this.eElement.addEventListener(this.sEvent, fHandler, false);
            }
        } else { // IE
            this.eElement.attachEvent("on" + this.sEvent, fHandler);
        }

        //  Register the handler on the element
        if (!this.eElement._oDfDomH) {
            this.eElement._oDfDomH = {};
        }
        this.eElement._oDfDomH[this.sEvent] = this;

        //  Register the handler globally
        events.oDOMHandlers[this.iHandlerId] = this;

        this.fHandler = fHandler;
    }


    /*
    @private
    
    Clears the handler by deattaching itself from the event and removing itself 
    from the global and elements registration.
    */
    clear() {
        //  Deattach the listener
        if (window.addEventListener) {
            if (this.sEvent.substr(0, 8) === "capture_") {
                this.eElement.removeEventListener(this.sEvent.substr(8), this.fHandler, true);
            } else {
                this.eElement.removeEventListener(this.sEvent, this.fHandler, false);
            }
        } else {
            this.eElement.detachEvent("on" + this.sEvent, this.fHandler);
        }

        //  Unregister the handler on the element
        delete this.eElement._oDfDomH[this.sEvent];

        //  Unregister the global handler
        delete events.oDOMHandlers[this.iHandlerId];
    }


    /*
    @private
    
    Adds a listener to the event that is handled by this handler. It adds the 
    listener and environment reference encapsulated in an object to the listeners 
    array.
    
    @param  fListener       Reference to the handling method.
    @param  oEnvironment    (optional) Reference to the preferred environment.
    */
    addListener(fListener, oEnvironment) {
        if (typeof (fListener) !== "function") {
            throw new df.Error(5131, "Listener must be a function (event: {{0}})", oEnvironment || null, [this.sEvent]);
        }
        if (!oEnvironment) {
            console.warn("df.events.addListener()/df.dom.on() without an oEnvironment is deprecated, it could cause the wrong listener to be removed.");
        }

        this.aListeners.push({ "fListener": fListener, "oEnvironment": oEnvironment });
    }


    /*
    @private
    
    Removes a listener from the event that is handled by the handler. It removes 
    the listener from the array and if it is the last listener it clears the 
    handler.
    
    @param  fListener   Reference to the handling method.
    @param  oEnvironment    (optional) Reference to the preferred environment.
    */
    removeListener(fListener, oEnvironment) {
        // deprecation check
        // BN: for some reason the oEnvironment was not previously specified.
        //     now that we do, we check whether oEnvironment was not null or undefined.
        //     if so we warn the end-user that the first event with that listener will be removed like it was done before.
        if (oEnvironment) {
            for (let i = 0; i < this.aListeners.length; i++) {
                if (this.aListeners[i].fListener === fListener && this.aListeners[i].oEnvironment === oEnvironment) {
                    if (this.bFiring) {
                        this.aRemoveListeners.push(this.aListeners[i]);
                    } else {
                        if (this.aListeners.length > 1) {
                            this.aListeners.splice(i, 1);
                        } else {
                            this.clear();
                        }
                    }

                    break;
                }
            }
        } else {
            console.warn("df.events.removeListener()/df.dom.off() without an oEnvironment is deprecated, it could cause the wrong listener to be removed.");

            for (let i = 0; i < this.aListeners.length; i++) {
                if (this.aListeners[i].fListener === fListener) {
                    if (this.bFiring) {
                        // this will stay the new way as it does not change.
                        this.aRemoveListeners.push(this.aListeners[i]);
                    } else {
                        if (this.aListeners.length > 1) {
                            this.aListeners.splice(i, 1);
                        } else {
                            this.clear();
                        }
                    }

                    break;
                }
            }
        }

    }


    /*
    @private
    
    Fires the event by creating a df.events.DOMEvent object and calling the 
    listeners in sequence. It "locks" the event handling using the bFiring boolean. 
    It stops if the event is cancelled. If listeners are removed during the 
    handling it will perform this action again.
    
    @param  e   Event object in some browsers.
    */
    fire(e) {
        // df.debug("---- " + this.sEvent + " ---- (" + this.aListeners.length + " handlers) ----");
        // console.log(this.eElement);

        //  Create event object
        const oEvent = new events.DOMEvent(e, this.eElement, this.sEvent);

        //  Lock
        this.bFiring = true;

        //  Call the listeners
        for (let i = 0; i < this.aListeners.length && !oEvent.bCanceled; i++) {
            if (typeof (this.aListeners[i].fListener) === "function") {
                try {
                    if (this.aListeners[i].fListener.call((this.aListeners[i].oEnvironment !== undefined ? this.aListeners[i].oEnvironment : this.eElement), oEvent) === false) {
                        oEvent.stop();
                    }
                } catch (oError) {
                    df.handleError(oError);
                }
            }
        }

        //  Unlock
        this.bFiring = false;

        //  Remove the listeners that where placed for removal during the event execution.
        while (this.aRemoveListeners.length > 0) {
            const oListener = this.aRemoveListeners.pop();
            this.removeListener(oListener.fListener, oListener.oEnvironment);
        }

        //  If the event is canceled we do anything we can to stop the event!
        if (oEvent.bCanceled) {
            // necessary for addEventListener, works with traditional
            if (e.preventDefault) {
                e.preventDefault();
            }
            // necessary for attachEvent, works with traditional
            e.returnValue = false;

            // works with traditional, not with attachEvent or addEventListener
            return false;
        }
        return true;
    }

};



/*
This class is used as a wrapper of the event object when using the AJAX Library 
event system to handle DOM events. It main purpose is to provide a browser 
independent API to handle the events. It is passed as parameter to the event 
handler method.

@code
function myInitForm(oForm){
    df.events.addDomListener("click", document.getElementById("mybutton"), myButtonClick);
}

function myButtonClick(oEvent){
    //  oEvent.eSource always contains a reference to the element on which the listener was attached.
    oEvent.eSource.value = "I am clicked!";
}

...

<input type="button" id="mybutton" value="Click me!"/>
@code
*/
events.DOMEvent = class DOMEvent {
    /*
    Constructor that takes the event object of the browser as a parameter.

    @param  e       Event object (in some browsers).
    @param  eSource Reference to the element to which the listener is attached.
    */
    constructor(e, eSource, sName) {
        /*
        Reference to the element to which the listener is attached.
        */
        this.eSource = eSource;
        /*
        Reference to the browsers event object.
        */
        if (!e) {
            this.e = window.event;
        } else {
            this.e = e;
        }
        /*
        Name of the event (used by the AJAX Library, without the "on").
        */
        this.sName = sName;

        // @privates
        this.bCanceled = false;
    }

    /*
Determines which DOM element has thrown the event. This can be a different 
element than to which the listeners is attached because events can bubble up in 
the DOM. Note that there are still some minor differences between the different 
browsers in the result of this function.
 
@return The DOM element that fired the event.
*/
    getTarget() {
        let eTarget;

        if (this.e.target) {
            eTarget = this.e.target; // W3C
        } else if (this.e.srcElement) {
            eTarget = this.e.srcElement;    // IE
        }

        if (eTarget.nodeType === 3) {
            eTarget = eTarget.parentNode; // Safari bug
        }

        return eTarget;
    }

    /*
    @return The horizontal mouse position.
    */
    getMouseX() {
        return this.e.clientX;
    }

    /*
    @return The vertical mouse position.
    */
    getMouseY() {
        return this.e.clientY;
    }

    /*
    @return The keycode from the key that is pressed.
    */
    getKeyCode() {
        //    if(this.e.keyCode){
        return this.e.keyCode;  // IE
        //    }else{
        //        return this.e.which; // W3C
        //    }
    }

    /*
    Determines wether the key event represents an special key (delete, home, 
    end, up, ...).
    
    @return True if the key is supposed to be special.
    */
    isSpecialKey() {
        const iKeyCode = this.getKeyCode();

        //  IE and webkit browsers do not fire keypress events for special keys
        if ((df.sys.isIE || df.sys.isSafari) && this.e.type === "keypress") {
            return false;
        }

        return (this.getAltKey() || this.getCtrlKey() || (events.KEY_CODE_SPECIAL[iKeyCode] && iKeyCode !== 0));
    }

    /*
    Determines if a key is printable based on the KeyboardEvent.key value.
    
    @return True if the keydown will result in a printable key.
    */
    isKeyPrintable() {
        return !this.getCtrlKey() && !this.getAltKey() && events.allKeys.indexOf(this.e.key) === -1;
    }

    /*
    @return String describing the pressed key (KeyboardEvent.key).
    */
    key() {
        return this.e.key;
    }

    /*
    Determines if an onInput event is caused by an insert operation.
    
    @return True if the input event is an insert operation.
    */
    inputIsInsert() {
        return events.insertInputTypes.indexOf(this.e.inputType) !== -1;
    }


    /*
    Returns the charcode fort his key press indicating the resulting character. 0 will be returned if 
    the keypress does not result in a character (except for older browsers where the difference can not 
    be established). 
    
    @return ASCII Character code.
    */
    getCharCode() {
        if (this.e.charCode) {
            return this.e.charCode;
        }

        //  For old browsers we use the keyCode which sometimes contains the charCode (Internet Explorer 8)
        if (typeof this.e.charCode !== "number") {
            return this.e.keyCode;
        }
        return 0;
    }

    /*
    @return True if the ctrl key was pressed.
    */
    getCtrlKey() {
        return this.e.ctrlKey;
    }

    /*
    @return True if the shift key was pressed.
    */
    getShiftKey() {
        return this.e.shiftKey;
    }

    /*
    @return True if the alt key was pressed.
    */
    getAltKey() {
        return this.e.altKey;
    }

    /*
    Checks which mouse button has been pressed if the event is a mouse event. 
    
    @return Integer indicating the clicked button according to the microsoft standard 
        (left: 1, middle: 4, right: 2).
    */
    getMouseButton() {
        if (this.e.which) { // W3C
            switch (this.e.which) {
                case 0:
                    return 1;
                case 1:
                    return 4;
                case 2:
                    return 2;
                default:
                    return 0;
            }
        } else { // IE
            return this.e.button;
        }
    }

    /*
    Determines the mousewheel action performed by the user.
    
    @return Integer indicating the action (up: >0, down: <0, none:0).
    */
    getMouseWheelDelta() {
        let iDelta = 0;

        if (this.e.detail) {
            //  Mozilla has multiple of 3 as detail
            iDelta = -this.e.detail / 3;
        } else if (this.e.wheelDelta) { // IE / Opera
            iDelta = this.e.wheelDelta / 120;
        }

        return iDelta;
    }

    /*
    Stops the event chain by setting bCanceled to true so the handling object 
    won't call other listeners and tries to stop the event bubbling further.
    */
    stop() {
        this.bCanceled = true;
        this.e.returnValue = false;
        this.e.cancelBubble = true;
        this.e.canceled = true;

        if (this.e.preventDefault) {
            this.e.preventDefault();
        }
        if (this.e.stopPropagation) {
            this.e.stopPropagation();
        }
    }

    /* 
    Stops the event from bubbling to parent elements without canceling the event and its default 
    behaviors.
    */
    stopPropagation() {
        if (this.e.stopPropagation) {
            this.e.stopPropagation();
        } else if (this.e.cancelBubble !== undefined) {
            this.e.cancelBubble = true;
        }
    }

    /* 
    Checks if the current event (only works for key events) matches the provided key definition(s). 
    
    @param  keydef  Object (or array of objects) representing a key combination 
                    { iKeyCode : 1, bCtrl : false, bShift : false, bAlt : false }.
    @return True if the key event matches one of the provided key definitions.
    */
    matchKey(keydef) {

        if (keydef) {
            if (keydef instanceof Array) {
                for (let i = 0; i < keydef.length; i++) {
                    if (keydef[i].iKeyCode === this.getKeyCode() &&
                        !!keydef[i].bCtrl === this.getCtrlKey() &&
                        !!keydef[i].bShift === this.getShiftKey() &&
                        !!keydef[i].bAlt === this.getAltKey()) {
                        return true;
                    }
                }
            } else {
                return (keydef.iKeyCode === this.getKeyCode() &&
                    !!keydef.bCtrl === this.getCtrlKey() &&
                    !!keydef.bShift === this.getShiftKey() &&
                    !!keydef.bAlt === this.getAltKey());
            }
        }
        return false;
    }

};


/*
Attach the clearDomHandlers method to the windows unload event to clean the 
events when the page is unloaded.
*/
events.addDomListener("unload", window, events.clearDomHandlers, window);

/*
The df.events.JShandler class contains the logic that is used to throw AJAX 
Library events. An event within the AJAX Library is nothing more than an 
instance of this class. The class maintains an array of listeners (and their 
environment references) that are added to this event. If the object throwing the 
event calls the fire method it will go through this array calling all the 
methods attached to this event. 

The example below shows how the event object can be used. The AJAX Library 
components have several events (usually with names startin with "on") that can 
be handled this way.
@code
function listener1(oEvent){
    //  Access the sPersonName property given with the event
    df.gui.alert("Hello " + oEvent.sPersonName);
    
    //  Stop the event so listener2 never gets called
    oEvent.stop();
}

function listener2(oEvent){
    df.gui.alert("This method should never be called..");
}

//  Create event object
var myEvent = new df.events.JSHandler();

//  Add listeners
myEvent.addListener(listener1);
myEvent.addListener(listener2);

//  Fire event
myEvent.fire(this, { sPersonName : "John" })
@code
*/
events.JSHandler = class JSHandler {
    /*
    Represents an event within the AJAX Library.
    */
    constructor(sOptServerName) {
        this.sServerName = sOptServerName || null;

        // @privates
        this.aListeners = [];

        this.aRemoveListeners = [];
        this.bFiring = false;
    }

    /*
    Adds a new listener to the handler by putting it into the aListeners array.
    
    @param  fListener       Function that will be called when the event occurs.
    @param  oEnvironment    The environment (this reference) in which the listeners 
            will be called.
            
    @deprecated
    */
    addListener(fListener, oEnvironment) {
        this.on(fListener, oEnvironment);
    }

    /* 
    Adds a new listener to the event.
    
    @param  fListener       Function that will be called when the event occurs.
    @param  oEnvironment    The environment (this reference) in which the listeners 
            will be called.
    */
    on(fListener, oEnv) {
        if (typeof (fListener) !== "function") {
            throw new df.Error(5131, "Listener must be a function", oEnv || null, [this.sEvent]);
        }

        this.aListeners.push({ "fListener": fListener, "oEnvironment": oEnv });
    }

    /*
    Removes the given listener from the handler by removing it from the aListeners
    array.
    
    @param  fListener   Function that was listening to the event.
    @param  oEnvironment    The environment (this reference) in which the listeners 
            will be called.
    */
    off(fListener, oEnv) {

        for (let iListener = 0; iListener < this.aListeners.length; iListener++) {
            if (this.aListeners[iListener].fListener === fListener && this.aListeners[iListener].oEnvironment === oEnv) {
                if (this.bFiring) {
                    this.aRemoveListeners.push(this.aListeners[iListener]);
                } else {
                    this.aListeners.splice(iListener, 1);
                }
            }
        }
    }

    /*
    Removes the given listener from the handler by removing it from the aListeners
    array.
    
    @param  fListener   Function that was listening to the event.
    @param  oEnvironment    The environment (this reference) in which the listeners 
            will be called.
    @deprecated
    */
    removeListener(fListener, oEnv) {
        this.off(fListener, oEnv);
    }

    /*
    The fire method that calls the listeners in a first registered = first called 
    sequence as long as bCanceled is false.
    
    @return bCanceled property of the event object.
    */
    fire(oSource, oOptions) {
        if (this.aListeners.length > 0) {

            const oEvent = (oOptions instanceof events.JSEvent ? oOptions : new events.JSEvent(oSource, oOptions));

            //  Lock
            this.bFiring = true;

            //  Call the listeners
            for (let iListener = 0; iListener < this.aListeners.length && !oEvent.bCanceled; iListener++) {
                if (typeof (this.aListeners[iListener].fListener) === "function") {
                    try {
                        if (this.aListeners[iListener].fListener.call((this.aListeners[iListener].oEnvironment !== undefined ? this.aListeners[iListener].oEnvironment : this.eElement), oEvent) === false) {
                            oEvent.stop();
                        }
                    } catch (oError) {
                        df.handleError(oError, oSource);
                    }
                }
            }

            //  Unlock
            this.bFiring = false;

            //  Remove the listeners that where placed for removal during the event execution.
            while (this.aRemoveListeners.length > 0) {
                const oListener = this.aRemoveListeners.pop();
                this.off(oListener.fListener, oListener.oEnvironment);
            }

            return !oEvent.bCanceled;
        }



        return true;
    }
};

/*
This class defines the API of the event that is given to event listeners by the 
AJAX Library event system. See df.events.JSHandler for an example of how this 
object can be used. Most events add event specific properties to this object. 
The important methods and properties are oSource and stop.
*/
events.JSEvent = class JSEvent {
    /*
    Constructor of the df.events.JSEvent class which takes two parameters.

    @param  oSource     Reference to the object throwing the event.
    @param  oOptions    Object with event options that are added to the object.
    */
    constructor(oSource, oOptions) {

        /*
        Reference to the object that has fired the event.
        */
        this.oSource = oSource;

        //  @privates
        this.bCanceled = false;

        if (typeof (oOptions) === "object") {
            for (const sProp in oOptions) {
                if (oOptions.hasOwnProperty(sProp)) {
                    this[sProp] = oOptions[sProp];
                }
            }
        }
    }

    /*
    Alternative for the oSource property so it is compatible with the DOMEvent.
    
    @return Reference to the element that fired event (this.oSource).
    */
    getTarget() {
        return this.oSource;
    }

    /*
    Can be used to stop the firing of the event. The rest of the listeners won't be
    called and true will be returned which usually causes the action that follows 
    by "Before" events to cancel.
    */
    stop() {
        this.bCanceled = true;
    }
};

//  Assemble flat array of all keys
events.allKeys = Object.keys(events.keys).reduce(function (acc, sKey) {
    return acc.concat(events.keys[sKey]);
}, []);