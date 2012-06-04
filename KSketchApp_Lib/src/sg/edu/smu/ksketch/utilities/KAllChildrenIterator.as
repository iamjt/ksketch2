/**------------------------------------------------
* Copyright 2012 Singapore Management University
* All Rights Reserved
*
*-------------------------------------------------*/

package sg.edu.smu.ksketch.utilities
{
	import sg.edu.smu.ksketch.model.KGroup;
	import sg.edu.smu.ksketch.model.KObject;

	public class KAllChildrenIterator implements IIterator
	{
		private var _group:IModelObjectList;
		private var _time:Number;
		private var _iterators:Vector.<IIterator>;
		private var _currentIterator:IIterator;
		
		public function KAllChildrenIterator(group:KGroup, kskTime:Number)
		{
			_group = group;
			_time = kskTime;
			_currentIterator = group.directChildIterator(kskTime);
			_iterators = new Vector.<IIterator>();
			moveToNextLeaf();
		}
		
		public function hasNext():Boolean
		{
			return _currentIterator.hasNext();
		}
		
		public function next():KObject
		{
			if(!hasNext())
				throw new Error("No such element!");
			var nextObj:KObject = _currentIterator.next();
			moveToNextLeaf();
			return nextObj;
		}
		
		public function top():KObject
		{
			if(!hasNext())
				throw new Error("No such element!");
			
			return _currentIterator.top();
		}
		
		private function moveToNextLeaf():void
		{
			while(!_currentIterator.hasNext() && _iterators.length > 0)
				_currentIterator = _iterators.pop();
			
			if(!_currentIterator.hasNext())
				return;
			
			var nextObj:KObject = _currentIterator.top();
			if(nextObj is KGroup)
			{
				nextObj = _currentIterator.next();
				_iterators.push(_currentIterator);
				_currentIterator = (nextObj as KGroup).directChildIterator(_time);
				moveToNextLeaf();
			}
			// else, is leaf node already
		}
	}
}