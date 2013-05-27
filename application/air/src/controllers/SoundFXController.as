package controllers
{
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	
	import oak.interfaces.IDestroyable;
	
	public class SoundFXController extends EventDispatcher implements IDestroyable
	{
		[Embed(source="/../assets/gong.mp3")]
		private const GongSoundEmbed:Class;
		
		private var _sound:Sound;
		private var _channel:SoundChannel;
		private var _destroyed:Boolean;
		
		public function SoundFXController()
		{
			_sound = new GongSoundEmbed() as Sound;
		}
		
		public function play():void
		{
			_channel = _sound.play();
		}
		
		public function destroy():void
		{
			if (_destroyed) return;
			
			_sound = null;
			
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