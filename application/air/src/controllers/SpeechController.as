package controllers
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import oak.interfaces.IDestroyable;
	
	public class SpeechController extends EventDispatcher implements IDestroyable
	{
		private const VOICE_ENGLISH_MALE:String = "usenglishmale";
		
		private const URL:String = "http://www.ispeech.org/p/generic/getaudio?&action=convert&text=";
		private const VOICE:String = "&voice=";
		private const SPEED:String = "&speed=0";
		
		private const COMMERCIAL_LENGTH:int = 2350;
		
		private var _sound:Sound;
		private var _channel:SoundChannel;
		
		private var _startLoad:int;
		private var _endLoad:int;
		
		private var _busy:Boolean;
		private var _destroyed:Boolean;
		
		public function SpeechController()
		{
		}
		
		private function _progressHandler(event:ProgressEvent):void
		{
			_sound.removeEventListener(ProgressEvent.PROGRESS, _progressHandler);
			
			_startLoad = getTimer();
		}
		
		private function _completeHandler(event:Event):void
		{
			_sound.removeEventListener(Event.COMPLETE, _completeHandler);
			
			_endLoad = getTimer();
			
			var offset:int = (_sound.length - (_endLoad - _startLoad)) - COMMERCIAL_LENGTH;
			
			setTimeout(_cutOffCommercial, offset);
		}
		
		private function _cutOffCommercial():void
		{
			_channel.stop();
			
			_busy = false;
		}
		
		public function say(message:String):void
		{
			if (isBusy) return;
			
			_busy = true;
			
			_startLoad = 0;
			_endLoad = 0;
			
			var url:String = URL + encodeURI(message) + VOICE + VOICE_ENGLISH_MALE + SPEED;
			
			_sound = new Sound();
			_sound.addEventListener(Event.COMPLETE, _completeHandler);
			_sound.addEventListener(ProgressEvent.PROGRESS, _progressHandler);
			_sound.load(new URLRequest(url));
			
			_channel = _sound.play();
		}
		
		public function destroy():void
		{
			if (_destroyed) return;
			
			if (_sound)
			{
				_sound.removeEventListener(Event.COMPLETE, _completeHandler);
				_sound.removeEventListener(ProgressEvent.PROGRESS, _progressHandler);
				
				if (_sound.bytesLoaded < _sound.bytesTotal)
				{
					_sound.close();
				}
				
				_sound = null;
			}
			
			if (_channel)
			{
				_channel.stop();
				_channel = null;
			}
		}
		
		public function get isBusy():Boolean
		{
			return _busy;
		}
		
		public function get destroyed():Boolean
		{
			return _destroyed;
		}
	}
}