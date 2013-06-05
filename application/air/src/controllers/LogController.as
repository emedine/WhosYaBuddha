package controllers
{
	import flash.text.TextField;
	
	import oak.interfaces.IDestroyable;

	public class LogController implements IDestroyable
	{
		static private var _instance:LogController;		
		
		static public function get instance():LogController
		{
			if (!_instance)
			{
				_instance = new LogController(new Singleton());
			}
			
			return _instance; 
		}
		
		private var _textfield:TextField;
		private var _destroyed:Boolean;
		
		public function LogController(singleton:Singleton)
		{
		}
		
		public function init(textfield:TextField):void
		{
			_textfield = textfield;
		}
		
		public function log(message:String):void
		{
			_textfield.appendText(message + "\n");
			_textfield.scrollV = _textfield.numLines;
		}
		
		static public function log(message:String):void
		{
			instance.log(message);
		}
		
		public function destroy():void
		{
			if (_destroyed) return;
			
			_textfield = null;
			_instance = null;
			
			_destroyed = true;
		}
		
		public function get destroyed():Boolean
		{
			return _destroyed;
		}
	}
}

class Singleton
{
}