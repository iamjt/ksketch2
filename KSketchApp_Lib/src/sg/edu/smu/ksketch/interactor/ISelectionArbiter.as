package sg.edu.smu.ksketch.interactor
{
	import flash.utils.Dictionary;
	import sg.edu.smu.ksketch.utilities.KModelObjectList;

	public interface ISelectionArbiter
	{
		function bestGuess(rawData:Dictionary, time:Number):KModelObjectList;
	}
}