package;

#if hxdiscord_rpc
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.sound.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end
#if (sys && MODS_ALLOWED && PRELOAD_ALL)
import openfl.media.Sound;
import openfl.system.System;
import sys.thread.Deque;
import sys.thread.Thread;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.loadTheFirstEnabledMod();

		/*		//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		for (i in 0...initSonglist.length)
		{
			if(initSonglist[i] != null && initSonglist[i].length > 0) {
				var songArray:Array<String> = initSonglist[i].split(":");
				addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
			}
		}*/

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			grpSongs.add(songText);

			var maxWidth = 980;
			if (songText.width > maxWidth)
			{
				songText.scaleX = maxWidth / songText.width;
			}
			songText.snapToPosition();

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeSelection();
		changeDiff();

		#if (sys && MODS_ALLOWED && PRELOAD_ALL)
		startPreload();
		#end

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);
			this.songs[this.songs.length-1].color = weekColor;

			if (songCharacters.length != 1)
				num++;
		}
	}*/

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		#if (sys && MODS_ALLOWED && PRELOAD_ALL)
		pollPreload();
		#end

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		// Sarv Engine HUD only: the background beats to the BPM of the song that is playing
		var zavodila:Bool = false;
		if (ClientPrefs.data.sarvEngineHud)
		{
			if (bgBpm > 0 && FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				var beat:Int = Math.floor(FlxG.sound.music.time / (60000 / bgBpm));
				if (beat != bgLastBeat)
				{
					bgLastBeat = beat;
					bgPulse = 1;
				}
			}
			bgPulse = FlxMath.lerp(0, bgPulse, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));

			zavodila = bgBpm > 0 && isZavodila();
			var beatScale:Float = 1 + (zavodila ? zavodilaBeatScale : bgBeatScale) * bgPulse;
			bg.scale.set(beatScale, beatScale);
			// Zavodila: the background shakes on every beat too
			bg.offset.set(zavodila ? FlxG.random.float(-1, 1) * zavodilaBgShake * bgPulse : 0, zavodila ? FlxG.random.float(-1, 1) * zavodilaBgShake * bgPulse : 0);
		}

		// take last frame's text shake off before the menu items lerp toward their positions
		if (textShakeX != 0 || textShakeY != 0)
		{
			for (item in grpSongs.members)
			{
				if (item != null)
				{
					item.x -= textShakeX;
					item.y -= textShakeY;
				}
			}
			textShakeX = 0;
			textShakeY = 0;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore;
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(songs.length > 1)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}
		}

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		else if (controls.UI_RIGHT_P)
			changeDiff(1);
		else if (upP || downP) changeDiff();

		if (controls.BACK)
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if(ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if (accepted)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			/*#if MODS_ALLOWED
			if(!sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
			#else
			if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
			#end
				poop = songLowercase;
				curDifficulty = 1;
				trace('Couldnt find file');
			}*/
			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			if(colorTween != null) {
				colorTween.cancel();
			}
			
			if (FlxG.keys.pressed.SHIFT){
				LoadingState.loadAndSwitchState(new ChartingState());
			}else{
				LoadingState.loadAndSwitchState(new PlayState());
			}

			FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();

			#if (sys && MODS_ALLOWED && PRELOAD_ALL)
			keepOnLeave = instLocation(songs[curSelected]).cacheKey; // the song is about to use it
			#end
		}
		else if(controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		super.update(elapsed);

		// Zavodila: the song text shakes a little on every beat
		if (zavodila && bgPulse > 0.01)
		{
			textShakeX = FlxG.random.float(-1, 1) * zavodilaTextShake * bgPulse;
			textShakeY = FlxG.random.float(-1, 1) * zavodilaTextShake * bgPulse;
			for (item in grpSongs.members)
			{
				if (item != null)
				{
					item.x += textShakeX;
					item.y += textShakeY;
				}
			}

			// the icons shake too. They snap back to their song text in their own update every frame,
			// so there is nothing to undo here.
			var iconShakeX:Float = FlxG.random.float(-1, 1) * zavodilaIconShake * bgPulse;
			var iconShakeY:Float = FlxG.random.float(-1, 1) * zavodilaIconShake * bgPulse;
			for (icon in iconArray)
			{
				if (icon != null)
				{
					icon.x += iconShakeX;
					icon.y += iconShakeY;
				}
			}
		}
	}

	// ---- background beat (follows the BPM of the song being played) ----
	/** Background size added on a beat (1 = +100%). */
	public static var bgBeatScale:Float = 0.04;
	/** Zavodila: bigger beat, background shake and text shake. */
	public static var zavodilaBeatScale:Float = 0.12;
	public static var zavodilaBgShake:Float = 14; // pixels
	public static var zavodilaTextShake:Float = 4; // pixels
	public static var zavodilaIconShake:Float = 6; // pixels

	var bgBpm:Float = 0;
	var bgLastBeat:Int = -1;
	var bgPulse:Float = 0; // 1 on a beat, eases back to 0
	var bgBpmCache:Map<String, Float> = new Map();
	var textShakeX:Float = 0;
	var textShakeY:Float = 0;

	function isZavodila():Bool
	{
		return Paths.formatToSongPath(songs[curSelected].songName) == 'zavodila';
	}

	/** BPM from the song's chart (cached). 0 when the chart can't be read. */
	function songBpm(song:SongMetadata):Float
	{
		var oldDir:String = Paths.currentModDirectory;
		Paths.currentModDirectory = song.folder;

		var lower:String = Paths.formatToSongPath(song.songName);
		var key:String = song.folder + '/' + lower;
		if (!bgBpmCache.exists(key))
		{
			var bpm:Float = 0;
			for (chartName in [Highscore.formatSong(lower, curDifficulty), lower])
			{
				try
				{
					bpm = Song.loadFromJson(chartName, lower).bpm;
				}
				catch (e:Dynamic) {}
				if (bpm > 0)
					break;
			}
			bgBpmCache.set(key, bpm);
		}

		Paths.currentModDirectory = oldDir;
		return bgBpmCache.get(key);
	}

	// ---- preload every song's instrumental while Freeplay is open, unload when leaving ----
	#if (sys && MODS_ALLOWED && PRELOAD_ALL)
	var preloadQueue:Deque<{key:String, sound:Sound}> = new Deque();
	var preloadStop:Bool = false;
	/** Cache key of the inst that must survive leaving Freeplay (the song being played). */
	var keepOnLeave:String = null;

	/** Where Paths.returnSound loads a song's Inst from, and the key it caches it under. */
	function instLocation(song:SongMetadata):{file:String, cacheKey:String}
	{
		Paths.currentModDirectory = song.folder;
		var key:String = Paths.formatToSongPath(song.songName) + '/Inst';
		var modFile:String = Paths.modsSounds('songs', key);
		if (FileSystem.exists(modFile))
			return {file: modFile, cacheKey: modFile};

		var gotten:String = Paths.getPath('songs/' + key + '.' + Paths.SOUND_EXT, SOUND, null);
		gotten = gotten.substring(gotten.indexOf(':') + 1, gotten.length);
		return {file: './' + gotten, cacheKey: gotten};
	}

	/** Decodes every inst on a background thread (nearest to the selection first). */
	function startPreload():Void
	{
		var oldDir:String = Paths.currentModDirectory;
		var order:Array<Int> = [for (i in 0...songs.length) i];
		order.sort(function(a:Int, b:Int) return Std.int(Math.abs(a - curSelected)) - Std.int(Math.abs(b - curSelected)));

		var jobs:Array<{file:String, key:String}> = [];
		var queued:Map<String, Bool> = new Map();
		for (i in order)
		{
			var loc = instLocation(songs[i]);
			if (queued.exists(loc.cacheKey) || Paths.currentTrackedSounds.exists(loc.cacheKey) || !FileSystem.exists(loc.file))
				continue;
			queued.set(loc.cacheKey, true);
			jobs.push({file: loc.file, key: loc.cacheKey});
		}
		Paths.currentModDirectory = oldDir;

		if (jobs.length == 0)
			return;

		preloadStop = false;
		Thread.create(function()
		{
			for (job in jobs)
			{
				if (preloadStop)
					break;
				var snd:Sound = null;
				try
				{
					snd = Sound.fromFile(job.file);
				}
				catch (e:Dynamic) {}
				if (snd != null && !preloadStop)
					preloadQueue.add({key: job.key, sound: snd});
			}
		});
	}

	/** Moves finished songs into the cache (on the main thread, the cache is not thread safe). */
	function pollPreload():Void
	{
		var item = preloadQueue.pop(false);
		while (item != null)
		{
			if (!Paths.currentTrackedSounds.exists(item.key))
				Paths.currentTrackedSounds.set(item.key, item.sound);
			else
				closeSound(item.sound);
			item = preloadQueue.pop(false);
		}
	}

	function closeSound(snd:Sound):Void
	{
		try
		{
			snd.close();
		}
		catch (e:Dynamic) {}
	}

	/** Stops the loader and frees every song inst, except the one being taken into the song. */
	function unloadInsts():Void
	{
		preloadStop = true;

		var item = preloadQueue.pop(false);
		while (item != null)
		{
			closeSound(item.sound);
			item = preloadQueue.pop(false);
		}

		var oldDir:String = Paths.currentModDirectory;
		for (song in songs)
		{
			var loc = instLocation(song);
			if (loc.cacheKey == keepOnLeave)
				continue;
			var snd:Sound = Paths.currentTrackedSounds.get(loc.cacheKey);
			if (snd != null)
			{
				Paths.currentTrackedSounds.remove(loc.cacheKey);
				closeSound(snd);
			}
		}
		Paths.currentModDirectory = oldDir;
		System.gc();
	}
	#end

	override function destroy()
	{
		#if (sys && MODS_ALLOWED && PRELOAD_ALL)
		unloadInsts();
		#end
		super.destroy();
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = CoolUtil.difficultyString();
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		// 0.2.5: the instrumental of the song you are on plays, starting from 0 volume (update() fades it in).
		// Runs when the menu opens and whenever the selection moves, not when a substate closes.
		#if PRELOAD_ALL
		if (change != 0 || instPlaying == -1)
		{
			var inst:Any = Paths.inst(songs[curSelected].songName);
			if (inst != null)
			{
				FlxG.sound.playMusic(inst, 0);
				instPlaying = curSelected;
				bgBpm = ClientPrefs.data.sarvEngineHud ? songBpm(songs[curSelected]) : 0;
				bgLastBeat = -1;
			}
		}
		#end

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}