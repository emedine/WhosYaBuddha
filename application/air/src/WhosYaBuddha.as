package
{
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import assets.BackgroundAsset;
	
	import controllers.ArduinoController;
	import controllers.CalendarController;
	import controllers.LogController;
	import controllers.SoundFXController;
	import controllers.TweetDBController;
	import controllers.TwitterController;
	import controllers.UserDBController;
	
	import events.ArduinoControllerEvent;
	import events.CalendarControllerEvent;
	import events.TwitterControllerEvent;
	import events.UserDBControllerEvent;
	
	[SWF(width="1280", height="720")]
	public class WhosYaBuddha extends Sprite
	{
		private var _timer:Timer;
		
		private var _log:LogController;
		private var _rfid:ArduinoController;
		private var _db:UserDBController;
		private var _message:TweetDBController;
		private var _calendar:CalendarController;
		private var _twitter:TwitterController;
		private var _sound:SoundFXController;
		
		private var _background:BackgroundAsset;
		
		public function WhosYaBuddha()
		{
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, _exitHandler);
			
			_initBackground();
			_initText();
			//_initRFID();
			_initDatabase();
			_initMessage();
			_initCalender()
			_initTwitter();
			_initSound();
		}
		
		private function _initBackground():void
		{
			_background = new BackgroundAsset();
			addChild(_background);
		}		
		
		private function _initText():void
		{
			var text:TextField = new TextField();
			text.multiline = text.wordWrap = true;
			text.width = stage.stageWidth;
			text.height = stage.stageHeight;
			text.defaultTextFormat = new TextFormat("Sans", 20, 0xF5F5F5);
			addChild(text);
			
			_log = LogController.instance;
			_log.init(text);
			_log.log("init");
		}
		
		private function _initRFID():void
		{
			_rfid = new ArduinoController();
			_rfid.addEventListener(Event.COMPLETE, _rfidCompleteHandler);
			_rfid.addEventListener(ArduinoControllerEvent.RFID_FOUND, _rfidFoundHandler);
		}
		
		private function _rfidCompleteHandler(event:Event):void
		{
			_rfid.removeEventListener(Event.COMPLETE, _rfidCompleteHandler);
			
			_log.log("rfid ready");
		}
		
		private function _rfidFoundHandler(event:ArduinoControllerEvent):void
		{
			_log.log("rfid: " + event.rfid);
			_db.getUserByRFID(event.rfid);
		}
		
		private function _initDatabase():void
		{
			_db = new UserDBController();
			_db.addEventListener(Event.COMPLETE, _dbCompleteHandler);
			_db.addEventListener(UserDBControllerEvent.USER_FOUND, _dbHandler);
		}
		
		private function _dbCompleteHandler(event:Event):void
		{
			_db.removeEventListener(Event.COMPLETE, _dbCompleteHandler);
			
			_log.log("user db ready");
		}
		
		private function _dbHandler(event:UserDBControllerEvent):void
		{
			switch (event.type)
			{
				case UserDBControllerEvent.USER_FOUND:
				{
					_createTweet(event.user);
					break;
				}
				case UserDBControllerEvent.NO_USER_FOUND:
				{
					_createTweet(event.user);
					break;
				}
			}
		}
		
		private function _initMessage():void
		{
			_message = new TweetDBController();
			_message.addEventListener(Event.COMPLETE, _messageCompleteHandler);
		}
		
		private function _messageCompleteHandler(event:Event):void
		{
			_message.removeEventListener(Event.COMPLETE, _messageCompleteHandler);
			
			_log.log("tweet db ready");
		}
		
		private function _initCalender():void
		{
			_calendar = new CalendarController(stage);
			_calendar.addEventListener(Event.COMPLETE, _calenderCompletehandler);
			_calendar.addEventListener(CalendarControllerEvent.GOT_EVENT, _gotEventHandler);
		}
		
		private function _calenderCompletehandler(event:Event):void
		{
			_calendar.removeEventListener(Event.COMPLETE, _calenderCompletehandler);
			_log.log("calendar ready");
		}
		
		private function _gotEventHandler(event:CalendarControllerEvent):void
		{
			_log.log("got calender event: " + event.model.title);
			
			_createTweet(event.model);
		}
		
		private function _initTwitter():void
		{
			_twitter = new TwitterController(stage);
			_twitter.addEventListener(Event.COMPLETE, _tweetCompleteHandler);
			_twitter.addEventListener(TwitterControllerEvent.GOT_MENTION, _mentionHandler);
		}
		
		private function _mentionHandler(event:TwitterControllerEvent):void
		{
			_createTweet(event.data);
		}
		
		private function _tweetCompleteHandler(event:Event):void
		{
			_twitter.removeEventListener(Event.COMPLETE, _tweetCompleteHandler);
			
			_log.log("twitter ready");
		}
		
		private function _initSound():void
		{
			_sound = new SoundFXController();
		}
		
		private function _createTweet(model:* = null):void
		{
			var message:String = _message.generate(model);
			
			_log.log("tweet: " + message);
			
			_twitter.tweet(message);
			_sound.play();
		}
		
		private function _exitHandler(event:Event):void
		{
			NativeApplication.nativeApplication.removeEventListener(Event.EXITING, _exitHandler);
			
			if (_rfid)
			{
				_rfid.destroy();
				_rfid.removeEventListener(Event.COMPLETE, _rfidCompleteHandler);
				_rfid.removeEventListener(ArduinoControllerEvent.RFID_FOUND, _rfidFoundHandler);
				_rfid = null;
			}
			
			_db.destroy();
			_db.removeEventListener(Event.COMPLETE, _dbCompleteHandler);
			_db.removeEventListener(UserDBControllerEvent.USER_FOUND, _dbHandler);
			_db = null;
			
			_message.destroy();
			_message = null;
			
			_twitter.destroy();
			_twitter.removeEventListener(Event.COMPLETE, _tweetCompleteHandler);
			_twitter = null;
			
			_sound.destroy();
			_sound = null;
		}
	}
}