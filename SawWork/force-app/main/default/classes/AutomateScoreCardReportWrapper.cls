// File added as part of SFDC-2201 by Mayank Bansal

public class AutomateScoreCardReportWrapper {

	public Map<Integer, FieldWrapper> fieldList;

	public AutomateScoreCardReportWrapper(){

	}


	public AutomateScoreCardReportWrapper addField(AutomateScoreCardReportWrapper obj, String fieldAPIName, Object fieldValue, String fieldLabel, Integer sequence){

		FieldWrapper fw = new FieldWrapper();
		fw.fieldAPI = fieldAPIName;
		fw.fieldValue = fieldValue;
		fw.fieldLabel = fieldLabel;
		fw.sequence = sequence;

		if(obj.fieldList == null){
			obj.fieldList = new Map<Integer, fieldWrapper>();
		}
		obj.fieldList.put(sequence, fw);
		return obj;
	}

	public class FieldWrapper {

	public String fieldAPI;
	public String fieldLabel;
	public Object fieldValue;
	public Integer sequence;	
	}
}