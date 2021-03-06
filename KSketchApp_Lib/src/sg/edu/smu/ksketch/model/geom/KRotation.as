/***************************************************
*Copyright 2010-2012 Singapore Management University
*Developed under a grant from the Singapore-MIT GAMBIT Game Lab

*This Source Code Form is subject to the terms of the
*Mozilla Public License, v. 2.0. If a copy of the MPL was
*not distributed with this file, You can obtain one at
*http://mozilla.org/MPL/2.0/.
****************************************************/

package sg.edu.smu.ksketch.model.geom
{
	import flash.geom.Point;
	
	import sg.edu.smu.ksketch.model.implementations.KSpatialKeyFrame;
	import sg.edu.smu.ksketch.operation.KTransformMgr;
	import sg.edu.smu.ksketch.utilities.KAppState;
	import sg.edu.smu.ksketch.utilities.KMathUtil;

	public class KRotation
	{
		private var _motionPath:KPath;
		private var _transitionPath:K2DPath;
		private var _hasTransform:Boolean;
		
		private var _currentAngle:Number;
		private var _currentRotationPoints:K3DPath;
		private var _oldTransformClone:KRotation;
		
		public function KRotation()
		{
			_motionPath = new KPath();
			_transitionPath = new K2DPath();
			_currentAngle = 0;
			_hasTransform = false;
		}
		
		public function get motionPath():KPath
		{
			return _motionPath;
		}
		
		public function set motionPath(value:KPath):void
		{
			_motionPath = value;
		}
		
		public function get transitionPath():K2DPath
		{
			return _transitionPath;
		}
		
		public function set transitionPath(value:K2DPath):void
		{
			_transitionPath = value;
			
			if(_transitionPath.length > 0)
				_hasTransform = true;
			else
				_hasTransform = false;
		}
		
		public function get oldTransform():KRotation
		{
			return _oldTransformClone;
		}
		
		/**
		 * Prepares this KRotation for a transformation operation
		 */
		public function setUpCurrentTransform():void
		{
			_currentAngle = 0;
			_currentRotationPoints = new K3DPath();
			_oldTransformClone = clone();
		}
		
		/**
		 * Update and record the details of the current rotation operation
		 */
		public function updateTransform(x:Number, y:Number, angle:Number, time:Number):void
		{
			_hasTransform = true;
			_currentRotationPoints.push(x,y,time);
			_currentAngle = angle;
		}
		
		/**
		 * Processes the points recorded during the rotation operation into usable
		 * transformation values.
		 */
		public function endCurrentTransform(transitionType:int, center:Point):void
		{
			if(_transitionPath.length == 0)
			{
				if(transitionType == KAppState.TRANSITION_INTERPOLATED)
				{
					if(_currentRotationPoints.length == 0)
						return;
					
					//Generate a rotation circle from the final angle
					var duration:Number = _currentRotationPoints.points[_currentRotationPoints.length-1].z;
					
					if(duration == 0)
					{
						//If the rotation is an instant transformation
						//Ignore motion paths and just set the angle.
						_transitionPath.push(0,0);
						_transitionPath.push(_currentAngle, 0);
					}
					else
					{
						var numSteps:int = duration/KAppState.ANIMATION_INTERVAL;
						var angleStep:Number = _currentAngle/numSteps;
						var timeStep:Number = (duration)/numSteps;
						
						var startVector:K3DVector = _currentRotationPoints.points[0];
						var startPoint:Point = new Point(startVector.x, startVector.y);
						var startAngle:Number = KMathUtil.cartesianToPolar(startPoint).y;
						
						var angleMoved:Number = 0;
						var timeMoved:Number = 0;
						var theta:Number;
						
						while(Math.abs(angleMoved) <  Math.abs(_currentAngle))
						{
							theta = angleMoved + startAngle;
							_transitionPath.push(angleMoved, timeMoved);
							angleMoved += angleStep;
							timeMoved += timeStep;
						}

						if(_transitionPath.length==0)
						{
							_transitionPath.push(0,0);
							_transitionPath.push(_currentAngle, 0);
						}
						else
						{
							_transitionPath.push(_currentAngle, timeMoved);
						}
					}
				}
				else
				{
					//Compute the angle values for the transition paths
					var i:int= 0;
					var length:int = _currentRotationPoints.length;
					
					var angle:Number;
					var direction:int;
					var currentVector:K3DVector;
					var currentPoint:Point;
					var previousPoint:Point;
					var rotateAngle:Number = 0;

					for(i; i<length; i++)
					{
						currentVector = _currentRotationPoints.points[i];
						currentPoint = new Point(currentVector.x, currentVector.y);
						
						if(!previousPoint)
							previousPoint = currentPoint.clone();
							
						angle = Math.min(KMathUtil.angleOf(previousPoint,currentPoint),KMathUtil.angleOf(currentPoint,previousPoint));
						direction = KMathUtil.segcross(previousPoint, currentPoint, previousPoint);
						
						if(direction <0)
							angle *= -1;
						
						rotateAngle += angle;
						previousPoint = currentPoint.clone();
						_transitionPath.push(rotateAngle, currentVector.z);			
					}
				}
			}
			else
			{
				//Transformation exists, so have to deal with the existing transformation via refactoring
				//or interpolation of existing paths
				KPathProcessor.interpolateRotationTransitionPath(_transitionPath.points, _currentAngle);
			}
			
			if(_transitionPath)
				cleanUpPath();
			
			_currentAngle = 0;
			_currentRotationPoints = new K3DPath();
		}
		
		/**
		 * Returns the current rotation angle of this transform based on time.
		 */
		public function getTransform(proportion:Number):Number
		{
			if(_transitionPath.length == 0)
				return _currentAngle;
			var pathPoint:K2DVector = _transitionPath.getPoint(proportion);
			var result:Number = pathPoint.x + _currentAngle;
			return result
		}
		
		/**
		 * Splits this transform into two parts and returns the front portion
		 */
		public function splitTransform(proportion:Number, shift:Boolean = false):KRotation
		{
			var frontTransform:KRotation = new KRotation();
			var frontTransitionPath:K2DPath = _transitionPath.split(proportion, shift);
			
			frontTransform.transitionPath = frontTransitionPath;
			
			cleanUpPath();
			frontTransform.cleanUpPath();
			
			return frontTransform;
		}
		
		public function mergeTransform(transform:KRotation):KRotation
		{
			_oldTransformClone = this.clone();
			var rotate:KRotation = new KRotation();
			rotate.transitionPath = KPathProcessor.mergeRotationTransitionPath(
				_transitionPath, transform.transitionPath);
			rotate.cleanUpPath();
			return rotate;		
		}
		
		/**
		 * Returns an exact copy of this KRotation
		 */
		public function clone():KRotation
		{
			var clone:KRotation = new KRotation();
			clone.transitionPath = _transitionPath.clone();
			clone.cleanUpPath();
			return clone;
		}
		
		public function resampleMotion():void
		{
			KPathProcessor.resample2DPath(_transitionPath);
			KPathProcessor.generateRotationMotionPath(_transitionPath);	
		}
		
		public function addInterpolatedTransform(dThetha:Number):void
		{
			KPathProcessor.interpolateRotationTransitionPath(_transitionPath.points,dThetha);
			cleanUpPath();
		}
		
		public function setLine(time:Number):void
		{
			_transitionPath.push(0,0);
			_transitionPath.push(0,time);
		}
		
		/**
		 * Removes excess points (points near each other, points too close in time)
		 */
		public function cleanUpPath():void
		{
			KPathProcessor.cleanUp2DPath(_transitionPath);
			_motionPath = KPathProcessor.generateRotationMotionPath(_transitionPath);
			_transitionPath.generateMagnitudeTable();
		}
	}
}