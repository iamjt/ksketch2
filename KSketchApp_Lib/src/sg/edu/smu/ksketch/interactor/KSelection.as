/**------------------------------------------------
* Copyright 2012 Singapore Management University
* All Rights Reserved
*
*-------------------------------------------------*/

package sg.edu.smu.ksketch.interactor
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import sg.edu.smu.ksketch.geom.KGeomUtil;
	import sg.edu.smu.ksketch.model.KGroup;
	import sg.edu.smu.ksketch.model.KObject;
	import sg.edu.smu.ksketch.utilities.IIterator;
	import sg.edu.smu.ksketch.utilities.IModelObjectList;
	import sg.edu.smu.ksketch.utilities.KModelObjectList;

	public class KSelection
	{
		private var _objects:KModelObjectList;
		
		private var _selectedTime:Number;
		
//		private var _rawData:Dictionary;
		
		private var _interactionCenter:Point;
		private var _userSetHandleOffset:Point;
		private var _fullObjectSet:KModelObjectList;
		
		public function KSelection(selection:KModelObjectList, selectedTime:Number)
		{
			_fullObjectSet = selection;
			_objects = selection;
			_selectedTime = selectedTime;
			if(selection == null || selection.length() == 0)
				throw new Error("Selection cann't be null or empty!");
		}
		
		public function get selectedTime():int
		{
			return _selectedTime;
		}

		public function get objects():KModelObjectList
		{
			return _objects;
		}
		
		public function set objects(value:KModelObjectList):void
		{
			_objects = value;
		}
		
		/**
		 * @return The center offset in object coordinate system.
		 */
		public function get userSetHandleOffset():Point
		{
			return _userSetHandleOffset;
		}
		
		/**
		 * @param value The new offset to be added to the existing center offset, 
		 * in object coordinate system.
		 */
		public function set userSetHandleOffset(value:Point):void
		{
			_userSetHandleOffset = value;
		}
		
		/**
		 * @param time KSK time
		 * @return The center of the selection. If no user set center exist, 
		 * this function will return the center of the keyframe at the given time.
		 */
		public function centerAt(time:Number):Point
		{
			if(_interactionCenter)
				return _interactionCenter;
			
			var c:Point;
			if(_objects.length() == 1)
			{
				var obj:KObject = _objects.getObjectAt(0);
				var m:Matrix = obj.getFullPathMatrix(time);
				c = obj.handleCenter(time);
				c = m.transformPoint(c);
				if(_userSetHandleOffset != null)
					c = c.add(_userSetHandleOffset);				
				
			}
			else
			{
				c = KGeomUtil.defaultCentroidOf(_objects, time);
				if(_userSetHandleOffset != null)
					c = c.add(_userSetHandleOffset);
			}
			trace(c);
			return c;
		}

		public function get interactionCenter():Point
		{
			return _interactionCenter;
		}

		public function set interactionCenter(value:Point):void
		{
			_interactionCenter = value;
		}
		
		public function contains(obj:KObject):Boolean
		{
			var it:IIterator = _objects.iterator;
			var currentObject:KObject;
			
			while(it.hasNext())
			{
				currentObject = it.next();
				if(currentObject.id == obj.id)
					return true;
				
				if(currentObject is KGroup)
					if((currentObject as KGroup).hasChild(obj, _selectedTime))
						return true;
			}
			
			return false;
		}
		
		public function tuneSelection(time:Number):void
		{
			var it:IIterator = _fullObjectSet.iterator;
			var currentObject:KObject;
			var visibleObjects:Vector.<KObject> = new Vector.<KObject>();
			
			while(it.hasNext())
			{
				currentObject = it.next();
				
				if(currentObject is KGroup)
				{
					trace("checking group",currentObject.id,"components");
					var visibleChildParts:Vector.<KObject> = (currentObject as KGroup).partsVisible(time);
					visibleObjects = visibleObjects.concat(visibleChildParts);
				}
				else
				{
					if(currentObject.getVisibility(time) > 0)
						visibleObjects.push(currentObject)
				}
			}
			
			var newList:KModelObjectList = new KModelObjectList();
			for(var i:int = 0; i<visibleObjects.length; i++)
			{
				newList.add(visibleObjects[i]);
			}
			
			_objects = newList;
		}
	}
}