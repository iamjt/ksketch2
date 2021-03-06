/***************************************************
*Copyright 2010-2012 Singapore Management University
*Developed under a grant from the Singapore-MIT GAMBIT Game Lab

*This Source Code Form is subject to the terms of the
*Mozilla Public License, v. 2.0. If a copy of the MPL was
*not distributed with this file, You can obtain one at
*http://mozilla.org/MPL/2.0/.
****************************************************/

package sg.edu.smu.ksketch.components
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import sg.edu.smu.ksketch.model.IKeyFrame;
	import sg.edu.smu.ksketch.model.IReferenceFrame;
	import sg.edu.smu.ksketch.model.ISpatialKeyframe;
	import sg.edu.smu.ksketch.model.KGroup;
	import sg.edu.smu.ksketch.model.KObject;
	import sg.edu.smu.ksketch.model.geom.KPath;
	import sg.edu.smu.ksketch.model.geom.KPathPoint;
	import sg.edu.smu.ksketch.model.implementations.KSpatialKeyFrame;
	import sg.edu.smu.ksketch.operation.KTransformMgr;
	import sg.edu.smu.ksketch.utilities.KAppState;
	
	public class KPathView extends Sprite
	{
		protected static const _THICKNESS_THIN:int = 2;
		protected static const _THICKNESS_THICK:int = 4;
				
		protected var _object:KObject;
		protected var _pathR:Sprite;
		protected var _pathS:Sprite;
		protected var _pathT:Sprite;
		
		public static var lightColors:Dictionary = new Dictionary();
		public static var colors:Dictionary = new Dictionary();
		
		colors[KTransformMgr.TRANSLATION_REF] = 0x0000FF;
		lightColors[KTransformMgr.TRANSLATION_REF] = 0xBFBFFF;
		colors[KTransformMgr.ROTATION_REF] = 0x33CC00;
		lightColors[KTransformMgr.ROTATION_REF] = 0x99FF99;
		colors[KTransformMgr.SCALE_REF] = 0xCC0033;
		lightColors[KTransformMgr.SCALE_REF] = 0xD27D92;
		
		public function KPathView(object:KObject)
		{
			super();
			_pathR = new Sprite();
			_pathS = new Sprite();
			_pathT = new Sprite();
			addChild(_pathR);
			addChild(_pathS);
			addChild(_pathT);
			_object = object;
		}
		
		public function get object():KObject
		{
			return _object;
		}
		
		public function getTranslatePath():Sprite
		{
			return _pathT;
		}
		
		public function getRotatePath():Sprite
		{
			return _pathR;
		}
		
		public function getScalePath():Sprite
		{
			return _pathS;
		}
		
		public function clear():void
		{
			_pathT.graphics.clear();
			_pathR.graphics.clear();
			_pathS.graphics.clear();
		}
		
		public function redraw(time:Number, showAll:Boolean):void
		{
			clear();
			var toDrawKey:ISpatialKeyframe;
			
			toDrawKey = _getKeyToDraw(KTransformMgr.TRANSLATION_REF,time,showAll);
			
			_drawKeyPaths(toDrawKey, showAll, KTransformMgr.TRANSLATION_REF, time);
			if(toDrawKey && time == toDrawKey.endTime && toDrawKey.next && !showAll)
				_drawKeyPaths(toDrawKey.next as ISpatialKeyframe, showAll, KTransformMgr.TRANSLATION_REF, time);
			
			toDrawKey = _getKeyToDraw(KTransformMgr.ROTATION_REF,time,showAll);
			_drawKeyPaths(toDrawKey, showAll, KTransformMgr.ROTATION_REF, time);
			if(toDrawKey && time == toDrawKey.endTime && toDrawKey.next && !showAll)
				_drawKeyPaths(toDrawKey.next as ISpatialKeyframe, showAll, KTransformMgr.ROTATION_REF, time);
			
			toDrawKey = _getKeyToDraw(KTransformMgr.SCALE_REF,time,showAll);
			_drawKeyPaths(toDrawKey, showAll, KTransformMgr.SCALE_REF, time);
			if(toDrawKey && time == toDrawKey.endTime && toDrawKey.next && !showAll)
				_drawKeyPaths(toDrawKey.next as ISpatialKeyframe, showAll, KTransformMgr.SCALE_REF, time);
		}
		
		protected function _drawKeyPaths(targetKey:ISpatialKeyframe,showAll:Boolean, type:int, time:Number):void
		{
			var position:Point;
			var transformAtTime:Matrix;
			var duration:Number;
			var elapsedTime:Number;
			var proportionCovered:Number;
			var drawThisKey:Boolean = false;
			
			while(targetKey)
			{
				duration = targetKey.endTime - targetKey.startTime();
				
				if(duration <= 0)
					drawThisKey = false;
				else
					drawThisKey = true;
				
				if(drawThisKey)
				{
					elapsedTime = time - targetKey.startTime();
					
					if(duration > 0)
						proportionCovered = elapsedTime/duration;
					else
					{
						if(elapsedTime >= duration)
							proportionCovered = 1;
						else
							proportionCovered = 0;
					}
					
					if(type == KTransformMgr.TRANSLATION_REF)
					{
						transformAtTime = _object.getFullPathMatrix(targetKey.startTime()+1);
						
						if(object is KGroup)
							position = (_object as KGroup).getCentroid(targetKey.startTime()+1);
						else
							position = transformAtTime.transformPoint(targetKey.center);
						
						_drawCursorPath(targetKey.translate.motionPath.path, position,_pathT, proportionCovered, type);
					}
					else
					{
						transformAtTime = _object.getFullPathMatrix(time);
						position = transformAtTime.transformPoint(targetKey.center);
						
						if(type == KTransformMgr.ROTATION_REF)
							_drawCursorPath(targetKey.rotate.motionPath.path, position,_pathR, proportionCovered, type);
						else if(type == KTransformMgr.SCALE_REF)
							_drawCursorPath(targetKey.scale.motionPath.path, position,_pathS, proportionCovered, type);
					}
				}
				
				if(showAll&& (type == KTransformMgr.TRANSLATION_REF))
					targetKey = targetKey.next as ISpatialKeyframe;
				else
					targetKey = null;
			}
		}
		
		protected function _drawCursorPath(points:Vector.<KPathPoint>, origin:Point, path:Sprite, proportionCovered:Number, type:int):void
		{
			var length:int = points.length;
			var drawLayer:Graphics = path.graphics;
			var arrowHeadColor:uint;
			var arrowPosition:Point;
			
			if(length <= 1 || (length == 2 && Math.abs(points[0].time-points[1].time) <= 0))
				return;
			
			var currentPoint:KPathPoint;
			
			drawLayer.moveTo(points[0].x+origin.x, points[0].y+origin.y);
		
			var duration:Number = Math.abs(points[0].time-points[points.length-1].time);
			
			if(length == 2)
			{
				var startPoint:KPathPoint = points[0];
				var endPoint:KPathPoint = points[1];
				if(proportionCovered > 1)
					proportionCovered = 1;
				else if(proportionCovered < 0)
					proportionCovered = 0;
				
				var dx:Number = (endPoint.x - startPoint.x)*proportionCovered + startPoint.x;
				var dy:Number = (endPoint.y - startPoint.y)*proportionCovered + startPoint.y;
				
				drawLayer.lineStyle(_THICKNESS_THIN, lightColors[type]);
				drawLayer.lineTo(dx+origin.x,dy+origin.y);
				
				if(proportionCovered < 1)
				{
					drawLayer.lineStyle(_THICKNESS_THIN, colors[type]);
					drawLayer.lineTo(endPoint.x+origin.x, endPoint.y+origin.y);
					arrowHeadColor = colors[type];
					arrowPosition = endPoint.add(origin);
				}
				else
				{
					arrowHeadColor = lightColors[type];
					arrowPosition = new Point(dx+origin.x, dy+origin.y);
				}
			}
			else
			{
				var proportionIndex:Number = proportionCovered * points.length-1;
				var i:int = 1;
				for(i; i<length; i++)
				{
					currentPoint = points[i];
					currentPoint.x += origin.x;
					currentPoint.y += origin.y;
					
					if(i < proportionIndex)
					{
						drawLayer.lineStyle(_THICKNESS_THIN, lightColors[type]);
						arrowHeadColor = lightColors[type];
					}
					else
					{
						drawLayer.lineStyle(_THICKNESS_THIN, colors[type]);
						arrowHeadColor = colors[type];
					}
					
					drawLayer.lineTo(currentPoint.x, currentPoint.y);
				}
				
				arrowPosition = currentPoint.clone();
			}
			
			_drawArrowHead(drawLayer, arrowHeadColor, points, arrowPosition);
		}
		
		protected function _getKeyToDraw(type:int, time:Number, showAll:Boolean):ISpatialKeyframe
		{
			if(showAll&& (type == KTransformMgr.TRANSLATION_REF))
				return _object.getSpatialKeyAtOfAfter(_object.createdTime, type);
			else
				return _object.getSpatialKeyAtOfAfter(time, type);
		}
		
		protected function _drawArrowHead(grph:Graphics, color:uint, points:Vector.<KPathPoint>, drawPoint:Point):void
		{
			var length:int = points.length;
			var directionStart:int;
			
			if(length > 5)
				directionStart = 5;
			else if(length ==2)
				directionStart = 2;
			else
				return;
			
			var direction:Point = points[length-1].subtract(points[length-directionStart]);
			var triangleVertices:Vector.<Number> = _getTriangleVertices(direction, drawPoint);
			
			grph.beginFill(color);
			grph.drawTriangles(triangleVertices);
			grph.endFill();
		}
		
		//Construct a triangular arrow head.
		protected function _getTriangleVertices(vector:Point,start:Point):Vector.<Number>
		{
			//Find the vector's unit vector
			var magnitude:Number = Math.sqrt(vector.x*vector.x + vector.y*vector.y);
			var unitVector:Point = new Point(vector.x/magnitude*7,vector.y/magnitude*7);
			
			//Find the ortogonal vector for the arrow's direction.
			//This vector will form the direction of the triangular arrow head's base.
			//Eg: If given vector is <a,b> then the orthogonal vector will be <-b, a>.
			var orthogonal:Point = new Point(-unitVector.y,unitVector.x); 
			
			//Organise the points into three vertices that form the triangular arrow head.
			var vertex1:Point = new Point(unitVector.x+start.x, unitVector.y+start.y);
			var vertex2:Point = new Point(-orthogonal.x+start.x, -orthogonal.y+start.y);
			var vertex3:Point = new Point(orthogonal.x+start.x, orthogonal.y+start.y);
			return Vector.<Number>([vertex1.x, vertex1.y, 
				vertex2.x, vertex2.y, vertex3.x, vertex3.y]);
		}
	}
}