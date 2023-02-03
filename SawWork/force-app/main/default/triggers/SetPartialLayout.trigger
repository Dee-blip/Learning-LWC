Trigger SetPartialLayout on PageLayoutChangeRequest__c (after insert,after update) {
    Map<Id, List<PageLayoutChangeRequest__c>> manifestLayoutRequestMap = new Map<Id, List<PageLayoutChangeRequest__c>>();
    List<PageLayoutChangeRequest__c> plcrs = new List<PageLayoutChangeRequest__c>();
    
    for(PageLayoutChangeRequest__c plcr : Trigger.new) {
		if(trigger.isInsert) {
        	if(plcr.Invalid__c == false)
            	plcrs.add(plcr);
	    }
    	if(trigger.isUpdate) {
        	if(Trigger.oldMap.get(plcr.id).Invalid__c != plcr.Invalid__c) {
            	
                  plcrs.add(plcr);
	        }
    	}
    }
    
    for(PageLayoutChangeRequest__c plcr : plcrs) {
        if(manifestLayoutRequestMap.keySet().contains(plcr.ManifestCustom__c)) {
            manifestLayoutRequestMap.get(plcr.ManifestCustom__c).add(plcr);
        } 
           else {
                List<PageLayoutChangeRequest__c> pl= new List <PageLayoutChangeRequest__c>();
                pl.add(plcr);
                manifestLayoutRequestMap.put(plcr.ManifestCustom__c,pl);
               } 
       }
        
    List<Manifest_Custom__c> manifests = [Select id,Only_Partial_Layout__c,(Select Invalid__c  from PageLayoutChangeRequests__r) 
                                              from Manifest_Custom__c where id IN :manifestLayoutRequestMap.keySet()];
           
    for(Manifest_Custom__c manifest : manifests) {
        Boolean onlyPartial = false;
        for(PageLayoutChangeRequest__c plcr : manifestLayoutRequestMap.get(manifest.id)) {
            if(plcr.Invalid__c == false) {
                onlyPartial = true;
            }
        }
        manifest.Only_Partial_Layout__c = onlyPartial;
    }
	
    if(!manifests.isEmpty())
		Database.update(manifests);
}