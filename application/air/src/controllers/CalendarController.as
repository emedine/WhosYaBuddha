package controllers
{
	import com.adobe.protocols.oauth2.OAuth2;
	import com.adobe.protocols.oauth2.event.GetAccessTokenEvent;
	import com.adobe.protocols.oauth2.event.IOAuth2Event;
	import com.adobe.protocols.oauth2.event.RefreshAccessTokenEvent;
	import com.adobe.protocols.oauth2.grant.AuthorizationCodeGrant;
	import com.adobe.protocols.oauth2.grant.IGrantType;
	import com.adobe.utils.DateUtil;
	
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
		private var _tokenExpiresIn:int;
		private var _tokenCreationDate:Number;
		
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
				if (_checkTokenExpiration())
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
			_tokenExpiresIn = event.expiresIn;
			_tokenCreationDate = new Date().time;
			
			_saveOauthToken();
			
			_getCalender();
		}
		
		private function _getCalender():void
		{
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, _completeHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, _errorHandler);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _errorHandler);
			urlLoader.load(new URLRequest(calenderURL + "?key=" + apiKey + "&access_token=" + _accesToken + "&timeMin=" + DateUtil.toW3CDTF(new Date()).toString()));
		}
		
		private function _errorHandler(event:Event):void
		{
			LogController.log(event.type);
			LogController.log(event["text"]);
			
			_reset();
			_init();
		}
		
		private function _completeHandler(event:Event):void 
		{
			_parseEventData(event.currentTarget.data);
			
			if (!_eventChecker)
			{
				// check every half hour
				_eventChecker = new Timer(1800000, 0);
				_eventChecker.addEventListener(TimerEvent.TIMER, _checkEventsHandler);
			}
			
			_eventChecker.start();
			
			dispatchEvent(event);
		}
		
		private function _checkEventsHandler(event:TimerEvent):void
		{
			if (_checkTokenExpiration())
			{
				_eventChecker.stop();
				_init();
				return;
			}
				
			var time:Number = new Date().time;
			var model:CalendarEventModel;
			
			for each(model in _events) 
			{
				if ((model.date.time - time) <= 0)
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
			_events = new Vector.<CalendarEventModel>;
			
			var data:Object = JSON.parse(value);
			var model:CalendarEventModel;
			var time:Number = new Date().time;
			
			LogController.log("Amount calender items: " + data.items.length);
			
			for (var i:int = 0; i < data.items.length; i++) 
			{
				model = new CalendarEventModel(data.items[i]);
				
				if (model.date.time - time >= 0)
				{
					LogController.log(model.title + " - " + model.date);
					
					_events.push(model);
				}
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
				_tokenExpiresIn = data.expireToken;
				_tokenCreationDate = data.tokenCreationDate;
			} else
			{
				_reset();
			}
		}
		
		private function _saveOauthToken():void
		{
			var file:File = File.applicationStorageDirectory.resolvePath(tokenFileName);
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeObject({accesToken: _accesToken, refreshToken: _refreshToken, expireToken: _tokenExpiresIn, tokenCreationDate: _tokenCreationDate});
			fileStream.close();
		}
		
		private function _reset():void
		{
			_accesToken = "";
			_refreshToken = "";
			_tokenExpiresIn = 0;
			_tokenCreationDate = 0;
			
			_saveOauthToken();
		}
		
		// returns true if the token is expired.
		private function _checkTokenExpiration():Boolean
		{
			 return ((_tokenCreationDate - new Date().time) / 1000) >= _tokenExpiresIn;
		}
		
		public function get destroyed():Boolean
		{
			return _destroyed;
		}
	}
}