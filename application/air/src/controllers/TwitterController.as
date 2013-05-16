package controllers
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.LocationChangeEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import flash.net.URLRequest;
	
	import assets.Configuration;
	
	import isle.susisu.twitter.Twitter;
	import isle.susisu.twitter.TwitterRequest;
	import isle.susisu.twitter.TwitterTokenSet;
	import isle.susisu.twitter.events.TwitterErrorEvent;
	import isle.susisu.twitter.events.TwitterRequestEvent;
	
	import oak.interfaces.IDestroyable;
	
	[Event(name="complete", type="flash.events.Event")]
	public class TwitterController extends EventDispatcher implements IDestroyable
	{
		private const tokenFileName:String = "twitter_token.file";
		
		private const consumerKey:String = Configuration.TWITTER_CONSUMER_KEY;
		private const consumerSecret:String = Configuration.TWITTER_CONSUMER_SECRET;
		
		private var _destroyed:Boolean;
		
		private var _twitter:Twitter;
		private var _token:TwitterTokenSet;
		
		private var _stage:Stage;
		private var _webView:StageWebView;
		
		public function TwitterController(stage:Stage)
		{
			_stage = stage;
			
			_init();
		}
		
		private function _init():void
		{
			_checkForOauthToken();
			
			var request:TwitterRequest
			
			if (_token)
			{
				_twitter = new Twitter(consumerKey, consumerSecret, _token.oauthToken, _token.oauthTokenSecret);
				request = _twitter.account_verifyCredentials();
				request.addEventListener(TwitterRequestEvent.COMPLETE, _verifyCompleteHandler);
				request.addEventListener(IOErrorEvent.IO_ERROR, _errorHandler);
				request.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _errorHandler);
				request.addEventListener(TwitterErrorEvent.CLIENT_ERROR, _errorHandler);
				request.addEventListener(TwitterErrorEvent.SERVER_ERROR, _errorHandler);
			} else
			{
				_twitter = new Twitter(consumerKey, consumerSecret);
				request = _twitter.oauth_requestToken();
				request.addEventListener(TwitterRequestEvent.COMPLETE, _tokenCompleteHandler);
				request.addEventListener(IOErrorEvent.IO_ERROR, _errorHandler);
				request.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _errorHandler);
				request.addEventListener(TwitterErrorEvent.CLIENT_ERROR, _errorHandler);
				request.addEventListener(TwitterErrorEvent.SERVER_ERROR, _errorHandler);
			}
		}
		
		private function _verifyCompleteHandler(event:TwitterRequestEvent):void
		{
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function _tokenCompleteHandler(event:TwitterRequestEvent):void
		{
			var request:URLRequest = new URLRequest(_twitter.getOAuthAuthorizeURL());
			
			_webView = new StageWebView();
			_webView.addEventListener(LocationChangeEvent.LOCATION_CHANGE, _locationChangeHandler);
			_webView.viewPort = new Rectangle(0, 0, _stage.stageWidth, _stage.stageHeight);
			_webView.stage = _stage;
			_webView.assignFocus();
			_webView.loadURL(request.url);
		}
		
		private function _locationChangeHandler(event:LocationChangeEvent):void
		{
			if (event.location.search("oauth_token") >= 0) return;
			
			_webView.loadURL("javascript:document.title=document.documentElement.innerHTML;");
			
			var pin:String = String(_webView.title.split('process:</span> <kbd aria-labelledby="code-desc"><code>')[1]).split("<")[0];
			
			if (pin.length)
			{
				_webView.removeEventListener(LocationChangeEvent.LOCATION_CHANGE, _locationChangeHandler);
				_webView.dispose();
				_webView = null;
				
				var request:TwitterRequest = _twitter.oauth_accessToken(pin);
				request.addEventListener(TwitterRequestEvent.COMPLETE, _pinRequestCompleteHandler);
			}
		}
		
		private function _pinRequestCompleteHandler(event:Event):void
		{
			var request:TwitterRequest = event.currentTarget as TwitterRequest;
			_token = _twitter.accessTokenSet;
			_saveOauthToken();
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function _checkForOauthToken():void
		{
			var file:File = File.applicationStorageDirectory.resolvePath(tokenFileName);
			var fileStream:FileStream = new FileStream();
			
			if(file.exists)
			{
				fileStream.open(file, FileMode.READ);
				var obj:Object = fileStream.readObject() as Object;
				fileStream.close();
				
				_token = new TwitterTokenSet(consumerKey, consumerSecret, obj.oauthToken, obj.oauthTokenSecret);
			} else
			{
				_token = null
			}
		}
		
		private function _saveOauthToken():void
		{
			var file:File = File.applicationStorageDirectory.resolvePath(tokenFileName);
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeObject({oauthToken: _token.oauthToken, oauthTokenSecret: _token.oauthTokenSecret});
			fileStream.close();
		}
		
		public function tweet(message:String):void
		{
			var request:TwitterRequest = _twitter.statuses_update(message);
			request.addEventListener(IOErrorEvent.IO_ERROR, _errorHandler);
			request.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _errorHandler);
			request.addEventListener(TwitterErrorEvent.CLIENT_ERROR, _errorHandler);
			request.addEventListener(TwitterErrorEvent.SERVER_ERROR, _errorHandler);
		}
		
		private function _errorHandler(event:Event):void
		{
			trace(event.type);
			
			if (event is TwitterErrorEvent)
			{
				trace(TwitterErrorEvent(event).statusCode);
			}
		}
		
		public function destroy():void
		{
			if (_destroyed) return;
			
			_stage = null;
			_twitter = null;
			_token = null;
			
			if (_webView)
			{
				_webView.removeEventListener(LocationChangeEvent.LOCATION_CHANGE, _locationChangeHandler);
				_webView.dispose();
				_webView = null;
			}
			
			_destroyed = true;
		}
		
		public function get destroyed():Boolean
		{
			return _destroyed;
		}
		
	}
}