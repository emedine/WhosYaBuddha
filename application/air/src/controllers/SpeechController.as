package controllers
{
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import oak.interfaces.IDestroyable;
	
	public class SpeechController extends EventDispatcher implements IDestroyable
	{
		private const LANGUAGE:String = "us";
		
		private var _channel:SoundChannel;
		private var _destroyed:Boolean;
		
		public function SpeechController()
		{
		}
		
		public function say(message:String):void
		{
			//if (phrase.length > 100) throw new Error("Google currently only supports phrases less than 100 characters in length.");
			var googleURL:String = "http://translate.google.co.uk/translate_tts?tl=" + LANGUAGE + "&q=" + encodeURI(message);
			
			var vars:URLVariables = new URLVariables();
			vars.url = googleURL;
			
			var req:URLRequest = new URLRequest("http://www.onebyonedesign.com/PHPFiles/proxy.php");
			req.method = URLRequestMethod.POST;
			req.data = vars;
			
			var speech:Sound = new Sound();
			speech.load(req);
			_channel = speech.play();
		}
		
		public function destroy():void
		{
			if (_destroyed) return;
			
			
			if (_channel)
			{
				_channel.stop();
				_channel = null;
			}
		}
		
		public function get destroyed():Boolean
		{
			return _destroyed;
		}
	}
}