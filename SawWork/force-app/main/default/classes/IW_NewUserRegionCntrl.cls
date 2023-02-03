public class IW_NewUserRegionCntrl {
//method called from create new user region componet

    /*@AuraEnabled
    public static boolean accesscheck(){
        User usr = [SELECT Id, Title, Profile.Name FROM USER WHERE Id =: UserInfo.getUserId()];
        PSA_Common_Setting__mdt pcSetting = [SELECT Id, Name__c, Value_Long__c FROM PSA_Common_Setting__mdt WHERE type__c = 'IW GSS User Region Access'];
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
    }*/
    
    @AuraEnabled
    public static String createNewUserRegion(String params){

        Id iwRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('Investment Workbox').getRecordTypeId();
        Id ramdRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('RAMD').getRecordTypeId();
        Id dealDeskRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('DealDesk').getRecordTypeId();
        Id chimeRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('Chime').getRecordTypeId();
        
        String message = '';
        IW_NewRegionWrapper results = (IW_NewRegionWrapper) JSON.deserialize(params, IW_NewRegionWrapper.class);
        System.debug('results :: '+ results);
        Id usrId = results.user;
        String type = '';
        
        List<Inv_WorkBox_Region_Mapping__c> urMapList = new List<Inv_WorkBox_Region_Mapping__c>();
        
        for(IW_Region reg : results.regions){
            
            System.debug('regions :: ' + reg.type + ' usrId ::' +  usrId);
            type = reg.type;
            // create a new UR Map Record
            Inv_WorkBox_Region_Mapping__c urMap = new Inv_WorkBox_Region_Mapping__c();
            urMap.User__c = results.user;
            //adding a Record type id to all the UserRegion Mapping records
            String rtype = results.recordType;
            //19.7 Adding Recordtype for Mulesoft RAMD 2.0 
            //20.3.1 Adding Recordtype for DealDesk Application
            //urMap.RecordTypeId = rtype.contains('Investment Work') ? iwRecordTypeId : ramdRecordTypeId;
            if(rtype.contains('Investment Work')){
                urMap.RecordTypeId = iwRecordTypeId;
            }
            else if(rtype.contains('RAMD')){
                urMap.RecordTypeId = ramdRecordTypeId;
            }
            else if(rtype.contains('DealDesk')){
               urMap.RecordTypeId = dealDeskRecordTypeId;
            }
            else{
                urMap.RecordTypeId = chimeRecordTypeId;
            }
            /*
            switch on type{
                when 'Division' {urMap.Division__c = reg.id;}   
                when 'Geography' {urMap.Geography__c = reg.id;}
                when 'Region' {urMap.Region__c = reg.id;}
                when 'Area' {urMap.Area__c = reg.id;}
                when 'Territory' {urMap.Territory__c = reg.id;}
                when else {
                    System.debug('in Switch Else :: IW_NewUserRegionCntrl');
                }
            }
            */
            switch on type{
                when 'Geography' {urMap.TERR_HIER_1__c = reg.id;}
                when 'Region' {urMap.TERR_HIER_2__c = reg.id;}
                when 'Area' {urMap.TERR_HIER_3__c = reg.id;}
                when 'Zone' {urMap.TERR_HIER_4__c = reg.id;}
                when 'Territory' {urMap.TERR_HIER_5__c = reg.id;}
                when else {
                    System.debug('in Switch Else :: IW_NewUserRegionCntrl');
                }
            }

            urMapList.add(urMap);  
            
        }
        try{
             insert urMapList;
               message = 'Success';
        }
        catch(Exception e) {
            System.debug('Exception :: e : ' +e.getDmlMessage(0));
            message = e.getDmlMessage(0);
        }
        
        return message;
    }
    
    class IW_NewRegionWrapper {
        Id user;
        String recordType;
        List<IW_Region> regions;
    }
    
    class IW_Region {
        String type;
        Id id;
    }
}