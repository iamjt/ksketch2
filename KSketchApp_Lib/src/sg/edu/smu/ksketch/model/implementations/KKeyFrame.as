/***************************************************
*Copyright 2010-2012 Singapore Management University
*Developed under a grant from the Singapore-MIT GAMBIT Game Lab

*This Source Code Form is subject to the terms of the
*Mozilla Public License, v. 2.0. If a copy of the MPL was
*not distributed with this file, You can obtain one at
*http://mozilla.org/MPL/2.0/.
****************************************************/

package sg.edu.smu.ksketch.model.implementations
{
	import sg.edu.smu.ksketch.model.IKeyFrame;
	import sg.edu.smu.ksketch.utilities.KAppState;
	
	public class KKeyFrame implements IKeyFrame
	{
		protected var _previous:KKeyFrame;
		protected var _next:KKeyFrame;
		protected var _endTime:Number;
		protected var _frameNumber:int;
		
		public function KKeyFrame(time:Number)
		{
			_endTime = time;
		}
		
		/**
		 * Defines the preceding key frame in the list
		 */
		public function get previous():IKeyFrame
		{
			return _previous as IKeyFrame;
		}
		
		public function set previous(keyframe:IKeyFrame):void
		{
			_previous = keyframe as KKeyFrame;
		}
		
		/**
		 * Defines the next key frame in the list
		 */
		public function get next():IKeyFrame
		{
			return _next as IKeyFrame;
		}
		
		public function set next(keyframe:IKeyFrame):void
		{
			_next = keyframe as KKeyFrame;	
		}
		
		/**
		 * Defines the end time of this key frame
		 */
		public function get endTime():Number
		{
			return _endTime;
		}
		
		public function set endTime(value:Number):void
		{
			_endTime = value;
		}
		
		public function get frameNumber():int
		{
			return _frameNumber;
		}
		
		public function clone():IKeyFrame
		{
			var cloneKey:KKeyFrame = new KKeyFrame(endTime);
			
			return cloneKey;
		}
		
		/**
		 * Returns the start time of this key
		 */
		public function startTime():Number
		{
			var prevEndTime:Number = 0;
			
			if(previous)
				prevEndTime += previous.endTime;
			
			return prevEndTime;
		}
		
		/**
		 * Retimes the keyframe
		 */
		public function retimeKeyframe(newTime:Number):void
		{
			_endTime = newTime;
			
			if(_previous)
			{
				if(_previous.endTime == _endTime)
					_endTime += KAppState.ANIMATION_INTERVAL;
					
				if(_next)
					_next.retimeKeyframe(_next.endTime);
				
			}
					
		}
	}
}