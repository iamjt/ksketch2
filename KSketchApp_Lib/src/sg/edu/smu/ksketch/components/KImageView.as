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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filters.GlowFilter;
	
	import sg.edu.smu.ksketch.model.KImage;
	import sg.edu.smu.ksketch.utilities.KAppState;
	
	public class KImageView extends KObjectView
	{
		protected var _image:Bitmap;
		protected var _glowFilter:GlowFilter;
		
		public function KImageView(appState:KAppState, object:KImage)
		{
			super(appState, object);			
			_image = new Bitmap(object.imageData);
			addChild(_image);
			_image.x = object.imagePosition.x;
			_image.y = object.imagePosition.y;
			_glowFilter = new GlowFilter(0xff0000);
		}
		
		public function set imageData(imageData:BitmapData):void
		{
			_image.bitmapData = imageData;
		}
		
		public override function set selected(selected:Boolean):void
		{
			if(selected)
				filters = [_glowFilter];
			else
				filters = [];
		}
	}
}