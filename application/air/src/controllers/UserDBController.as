package controllers
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	
	import events.UserDBControllerEvent;
	
	import models.UserModel;
	
	import oak.interfaces.IDestroyable;
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="userFound", type="events.UserDBControllerEvent")]
	[Event(name="noUserFound", type="events.UserDBControllerEvent")]
	public class UserDBController extends EventDispatcher implements IDestroyable
	{
		private var _destroyed:Boolean;
		
		private var _connection:SQLConnection;
		
		public function UserDBController()
		{
			_init();
		}
		
		private function _init():void
		{
			_connection = new SQLConnection(); 
			_connection.addEventListener(SQLEvent.OPEN, _openHandler); 
			_connection.addEventListener(SQLErrorEvent.ERROR, _errorHandler); 
			
			var folder:File = File.applicationStorageDirectory; 
			var dbFile:File = folder.resolvePath("/Users/johanhaneveld/Dropbox/WhosYaBuddha/app/assets/WhosYaBuddha.db"); 
			
			_connection.openAsync(dbFile); 
		}
		
		private function _openHandler(event:SQLEvent):void
		{
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function _errorHandler(event:SQLErrorEvent):void
		{
			LogController.log("db: " + event.type);
		}
		
		public function getUserByRFID(rfid:String):void
		{
			var sql:String =
				"SELECT firstName, lastName, twittername, rfid " +
				"FROM users " +
				"WHERE rfid='" + rfid + "'";
			
			var statement:SQLStatement = new SQLStatement();
			statement.addEventListener(SQLEvent.RESULT, _selectResultHandler); 
			statement.addEventListener(SQLErrorEvent.ERROR, _selectErrorHandler); 
			statement.sqlConnection = _connection;
			statement.text = sql; 
			statement.execute();
		}
		
		private function _selectResultHandler(event:SQLEvent):void
		{
			var statement:SQLStatement = event.currentTarget as SQLStatement;
			var result:SQLResult = statement.getResult();
			
			var e:UserDBControllerEvent;
			
			if (result.data.length)
			{
				e = new UserDBControllerEvent(UserDBControllerEvent.USER_FOUND);
				e.user = new UserModel(result.data[0]);
			} else
			{
				e = new UserDBControllerEvent(UserDBControllerEvent.NO_USER_FOUND);
				e.user = new UserModel();
				e.user.twittername = "Howdy stranger";
			}
			
			dispatchEvent(e);
		}

		private function _selectErrorHandler(event:SQLErrorEvent):void
		{
			LogController.log("db: " + event.type + " : " + event.error.message);
		}
		
		public function destroy():void
		{
			if (_destroyed) return;
			
			_connection.removeEventListener(SQLEvent.OPEN, _openHandler); 
			_connection.removeEventListener(SQLErrorEvent.ERROR, _errorHandler);
			_connection.close();
			_connection = null;
		}
		
		public function get destroyed():Boolean
		{
			return _destroyed;
		}
	}
}