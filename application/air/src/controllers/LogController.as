package controllers
{
	import flash.text.TextField;

	public class LogController
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
	}
}

class Singleton
{
}