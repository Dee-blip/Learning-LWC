trigger BillboardAlertRuleTrigger_ai_au on Billboard_Alert_Rule__c (after insert, after update) 
{
    List<Billboard_Alert_Rule_Custom_Settings__c> bbAlertCSList = new List<Billboard_Alert_Rule_Custom_Settings__c>();
    List<Billboard_Alert_Rule_Custom_Settings__c> inactiveBBAlertCSList = new List<Billboard_Alert_Rule_Custom_Settings__c>();
    
    if(Trigger.isInsert)    
    {
        for(Billboard_Alert_Rule__c bb: Trigger.New)
        {
        	if(bb.isActive__c && bb.Alert_Type__c=='Billboard' && bb.Alert_Start_Date__c <= Date.Today() && bb.Alert_End_Date__c >= date.Today())
	        {
	        	Billboard_Alert_Rule_Custom_Settings__c  bbAlertCS = new Billboard_Alert_Rule_Custom_Settings__c();
	            bbAlertCS.Name = bb.Id;
	            //bbAlertCS.ExternalId__c = bb.Id;
	            bbAlertCS.Start_Date__c = bb.Alert_Start_Date__c;
	            bbAlertCS.End_Date__c = bb.Alert_End_Date__c;
	            bbAlertCSList.add(bbAlertCS);
	        }
        }
    }
     
    if(Trigger.isUpdate)
    {
    	for(Billboard_Alert_Rule__c bb: Trigger.New)
        {
        	//CR 1901368 - Billboard fix: Added outer check for Alert_Type__c='Billboard'
        	if((bb.Alert_Type__c=='Billboard' && bb.Alert_Start_Date__c <= Date.Today() && bb.Alert_End_Date__c >= date.Today())
        	&&((Trigger.oldMap.get(bb.Id).isActive__c != bb.isActive__c && bb.isActive__c == True)
        	|| Trigger.oldMap.get(bb.Id).Alert_Start_Date__c != bb.Alert_Start_Date__c
        	|| Trigger.oldMap.get(bb.Id).Alert_End_Date__c != bb.Alert_End_Date__c 
        	|| (Trigger.oldMap.get(bb.Id).Alert_Type__c != bb.Alert_Type__c)))
        	{
        		Billboard_Alert_Rule_Custom_Settings__c  bbAlertCS = new Billboard_Alert_Rule_Custom_Settings__c();
			    bbAlertCS = Billboard_Alert_Rule_Custom_Settings__c.getInstance(bb.Id);
			    
			    if(bbAlertCS == null)
			    	bbAlertCS = new Billboard_Alert_Rule_Custom_Settings__c(Name=bb.Id);
			    
		        bbAlertCS.Start_Date__c = bb.Alert_Start_Date__c;
		        bbAlertCS.End_Date__c = bb.Alert_End_Date__c;
		        bbAlertCSList.add(bbAlertCS);
        	}
        	
        	if ((Trigger.oldMap.get(bb.Id).isActive__c != bb.isActive__c && bb.isActive__c == false)
        	|| (Trigger.oldMap.get(bb.Id).Alert_Type__c != bb.Alert_Type__c && bb.Alert_Type__c != 'Billboard'))
        	{	
        		Billboard_Alert_Rule_Custom_Settings__c bbCs = Billboard_Alert_Rule_Custom_Settings__c.getInstance(bb.Id);
        		if(bbCs != null)
        			inactiveBBAlertCSList.add(bbCs);
        	}
        }
    }
    
    if(bbAlertCSList.size() > 0)
        upsert bbAlertCSList;
        
    if(inactiveBBAlertCSList.size() > 0)
    	delete inactiveBBAlertCSList;

}