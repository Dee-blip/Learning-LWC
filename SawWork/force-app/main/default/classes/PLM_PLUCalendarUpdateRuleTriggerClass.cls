public class PLM_PLUCalendarUpdateRuleTriggerClass {
	
	public static Date findEarliestMilestoneDate(PLU__c plu){
		
		
		Date minDate = plu.System_Integration_Review_Date__c;
		
		if(plu.Backend_Integration_Test__c < minDate)
			minDate = plu.Backend_Integration_Test__c;
			
		if(plu.Product_Launch_Update__c < minDate)
			minDate = plu.Product_Launch_Update__c;
			
		if(plu.Momentum_Activation__c < minDate)
			minDate = plu.Momentum_Activation__c;
			
		if(plu.Launch_Readiness__c < minDate)
			minDate = plu.Launch_Readiness__c;
			
		if(plu.Package_Design_Submission_Date__c < minDate)
			minDate = plu.Package_Design_Submission_Date__c;
			
		
		
		return minDate;
		
	}

}