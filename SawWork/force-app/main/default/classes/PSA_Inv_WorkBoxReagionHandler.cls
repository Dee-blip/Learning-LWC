public class PSA_Inv_WorkBoxReagionHandler {

    //adding a RecordType check for future usage in RAMD 2.0 
    public Id iwRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('Investment Workbox').getRecordTypeId();
    public Id ramdRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('RAMD').getRecordTypeId();
    public Id dealDeskRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('DealDesk').getRecordTypeId();
    public Id chimeRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('Chime').getRecordTypeId();

    
    public void setGDRATvalues(List<Inv_WorkBox_Region_Mapping__c> idToWBRegion){
        
        /*User usr = [SELECT Id, Title, Profile.Name FROM USER WHERE Id =: UserInfo.getUserId()];
PSA_Common_Setting__mdt pcSetting = [SELECT Id, Name__c, Value_Long__c FROM PSA_Common_Setting__mdt WHERE type__c = 'IW GSS User Region Access'];
List<String> titles = pcSetting.Value_Long__c.split(',');
System.debug('titles :::: ' + titles);
boolean access = false;
for(String str : titles){
if(usr.Title != NULL && (usr.Title.equalsIgnoreCase(str) || usr.Profile.Name == 'System Administrator')){
access = true;
}
}
System.debug('access :::' + access );*/
        boolean access = accessCheck();
        boolean ramdAccess = ramdAccessCheck();
        boolean dealDeskAccess = dealDeskAccessCheck();
        
        List< pse__Region__c > allRegionFromTerritory = [SELECT Id, Name, psa_old__c,
                                                         pse__Parent_Region__c, pse__Parent_Region__r.Name,
                                                         pse__Parent_Region__r.pse__Parent_Region__c, pse__Parent_Region__r.pse__Parent_Region__r.Name,
                                                         pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c, pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name,
                                                         pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c, pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name,
                                                         pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c, pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name
                                                         FROM pse__region__c 
                                                         WHERE psa_old__c = false 
                                                         AND Name LIKE '% (Territory)'
                                                         AND (NOT Name Like '% _Old')
                                                         AND (NOT Name Like '% _Old (%')];
                                                         //AND (NOT Name Like '% _Old%')];
        Id filter; 
        
        for( Inv_WorkBox_Region_Mapping__c reg : idToWBRegion ) {
            if((access && reg.RecordTypeId == iwRecordTypeId) 
               || ( ramdAccess && reg.RecordTypeId == ramdRecordTypeId) 
               || (dealDeskAccess && reg.RecordTypeId == dealDeskRecordTypeId)
              || (reg.RecordTypeId == chimeRecordTypeId)){
                /*
                if( reg.Territory__c != NULL ) {
                    filter = reg.Territory__c;
                }else if ( reg.Area__c != NULL ) {
                    filter = reg.Area__c;
                }else if ( reg.Region__c != NULL ) {
                    filter = reg.Region__c;
                }else if ( reg.Geography__c != NULL ) {
                    filter = reg.Geography__c;
                }else if ( reg.Division__c != NULL ) {
                    filter = reg.Division__c;
                }
                */
                
                System.debug('TERR_HIER_1__c: '+reg.TERR_HIER_1__c);
                System.debug('TERR_HIER_2__c: '+reg.TERR_HIER_2__c);
                System.debug('TERR_HIER_3__c: '+reg.TERR_HIER_3__c);
                System.debug('TERR_HIER_4__c: '+reg.TERR_HIER_4__c);
                System.debug('TERR_HIER_5__c: '+reg.TERR_HIER_5__c);
                
                if( reg.TERR_HIER_5__c != NULL ) {
                    filter = reg.TERR_HIER_5__c;
                }else if ( reg.TERR_HIER_4__c != NULL ) {
                    filter = reg.TERR_HIER_4__c;
                }else if ( reg.TERR_HIER_3__c != NULL ) {
                    filter = reg.TERR_HIER_3__c;
                }else if ( reg.TERR_HIER_2__c != NULL ) {
                    filter = reg.TERR_HIER_2__c;
                }else if ( reg.TERR_HIER_1__c != NULL ) {
                    filter = reg.TERR_HIER_1__c;
                }
                System.debug('filter: '+filter);
                for( pse__Region__c allReg : allRegionFromTerritory ) {
                    System.debug('allReg.Id: '+allReg.Id);
                    //System.Assert(1==2,'Ends here');
                    /*
                    if( filter == allReg.Id ) {
                        reg.Area__c = allReg.pse__Parent_Region__c;
                        reg.Region__c = allReg.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.Geography__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.Division__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;                    
                    }
                    else if ( filter == allReg.pse__Parent_Region__c ) {
                        reg.Region__c = allReg.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.Geography__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.Division__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                    }
                    else if ( filter == allReg.pse__Parent_Region__r.pse__Parent_Region__c ) {
                        reg.Geography__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.Division__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                    }
                    else if ( filter == allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c ) {
                        reg.Division__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                    }
                    */
                    if( filter == allReg.Id ) {
                        reg.TERR_HIER_4__c = allReg.pse__Parent_Region__c;
                        reg.TERR_HIER_3__c = allReg.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.TERR_HIER_2__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.TERR_HIER_1__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;                    
                    }
                    else if ( filter == allReg.pse__Parent_Region__c ) {
                        reg.TERR_HIER_3__c = allReg.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.TERR_HIER_2__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.TERR_HIER_1__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                    }
                    else if ( filter == allReg.pse__Parent_Region__r.pse__Parent_Region__c ) {
                        reg.TERR_HIER_2__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                        reg.TERR_HIER_1__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                    }
                    else if ( filter == allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c ) {
                        reg.TERR_HIER_1__c = allReg.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c;
                    }
                    
                }//inner for
                
            } 
            else {
                if(reg.RecordTypeId == iwRecordTypeId){
                    reg.addError('Only SLDs/Sr.SLDs can take action on GSS User Regions');
                }
                else if(reg.RecordTypeId == ramdRecordTypeId){
                    reg.addError('Only RAMD Admins can take action on GSS User Regions');
                }
                else if(reg.RecordTypeId == dealDeskRecordTypeId){
                    reg.addError('Only DealDesk Admins can take action on GSS User Regions');
                }
                
            }
            
        }//outer for
        
    }
    
    public void setGDRATvaluesOnUpdate(Map<Id, Inv_WorkBox_Region_Mapping__c> newMap,Map<Id, Inv_WorkBox_Region_Mapping__c> oldMap ){
        
        boolean access = accessCheck();
        boolean ramdAccess = ramdAccessCheck();
        boolean dealDeskAccess = dealDeskAccessCheck();
        List<Inv_WorkBox_Region_Mapping__c> modifiedDGRAT = new List<Inv_WorkBox_Region_Mapping__c>();
        for(Id urId : newMap.keySet()){
            if((access && newMap.get(urId).RecordTypeId == iwRecordTypeId) 
                || (ramdAccess && newMap.get(urId).RecordTypeId == ramdRecordTypeId) 
                || (dealDeskAccess && newMap.get(urId).RecordTypeId == dealDeskRecordTypeId)
                || (newMap.get(urId).RecordTypeId == chimeRecordTypeId) ){
                /*
                if(newMap.get(urId).Division__c != NULL && newMap.get(urId).Division__c != oldMap.get(urId).Division__c){
                    newMap.get(urId).Geography__c = NULL;
                    newMap.get(urId).Region__c = NULL;
                    newMap.get(urId).Area__c = NULL;
                    newMap.get(urId).Territory__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }
                else if(newMap.get(urId).Geography__c != NULL && newMap.get(urId).Geography__c != oldMap.get(urId).Geography__c){
                    newMap.get(urId).Division__c = NULL;
                    newMap.get(urId).Region__c = NULL;
                    newMap.get(urId).Area__c = NULL;
                    newMap.get(urId).Territory__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }
                else if(newMap.get(urId).Region__c != NULL && newMap.get(urId).Region__c != oldMap.get(urId).Region__c){
                    newMap.get(urId).Division__c = NULL;
                    newMap.get(urId).Geography__c = NULL;
                    newMap.get(urId).Area__c = NULL;
                    newMap.get(urId).Territory__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }
                else if(newMap.get(urId).Area__c != NULL && newMap.get(urId).Area__c != oldMap.get(urId).Area__c){
                    newMap.get(urId).Division__c = NULL;
                    newMap.get(urId).Geography__c = NULL;
                    newMap.get(urId).Region__c = NULL;
                    newMap.get(urId).Territory__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }
                else if(newMap.get(urId).Territory__c != NULL && newMap.get(urId).Territory__c != oldMap.get(urId).Territory__c){
                    newMap.get(urId).Division__c = NULL;
                    newMap.get(urId).Geography__c = NULL;
                    newMap.get(urId).Region__c = NULL;
                    newMap.get(urId).Area__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }
                */
                if(newMap.get(urId).TERR_HIER_1__c != NULL && newMap.get(urId).TERR_HIER_1__c != oldMap.get(urId).TERR_HIER_1__c){
                    newMap.get(urId).TERR_HIER_2__c = NULL;
                    newMap.get(urId).TERR_HIER_3__c = NULL;
                    newMap.get(urId).TERR_HIER_4__c = NULL;
                    newMap.get(urId).TERR_HIER_5__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }
                else if(newMap.get(urId).TERR_HIER_2__c != NULL && newMap.get(urId).TERR_HIER_2__c != oldMap.get(urId).TERR_HIER_2__c){
                    newMap.get(urId).TERR_HIER_1__c = NULL;
                    newMap.get(urId).TERR_HIER_3__c = NULL;
                    newMap.get(urId).TERR_HIER_4__c = NULL;
                    newMap.get(urId).TERR_HIER_5__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }
                else if(newMap.get(urId).TERR_HIER_3__c != NULL && newMap.get(urId).TERR_HIER_3__c != oldMap.get(urId).TERR_HIER_3__c){
                    newMap.get(urId).TERR_HIER_1__c = NULL;
                    newMap.get(urId).TERR_HIER_2__c = NULL;
                    newMap.get(urId).TERR_HIER_4__c = NULL;
                    newMap.get(urId).TERR_HIER_5__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }
                else if(newMap.get(urId).TERR_HIER_4__c != NULL && newMap.get(urId).TERR_HIER_4__c != oldMap.get(urId).TERR_HIER_4__c){
                    newMap.get(urId).TERR_HIER_1__c = NULL;
                    newMap.get(urId).TERR_HIER_2__c = NULL;
                    newMap.get(urId).TERR_HIER_3__c = NULL;
                    newMap.get(urId).TERR_HIER_5__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }
                else if(newMap.get(urId).TERR_HIER_5__c != NULL && newMap.get(urId).TERR_HIER_5__c != oldMap.get(urId).TERR_HIER_5__c){
                    newMap.get(urId).TERR_HIER_1__c = NULL;
                    newMap.get(urId).TERR_HIER_2__c = NULL;
                    newMap.get(urId).TERR_HIER_3__c = NULL;
                    newMap.get(urId).TERR_HIER_4__c = NULL;
                    modifiedDGRAT.add(newMap.get(urId));
                }


            }
            else {
                if(newMap.get(urId).RecordTypeId == iwRecordTypeId){
                    newMap.get(urId).addError('Only SLDs/Sr.SLDs can take action on GSS User Regions');   
                }
                else if(newMap.get(urId).RecordTypeId == ramdRecordTypeId){
                    newMap.get(urId).addError('Only RAMD Admins can take action on GSS User Regions');   
                }
                else if(newMap.get(urId).RecordTypeId == dealDeskRecordTypeId){
                    newMap.get(urId).addError('Only DealDesk Admins can take action on GSS User Regions');
                }
            }

        }
        if(modifiedDGRAT != NULL && modifiedDGRAT.size() > 0){
            setGDRATvalues(modifiedDGRAT);
        }
        
    }
    
    public static boolean accessCheck(){
        User usr = [SELECT Id, Title, Profile.Name FROM USER WHERE Id =: UserInfo.getUserId()];
        PSA_Common_Setting__mdt pcSetting = [SELECT Id, Name__c, Value_Long__c FROM PSA_Common_Setting__mdt WHERE type__c = 'IW GSS User Region Access'];
        RAMD_Setting__mdt ramdSetting = [SELECT Value__c FROM RAMD_Setting__mdt WHERE DeveloperName = 'RAMD_GSS_Region_Approvers'];
        List<String> titles = pcSetting.Value_Long__c.split(',');
        System.debug('titles :::: ' + titles);
        boolean access = false;
        for(String str : titles){
            if(usr.Title != NULL && (usr.Title.equalsIgnoreCase(str) || usr.Profile.Name == 'System Administrator')){
                access = true;
            }
        }
        
        System.debug('access :::' + access );
        return access;
    }
    
    public static boolean ramdAccessCheck(){
        User usr = [SELECT Id, Title, Profile.Name FROM USER WHERE Id =: UserInfo.getUserId()];
        RAMD_Setting__mdt ramdSetting = [SELECT Value__c FROM RAMD_Setting__mdt WHERE DeveloperName = 'RAMD_GSS_Region_Approvers'];
        List<String> approverUserIds = ramdSetting.Value__c.split(',');
        String appovers = ramdSetting.Value__c;
        System.debug('RAMD approverUserIds :::: ' + approverUserIds);
        boolean access = false;
        System.debug('User Id :: '+ usr.Id);
        if(appovers.contains(usr.Id) || usr.Profile.Name == 'System Administrator'){
             access = true;
        }
        System.debug('access :::' + access );
        return access;
    }
    
    public static boolean dealDeskAccessCheck(){
        User usr = [SELECT Id, Title, Profile.Name, Alias FROM USER WHERE Id =: UserInfo.getUserId()];
        SC_Utility__mdt dealDeskSetting = [SELECT Value__c FROM SC_Utility__mdt WHERE DeveloperName = 'DealDesk_DGRAT_Create_Edit_Access'];
        String approvers = dealDeskSetting.Value__c;
        System.debug('Deal Desk User Alias :::: ' + approvers);
        boolean access = false;
        if(approvers.contains(usr.Alias) || usr.Profile.Name == 'System Administrator'){
             access = true;
        }
        System.debug('access :::' + access );
        return access;
    }
    
    public void beforeDeleteRecs(List<Inv_WorkBox_Region_Mapping__c> delRecs){
        
        boolean access = accessCheck();
        boolean ramdAccess = ramdAccessCheck();
        boolean dealDeskAccess = dealDeskAccessCheck();
        for(Inv_WorkBox_Region_Mapping__c reg : delRecs){
            if(!access && reg.RecordTypeId == iwRecordTypeId){
                System.debug('no Access from IW check');
                reg.addError('Only SLDs/Sr.SLDs can take action on GSS User Regions');
            }
            else if(!ramdAccess && reg.RecordTypeId == ramdRecordTypeId){
                System.debug('no Access from RAMD check');
                reg.addError('Only RAMD Admins can take action on GSS User Regions');
            }
            else if(!dealDeskAccess && reg.RecordTypeId == dealDeskRecordTypeId){
                System.debug('no Access from DealDesk check');
                reg.addError('Only DealDesk Admins can take action on GSS User Regions');
            }
        }
        
    }
    
}