package controllers
{
	import com.adobe.protocols.oauth2.OAuth2;
	import com.adobe.protocols.oauth2.event.GetAccessTokenEvent;
	import com.adobe.protocols.oauth2.event.IOAuth2Event;
	import com.adobe.protocols.oauth2.event.RefreshAccessTokenEvent;
	import com.adobe.protocols.oauth2.grant.AuthorizationCodeGrant;
	import com.adobe.protocols.oauth2.grant.IGrantType;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	import assets.Configuration;
	
	import events.CalendarControllerEvent;
	
	import models.CalendarEventModel;
	
	import oak.interfaces.IDestroyable;
	
	import org.as3commons.logging.setup.LogSetupLevel;
	
	[Event(name="gotEvent", type="events.CalendarControllerEvent")]
	[Event(name="complete", type="flash.events.Event")]
	public class CalendarController extends EventDispatcher implements IDestroyable
	{
		private const tokenFileName:String = "calendar_token.file";
		
		private const apiKey:String = Configuration.GOOGLE_API_KEY;
		private const clientID:String = Configuration.GOOGLE_CLIENT_ID;
		private const clientSecret:String = Configuration.GOOGLE_CLIENT_SECRET;
		private const redirectURI:String = "urn:ietf:wg:oauth:2.0:oob";
		
		private const calenderURL:String = "https://www.googleapis.com/calendar/v3/calendars/whosyabuddha%40gmail.com/events";
		
		private var _accesToken:String;
		private var _refreshToken:String;
		private var _expireToken:int;
		private var _tokenCreationDate:int;
		
		private var _destroyed:Boolean;
		
		private var _stage:Stage;
		private var _webView:StageWebView;
		
		private var _events:Vector.<CalendarEventModel>;
		
		private var _eventChecker:Timer;
		
		public function CalendarController(stage:Stage)
		{
			_stage = stage;
			
			_init();
		}
		
		private function _init():void
		{
			_checkForOauthToken();
			
			var oauth2:OAuth2 = new OAuth2("https://accounts.google.com/o/oauth2/auth", "https://accounts.google.com/o/oauth2/token", LogSetupLevel.DEBUG);
						
			if (_accesToken && _accesToken.length)
			{
				if (_checkTokenExpiration(_tokenCreationDate))
				{
					oauth2.addEventListener(RefreshAccessTokenEvent.TYPE, _refreshTokenHandler);
					oauth2.refreshAccessToken(_refreshToken, clientID, clientSecret);
				} else
				{
					_getCalender();
				}
			} else
			{
				_webView = new StageWebView();
				_webView.viewPort = new Rectangle(0, 0, _stage.stageWidth, _stage.stageHeight);
				_webView.stage = _stage;
				_webView.assignFocus();
				
				var grant:IGrantType = new AuthorizationCodeGrant(_webView, clientID, clientSecret, redirectURI, "https://www.googleapis.com/auth/calendar.readonly");
				
				oauth2.addEventListener(GetAccessTokenEvent.TYPE, _getAccesTokenHandler);
				oauth2.getAccessToken(grant);
			}
		}
		
		private function _refreshTokenHandler(event:RefreshAccessTokenEvent):void
		{
			_parseTokenEvent(event);
		}
		
		private function _getAccesTokenHandler(event:GetAccessTokenEvent):void
		{
			_webView.dispose();
			
			_parseTokenEvent(event);
		}
		
		private function _parseTokenEvent(event:IOAuth2Event):void
		{
			_accesToken = event.accessToken;
			_refreshToken = event.refreshToken;
			_expireToken = event.expiresIn;
			_tokenCreationDate = new Date().getTime();
			
			_saveOauthToken();
			
			_getCalender();
		}
		
		private function _getCalender():void
		{
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, _completeHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, _errorHandler);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _errorHandler);
			urlLoader.load(new URLRequest(calenderURL + "?key=" + apiKey + "&access_token=" + _accesToken));
		}
		
		private function _errorHandler(event:Event):void
		{
			trace(event.type);
			trace(event["text"]);
		}
		
		private function _completeHandler(event:Event):void 
		{
			_parseEventData(event.currentTarget.data);
			
			_eventChecker = new Timer(60000, 0);
			_eventChecker.addEventListener(TimerEvent.TIMER, _checkEventsHandler);
			_eventChecker.start();
			
			dispatchEvent(event);
		}
		
		private function _checkEventsHandler(event:TimerEvent):void
		{
			var model:CalendarEventModel;
			var time:Number = new Date().getTime();
			
			for each(model in _events) 
			{
				if ((model.date.getTime() - time) <= 0)
				{
					_events.splice(_events.indexOf(model), 1);
					
					var e:CalendarControllerEvent = new CalendarControllerEvent(CalendarControllerEvent.GOT_EVENT);
					e.model = model;
					dispatchEvent(e);
				}
			}
		}
		
		private function _parseEventData(value:String):void
		{
			var data:Object = JSON.parse(value);
			
			_events = new Vector.<CalendarEventModel>;
			var model:CalendarEventModel;
			
			for (var i:int = 0; i < data.items.length; i++) 
			{
				model = new CalendarEventModel(data.items[i]);
				_events.push(model);
			}
		}
		
		public function destroy():void
		{
			if (_destroyed) return;
			
			_stage = null;
			
			if (_webView)
			{
				_webView.dispose();
				_webView = null;
			}
			
			_destroyed = true;
		}
		
		private function _checkForOauthToken():void
		{
			var file:File = File.applicationStorageDirectory.resolvePath(tokenFileName);
			var fileStream:FileStream = new FileStream();
			
			if(file.exists)
			{
				fileStream.open(file, FileMode.READ);
				var data:Object = fileStream.readObject();
				fileStream.close();
				
				_accesToken = data.accesToken;
				_refreshToken = data.refreshToken;
				_expireToken = data.expireToken;
				_tokenCreationDate = data.tokenCreationDate;
			} else
			{
				_accesToken = "";
				_refreshToken = "";
				_expireToken = 0;
				_tokenCreationDate = 0;
			}
		}
		
		private function _saveOauthToken():void
		{
			var file:File = File.applicationStorageDirectory.resolvePath(tokenFileName);
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeObject({accesToken: _accesToken, refreshToken: _refreshToken, expireToken: _expireToken, tokenCreationDate: _tokenCreationDate});
			fileStream.close();
		}
		
		// returns true if the token is expired.
		private function _checkTokenExpiration(time:int):Boolean
		{
			 var difference:int = new Date().getTime() - time;
			 return (difference / 1000) >= _expireToken;
		}
		
		public function get destroyed():Boolean
		{
			return _destroyed;
		}
	}
}