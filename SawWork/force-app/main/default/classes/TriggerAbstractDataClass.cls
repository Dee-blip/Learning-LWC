public with sharing abstract class TriggerAbstractDataClass {
	
	
	
	public TriggerAbstractDataClass() 
	{

	 	initializeDataClassMethods();
	}

	

	public void initializeDataClassMethods()
	{
		init();
	}
	//Opportunity Trigger data class variables
	public  String amgOppRecordType;
	public Map<ID,Schema.RecordTypeInfo> oppty_rt_Map;
	public List<Manage_Forecast_Date_Category_n_Override__mdt> listOfManageForecastOverrideSettings  = new List<Manage_Forecast_Date_Category_n_Override__mdt>();
	public String opptySALStage ;
	public String OpportunityTrg_RebateTCError;
	public String opptyNascentStage;
    public String opptyUnqualifiedLeadClosedStage;
    public Profile currentUserProfile;

	//Generic Data class methods
	public abstract void init();
	//public  abstract void initializeDependency();
	public abstract void getCustomMetadata();
	public  abstract void getCustomSettings();
	public  abstract void getRecordTypeInfo();
	public abstract Id getRecordTypeInfoByName(String recordTypeName);
	public abstract String getUserTypeInfo();
	public abstract String getUserNameInfo();



	
}