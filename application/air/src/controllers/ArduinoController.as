package controllers
{
	import com.quetwo.Arduino.ArduinoConnector;
	import com.quetwo.Arduino.ArduinoConnectorEvent;
	
	import flash.events.EventDispatcher;
	
	import events.ArduinoControllerEvent;
	
	import oak.interfaces.IDestroyable;
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="rfidFound", type="events.ArduinoControllerEvent")]
	public class ArduinoController extends EventDispatcher implements IDestroyable
	{
		private var _connector:ArduinoConnector;
		private var _destroyed:Boolean;
		
		public function ArduinoController()
		{
			_init();
		}
		
		private function _init():void
		{
			_connector = new ArduinoConnector();
			_connector.addEventListener("socketData", _socketDataHandler);
			_connector.connect("/dev/tty.usbmodemfa131", 19200);
		}
		
		private function _socketDataHandler(event:ArduinoConnectorEvent):void
		{
			var data:String = _connector.readBytesAsString();
			
			if (data.search("Code: ") > -1)
			{
				var e:ArduinoControllerEvent = new ArduinoControllerEvent(ArduinoControllerEvent.RFID_FOUND);
				e.rfid = data.split("Code: ")[1];
				dispatchEvent(e);
			}
		}
		
		public function destroy():void
		{
			if (_destroyed) return;
			
			_connector.dispose();
		}
		
		public function get destroyed():Boolean
		{
			return _destroyed;
		}
	}
}