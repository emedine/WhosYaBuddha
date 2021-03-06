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
	
	import avmplus.getQualifiedClassName;
	
	import models.CalendarEventModel;
	import models.MentionModel;
	import models.TweetModel;
	import models.UserModel;
	
	import oak.interfaces.IDestroyable;
	import oak.math.Random;
	
	public class TweetDBController extends EventDispatcher implements IDestroyable
	{
		private var _destroyed:Boolean;
		
		private var _connection:SQLConnection;
		private var _userTweets:Vector.<TweetModel>;
		private var _buddhaTweets:Vector.<TweetModel>;
		
		public function TweetDBController()
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
			var sql:String =
				"SELECT message, type " +
				"FROM tweets";
			
			var statement:SQLStatement = new SQLStatement();
			statement.addEventListener(SQLEvent.RESULT, _selectResultHandler); 
			statement.addEventListener(SQLErrorEvent.ERROR, _errorHandler); 
			statement.sqlConnection = _connection;
			statement.text = sql; 
			statement.execute();
		}
		
		private function _selectResultHandler(event:SQLEvent):void
		{
			_connection.removeEventListener(SQLEvent.OPEN, _openHandler); 
			_connection.removeEventListener(SQLErrorEvent.ERROR, _errorHandler);
			_connection.close();
			_connection = null;
			
			_userTweets = new Vector.<TweetModel>;
			_buddhaTweets = new Vector.<TweetModel>;
			
			var statement:SQLStatement = event.currentTarget as SQLStatement;
			var result:SQLResult = statement.getResult();
			var tweets:Array = result.data;
			var tweet:TweetModel;
			
			for (var i:int = 0; i < tweets.length; i++) 
			{
				tweet = new TweetModel(tweets[i]);
				
				switch (tweet.type)
				{
					case TweetType.USER:
					{
						_userTweets.push(tweet);
						break;
					}
					case TweetType.BUDDHA:
					{
						_buddhaTweets.push(tweet);
						break;
					}
				}
			}
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function _errorHandler(event:SQLErrorEvent):void
		{
			LogController.log("db: " + event.type + " : " + event.error.message);
		}
		
		public function generate(model:Object = null):String
		{
			var tweet:TweetModel;
			var message:String;
			
			if (model)
			{
				switch (getQualifiedClassName(model))
				{
					case getQualifiedClassName(UserModel):
					{
						tweet = _userTweets[Random.integer(0, _userTweets.length - 1)];
						message = "@" + UserModel(model).twittername + " " + tweet.message;
						break;
					}
					case getQualifiedClassName(MentionModel):
					{
						tweet = _userTweets[Random.integer(0, _userTweets.length - 1)];
						message = "@" + MentionModel(model).screenName + " " + tweet.message;
						break;
					}
					case getQualifiedClassName(CalendarEventModel):
					{
						tweet = new TweetModel();
						
						var event:CalendarEventModel = CalendarEventModel(model);
						
						if (event && event.description && event.description.length)
						{
							message = event.description;
						} else
						{
							message = _buddhaTweets[Random.integer(0, _buddhaTweets.length - 1)].message;
						}
						break;
					}
				}
			} else
			{
				message = _buddhaTweets[Random.integer(0, _buddhaTweets.length - 1)].message;
			}
			
			return message;
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