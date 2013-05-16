package assets
{
	import flash.display.Bitmap;
	import flash.events.Event;
	
	[Embed(source="/../assets/background.jpg", mimeType="image/jpeg")]
	public class BackgroundAsset extends Bitmap
	{
		public function BackgroundAsset()
		{
			addEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
			
			smoothing = true;
		}
		
		private function _addedToStageHandler(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
			
			stage.addEventListener(Event.RESIZE, _resizeHandler);
			
			_resizeHandler();
		}
		
		private function _resizeHandler(event:Event = null):void
		{
			width = stage.stageWidth;
			height = stage.stageHeight;
		}
	}
}