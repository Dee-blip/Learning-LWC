trigger PLM_PLUCalendarUpdateRuleTrigger on PLU__c (before insert, before update) {
    
	
	/** 
		When a PLU is created, this sets flag notify_milestone_dates__c which triggers a time based workflow. 
		The timebased workflow will trigger an email one week prior to the earlier milestone date.
	*/    
    if(Trigger.isInsert){
		
    	for(PLU__c item : Trigger.new){
    		item.notify_milestone_dates__c = true;
    		item.earliest_plu_milestone__c = PLM_PLUCalendarUpdateRuleTriggerClass.findEarliestMilestoneDate(item);	
    	}

    }

        
    if(Trigger.isUpdate && PLM_CastIronClass.firstRun)
    {
    	
	    Set<Id> fullPlu = new Set<Id>();
	    
		    Map<Id, Date> siRDateMap = new Map<Id, Date>();
		    Map<Id, Date> biRDateMap = new Map<Id, Date>();
		    Map<Id, Date> productLaunchDateMap = new Map<Id, Date>();
		    Map<Id, Date> packageDesignDateMap = new Map<Id, Date>();
		    Map<Id, Date> momentumActivationDateMap = new Map<Id, Date>();
		    Map<Id, Date> launchReadinessDateMap = new Map<Id, Date>();
		    
		    Map<Id, Date> oldPluSiRDateMap = new Map<Id, Date>();
		    Map<Id, Date> oldPluBiRDateMap = new Map<Id, Date>();
		    Map<Id, Date> oldPluProductLaunchDateMap = new Map<Id, Date>();
		    Map<Id, Date> oldPluPackageDesignDateMap = new Map<Id, Date>();
		    Map<Id, Date> oldPluMomentumActivationDateMap = new Map<Id, Date>();
		    Map<Id, Date> oldPluLaunchReadinessDateMap = new Map<Id, Date>();
	    
			List<Launch_Item__c> launchList = new List<Launch_Item__c>();     
	    
		    for(PLU__c item : Trigger.new){
						
						//If any milestone date changes in PLU item, get that PLU for update
		                if((Trigger.oldMap.get(item.Id).System_Integration_Review_Date__c  != item.System_Integration_Review_Date__c)||
		                (Trigger.oldMap.get(item.Id).Backend_Integration_Test__c != item.Backend_Integration_Test__c)||
		                (Trigger.oldMap.get(item.Id).Product_Launch_Update__c != item.Product_Launch_Update__c)||
		                (Trigger.oldMap.get(item.Id).Momentum_Activation__c != item.Momentum_Activation__c)||
		                (Trigger.oldMap.get(item.Id).Launch_Readiness__c != item.Launch_Readiness__c)||
		                (Trigger.oldMap.get(item.Id).Package_Design_Submission_Date__c != item.Package_Design_Submission_Date__c)){
	
		                    fullPlu.add(item.Id);
		                    
		                    oldPluSiRDateMap.put(item.Id, Trigger.oldMap.get(item.Id).System_Integration_Review_Date__c);
		                    oldPluBiRDateMap.put(item.Id, Trigger.oldMap.get(item.Id).Backend_Integration_Test__c);
		                    oldPluProductLaunchDateMap.put(item.Id, Trigger.oldMap.get(item.Id).Product_Launch_Update__c);
		                    oldPluPackageDesignDateMap.put(item.Id, Trigger.oldMap.get(item.Id).Package_Design_Submission_Date__c);
		                    oldPluMomentumActivationDateMap.put(item.Id, Trigger.oldMap.get(item.Id).Momentum_Activation__c);
		                    oldPluLaunchReadinessDateMap.put(item.Id, Trigger.oldMap.get(item.Id).Launch_Readiness__c);
	
		                    siRDateMap.put(item.Id, item.System_Integration_Review_Date__c);
		                    biRDateMap.put(item.Id, item.Backend_Integration_Test__c);
		                    productLaunchDateMap.put(item.Id, item.Product_Launch_Update__c);
		                    packageDesignDateMap.put(item.Id, item.Package_Design_Submission_Date__c);
		                    momentumActivationDateMap.put(item.Id, item.Momentum_Activation__c);
		                    launchReadinessDateMap.put(item.Id, item.Launch_Readiness__c);
		                    
							// This block updates the earliest PLM milestone whenever a PLU is modified
			    			item.earliest_plu_milestone__c = PLM_PLUCalendarUpdateRuleTriggerClass.findEarliestMilestoneDate(item);	
		                    
		                }
		    
		    }
		    
	
	    	// Update launch items milestone dates with the new values set in PLU
	        for(Launch_Item__c lic: [Select Id, PLU__c, 
	        Backend_Integration_Test_Dates__c, 
	        Momentum_Activation_Date__c, 
	        Launch_Readiness_Date__c,
	        Package_Design_Submission_Date__c,
	        Product_Launch_Update__c,
	        System_Integration_Review_Date__c
	        From Launch_Item__c where PLU__c in :fullPlu]){
	        
	        // If the date in launch item hasn't been overwritten/customised, update the launch milestone with date set in PLU
	        // This rule applies to all milestone dates
	         
			if(lic.Backend_Integration_Test_Dates__c == oldPluBiRDateMap.get(lic.PLU__c))
				lic.Backend_Integration_Test_Dates__c = biRDateMap.get(lic.PLU__c);
	
			if(lic.Momentum_Activation_Date__c == oldPluMomentumActivationDateMap.get(lic.PLU__c))	
				lic.Momentum_Activation_Date__c =  momentumActivationDateMap.get(lic.PLU__c);
			
			if(lic.Launch_Readiness_Date__c == oldPluLaunchReadinessDateMap.get(lic.PLU__c))	
				lic.Launch_Readiness_Date__c =  launchReadinessDateMap.get(lic.PLU__c);
				
			if(lic.Package_Design_Submission_Date__c == oldPluPackageDesignDateMap.get(lic.PLU__c))	
				lic.Package_Design_Submission_Date__c =  packageDesignDateMap.get(lic.PLU__c);
		
			if(lic.Product_Launch_Update__c == oldPluProductLaunchDateMap.get(lic.PLU__c))	
				lic.Product_Launch_Update__c =  productLaunchDateMap.get(lic.PLU__c);
		
			if(lic.System_Integration_Review_Date__c == oldPluSiRDateMap.get(lic.PLU__c))	
				lic.System_Integration_Review_Date__c =  siRDateMap.get(lic.PLU__c);
				 
	        launchList.add(lic);
	
	        }
	    
	     // Update launch items with the changed dates
	     update launchList;
	     
	     PLM_CastIronClass.firstRun = false;
	     
	
	    }
       
        
}