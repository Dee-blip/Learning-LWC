/*

Territory Mapping object has fields like - Parent_Division which has values in the format of Geo_Div, Region, Area, Territory.
Region object in FF does not have separate fields like the TM. Here the Geography, Division etc are stored as individual records.
The identification is the Name field. Geography would have values like APJ(Geography), Division would have values like APJ Media (Division) and so on.

With the new DGRAT changes now the Parent_Division field at the Territory Mapping will hold the values - Geo_Div = Media Americas_Media.
FFPSA-1841 - Modified code to accommodate GRAZT changes
*/


public class PSA_updateGDRATalignment 
{  
    public void updateGDRAT()
    {
        /*The parent region of Geography is Corporate. Corporate is the top level. */
        Id CorporateId = [Select Id from pse__Region__c where Name = 'Corporate' limit 1][0].Id;
        
        /*Parent Region field is a lookup to Region object itself. The parent of Territory is Area, Area is Division and so on. 
The below query fetches all the existing Region records that are not tagged as '_OLD.'*/
        list<pse__Region__c> existingRegions = [select id,Name,pse__Parent_Region__c,pse__Region_Name_Chain__c,
                                                pse__Parent_Region__r.name,
                                                pse__Parent_Region__r.pse__Parent_Region__r.Name,
                                                pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name,
                                                pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name,
                                                pse__Hierarchy_Depth__c from pse__Region__c where (Not Name  Like 'Corporate') and (Not Name  Like '%_OLD') and (Not Name  Like '%_OLD (%')];//(Not Name  Like '%_OLD%') ];
        
        list<Territory_Mapping__c> tm =[Select Id, TERR_HIER_1__c, TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c,TerritoryMappingAutoID__c from Territory_Mapping__c where (Not Name  Like 'OLD%') AND TERR_HIER_1__c != null];

        set<pse__Region__c> Geos2Insert = new set<pse__Region__c>();
        set<pse__Region__c> Regs2Insert = new set<pse__Region__c>();
        set<pse__Region__c> Areas2Insert = new set<pse__Region__c>();
        set<pse__Region__c> Zones2Insert = new set<pse__Region__c>();
        set<pse__Region__c> Ters2Insert = new set<pse__Region__c>();
        list<pse__Region__c> InsertGeos = new list<pse__Region__c>();
        list<pse__Region__c> InsertRegs = new list<pse__Region__c>();
        list<pse__Region__c> InsertAreas = new list<pse__Region__c>();
        list<pse__Region__c> InsertZones = new list<pse__Region__c>();
        list<pse__Region__c> InsertTers = new list<pse__Region__c>();
        list<pse__Region__c> existingGeos = new list<pse__Region__c>();
        list<pse__Region__c> existingRegs = new list<pse__Region__c>();
        list<pse__Region__c> existingAreas = new list<pse__Region__c>();
        list<pse__Region__c> existingZones = new list<pse__Region__c>();
        list<pse__Region__c> existingTers = new list<pse__Region__c>();

        list<pse__Region__c> RegionInitialUpdate = new list<pse__Region__c>(); 
        
        //New list for adding all Region updates
        list<pse__Region__c> finalRegionUpdate = new list<pse__Region__c>();
        
        /* Hierarchy depth is a field that is set to 1 for Geo, 2 for region and so on. Territory has a hierarchy depth as 5. */
        for(pse__Region__c reg: existingRegions)
        {
            if(reg.pse__Hierarchy_Depth__c == 1)
            {
                existingGeos.add(reg);
            }
            else if(reg.pse__Hierarchy_Depth__c == 2)
            {
                existingRegs.add(reg);
            }
            else if(reg.pse__Hierarchy_Depth__c == 3)
            {
                existingAreas.add(reg);
            }
            else if(reg.pse__Hierarchy_Depth__c == 4)
            {
                existingZones.add(reg);
            }
            else if(reg.pse__Hierarchy_Depth__c == 5)
            {
                existingTers.add(reg);
            }
            /* Mark the old flag as true initially for all the existing Region records. */
            reg.psa_Old__c = TRUE;
            RegionInitialUpdate.Add(reg);
            
        }
        Database.update(RegionInitialUpdate);
        Boolean GeosExists,RegsExists,AreasExists,ZonesExists,TerrsExists;
        // Check whether only 1 unique Territory Mapping record for each GDRAT record or multiple duplicates
        For(Territory_Mapping__c tm1: tm)           
        {
            //String Geography,Division, Region,Area,Territory;
            String Geographys,Regions,Areas,Zones,Territorys;
            //List<String> GeoDiv = tm1.Parent_Division__c.split('_');
   
            Geographys = tm1.TERR_HIER_1__c;
            Regions = tm1.TERR_HIER_2__c;
            Areas = tm1.TERR_HIER_3__c;
            Zones = tm1.TERR_HIER_4__c;
            Territorys = tm1.TERR_HIER_5__c;
            GeosExists = FALSE;
            ZonesExists = FALSE;
            RegsExists = FALSE;
            AreasExists = FALSE;
            TerrsExists = FALSE;
            pse__Region__c parentGeoRegion1 = new pse__Region__c();   
            //GEOGRAPHY HIERARCHY
            for(pse__region__c geos:existingGeos)
            {     
                if((geos.name) == Geographys + ' (Geography)')
                {
                    geos.Region_Unique_Id__c= Geographys + CorporateId;
                    geos.psa_Old__c = FALSE;
                    Geos2Insert.add(geos);
                    GeosExists = TRUE;                  
                    parentGeoRegion1.Region_Unique_Id__c= geos.Region_Unique_Id__c;
                }
            }
            if(GeosExists == FALSE)  
            {
                pse__Region__c parentGeoRegion = new pse__Region__c();
                parentGeoRegion.Name= Geographys + ' (Geography)';
                parentGeoRegion.Region_Unique_Id__c= Geographys + CorporateId;
                parentGeoRegion.pse__Parent_Region__c = CorporateId;
                parentGeoRegion.psa_Old__c = FALSE;               
                Geos2Insert.add(parentGeoRegion);        
                parentGeoRegion1.Region_Unique_Id__c= parentGeoRegion.Region_Unique_Id__c;
            }  
            
            // REGION HIERARCHY
            //pse__Region__c parentDivRegion1 = new pse__Region__c(); 
            pse__Region__c parentRegionArea1 = new pse__Region__c(); 
            for(pse__region__c regs:existingRegs)
            {
                if(regs.Name == Regions + ' (Region)' && regs.pse__Parent_Region__r.Name == Geographys + ' (Geography)')
                {
                    regs.Region_Unique_Id__c= Regions + parentGeoRegion1.Region_Unique_Id__c;
                    regs.psa_Old__c = FALSE;
                    REGSExists = TRUE;
                    Regs2Insert.add(regs); 
                    parentRegionArea1.Region_Unique_Id__c=  regs.Region_Unique_Id__c;                 
                }
            }
            if(RegsExists == FALSE)
            {
                pse__Region__c childRegion = new pse__Region__c();
                childRegion.Name = Regions + ' (Region)';
                childRegion.Region_Unique_Id__c= Regions + parentGeoRegion1.Region_Unique_Id__c;
                childRegion.pse__Parent_Region__r = parentGeoRegion1;
                childRegion.psa_Old__c = FALSE;
                Regs2Insert.add(childRegion);    
                parentRegionArea1.Region_Unique_Id__c= childRegion.Region_Unique_Id__c;
            }
          
            //Area Hierarchy
            //pse__Region__c parentAreaRegion1 = new pse__Region__c();   
            pse__Region__c parentAreaZone1 = new pse__Region__c(); 
            for(pse__region__c Areai: existingAreas)
            {
                if(Areai.Name == Areas + ' (Area)' && Areai.pse__Parent_Region__r.Name == Regions + ' (Region)' && Areai.pse__Parent_Region__r.pse__Parent_Region__r.Name== Geographys + ' (Geography)' )
                {
                    Areai.Region_Unique_Id__c= Areas + parentRegionArea1.Region_Unique_Id__c;
                    AreasExists = TRUE;
                    Areai.psa_Old__c = False;
                    Areas2Insert.add(Areai);
                    parentAreaZone1.Region_Unique_Id__c = Areai.Region_Unique_Id__c;                   
                }
            }
            if(AreasExists==FALSE)
            {
                pse__Region__c childArea = new pse__Region__c();
                childArea.Name= Areas + ' (Area)';
                childArea.Region_Unique_Id__c= Areas + parentRegionArea1.Region_Unique_Id__c;
                childArea.pse__Parent_Region__r = parentRegionArea1;
                childArea.psa_Old__c = FALSE;  
                Areas2Insert.add(childArea);
                parentAreaZone1.Region_Unique_Id__c= childArea.Region_Unique_Id__c;      
            }

            // Zone Hierarchy    
            pse__Region__c parentZoneTerritory1 = new pse__Region__c(); 
            for(pse__region__c zone:existingzones)
            {
                if(zone.Name == Zones + ' (Zone)' && zone.pse__Parent_Region__r.Name == Areas + ' (Area)' && zone.pse__Parent_Region__r.pse__Parent_Region__r.Name == Regions + ' (Region)' && zone.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name == Geographys + ' (Geography)')
                {
                    zone.Region_Unique_Id__c= Zones+ parentAreaZone1.Region_Unique_Id__c;
                    zone.psa_Old__c = False;
                    zones2Insert.add(zone);
                    ZonesExists = TRUE;
                    parentZoneTerritory1.Region_Unique_Id__c = zone.Region_Unique_Id__c;  
                }
            }
            if(ZonesExists == FALSE)
            {
                pse__Region__c childZone = new pse__Region__c();
                childZone.Name= Zones + ' (Zone)';
                childZone.Region_Unique_Id__c= Zones+parentAreaZone1.Region_Unique_Id__c;
                childZone.pse__Parent_Region__r = parentAreaZone1;
                childZone.psa_Old__c = FALSE;     
                Zones2Insert.add(childZone);  
                parentZoneTerritory1.Region_Unique_Id__c = childZone.Region_Unique_Id__c;   
            }            
        
            //Territory Hierarchy 
            for(pse__region__c Terri:existingTers)
            {
                if(Terri.Name == Territorys + ' (Territory)' && Terri.pse__Parent_Region__r.Name == Zones + ' (Zone)' && Terri.pse__Parent_Region__r.pse__Parent_Region__r.Name == Areas + ' (Area)' && Terri.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name == Regions + ' (Region)' && Terri.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name == Geographys + ' (Geography)')
                {
                    Terri.Region_Unique_Id__c= Territorys+parentZoneTerritory1.Region_Unique_Id__c;
                    Terri.psa_Old__c = False;
                    Ters2Insert.add(Terri);
                    TerrsExists = TRUE;
                }
            }
            if(TerrsExists == FALSE)
            {
                pse__Region__c childTerritory = new pse__Region__c();
                childTerritory.Name= Territorys + ' (Territory)';
                childTerritory.Region_Unique_Id__c= Territorys+parentZoneTerritory1.Region_Unique_Id__c;
                childTerritory.pse__Parent_Region__r = parentZoneTerritory1;
                childTerritory.psa_Old__c = FALSE;     
                Ters2Insert.add(childTerritory);   
            } 
            
        }
        //System.AssertEquals(Ter2Insert, NULL);
        InsertGeos.addAll(Geos2Insert);
        InsertRegs.addAll(Regs2Insert);
        InsertAreas.addAll(Areas2Insert);
        InsertZones.addAll(Zones2Insert);
        InsertTers.addAll(Ters2Insert);
        
        //Database.Upsert(InsertGeos,False);

        List<Database.UpsertResult> geosUpsert = Database.Upsert(InsertGeos,false);
        List<Database.UpsertResult> regionsUpsert = Database.Upsert(InsertRegs,false); 
        Database.Upsert(InsertAreas,False);
        Database.Upsert(InsertZones,False);
        Database.Upsert(InsertTers,False);
        
        //18.10 : FFPSA-558 : commented above line by Sujay to track and notify user on regions alignment 
        Set<Id> newRegionIds = new Set<Id>();
        for (Database.UpsertResult sr : regionsUpsert)
        {
            if (sr.isCreated())
            {
                newRegionIds.add(sr.getId());
            }
        }

        //19.5 Adding Geo chnages also
        Set<Id> newGeoIds = new Set<Id>();
        for (Database.UpsertResult sr : geosUpsert)
        {
            if (sr.isCreated())
            {
                newGeoIds.add(sr.getId());
            }
        }
        System.debug('Regions :: '+ newRegionIds + ' ::::  Geos' + newGeoIds);
        notifyGSSUserOnNewRegions(newRegionIds, newGeoIds);
    }
    
    @future
    public static void notifyGSSUserOnNewRegions(Set<Id> newRegIds, Set<Id> newGeoIds){
        System.debug('in Future call :: notifyGSSUserOnNewRegions ');
        //Changes by Sujay : FFPSA-558 : for notifying users on any new Region that is craeted over GDRATalignment
        //List<String> newRegions = new List<String>();
        Date tday = Date.today();
        //19.5 Adding Geography Filter to make sure all Regions added are notified to SLDs
        List<pse__Region__c> allreg = [SELECT Id , Name
                                       FROM pse__Region__c 
                                       WHERE 
                                            ( Name LIKE '% (Region)' OR Name LIKE '% (Geography)')
                                       AND (
                                           (Id IN: newRegIds OR Id IN: newGeoIds) 
                                                OR 
                                           (LastModifiedDate = Today 
                                            AND psa_old__c = TRUE) 
                                        )];
        //List<pse__Region__c> setAlignmentNotified = new List<pse__Region__c>();
        System.debug('allreg :::::::::::::::: '+ allreg);
        
        String messageBody;
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage objEmail;
        String fromAddress = [SELECT Value_Long__c FROM PSA_Common_Setting__mdt WHERE Name__c = 'FromEmailAdress'].Value_Long__c ;
        String orgWideEmailId = '';
        try
        {
            orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
        }
        catch(Exception e)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('orgWideEmailId not found',e.getMessage());
        }
        
        objEmail = new Messaging.SingleEmailMessage();
        objEmail.setSubject('DGRAT Realignment | Regions have been Adding OR Removed');
        objEmail.setReplyTo('noreply@akamai.com');
        if(orgWideEmailId != '')
        {
            objEmail.setOrgWideEmailAddressId(orgWideEmailId);  
        }
        messageBody = 'Please note that the below Regions have been Removed as part of the annual DGRAT Realignment. <br>';
        String newRegionAdded = '<br> Below are the new Regions Added after the annual DGRAT Realignment. <br>';
        integer iRegion = 1;
        Integer i = 1;
        Boolean newRegEmail = false;
        Boolean RegRemovedEmail = false;
        for(pse__Region__c reg : allreg){
            System.debug('Building messageBody to notify SLDs ::::::::::::::::::::::::::::: '+ messageBody + newRegionAdded);
            if(!newRegIds.contains(reg.Id) || !newGeoIds.contains(reg.Id)){
                //setAlignmentNotified.add(reg);
                messageBody += i + '. '+ reg.Name +'<br>';
                RegRemovedEmail = true;
                i++;
            }
            //added Geo level Ids as well
            else if(newRegIds.contains(reg.Id) || newGeoIds.contains(reg.Id)){
                newRegionAdded += iRegion + '. '+ reg.Name +'<br>';
                newRegEmail = true; 
                iRegion++;
            }
        }
        
        System.debug('Building messageBody to notify SLDs After Loop ::::::::::::::::::::::::::::: '+ messageBody + newRegionAdded);
        //messageBody += '<br> Please map the GSS Users accordingly.';
        List<String> SLDs = new List<String>();
        if(RegRemovedEmail || newRegEmail){
            List<User> userSLD = [SELECT Id,Email, Title 
                                  FROM User 
                                  WHERE Title In ('Director..Service Line','Director.Senior.Service Line') 
                                  AND isActive = true];
            for(User usr : userSLD){
                SLDs.add(usr.Email);
            }
            //objEmail.setToAddresses(SLDs);
            System.debug('SLDs ::::::::::::::::::::::::' + SLDs);
            objEmail.setToAddresses(SLDs);
            //objEmail.setToAddresses(new List<String>{'sujs@akamai.com'});
            String messageAddedBody = RegRemovedEmail ? messageBody : '';
            String newRegionAddedBody = newRegEmail ? newRegionAdded : '';
            System.debug('EmailBody  before email sent :::' + messageBody +'/n :::: ' + newRegionAdded);
            objEmail.setHtmlBody(messageAddedBody + newRegionAddedBody + '<br> Please map the GSS Users accordingly.');
            mailsToBeSent.add(objEmail);  
            try{
                System.debug('sending email to :::::::::::::::::::' + objEmail);
                Messaging.sendEmail(mailsToBeSent,false);
            }
            catch(Exception ex){
                PSA_AutoCreateProjectUtil.sendErrorMails('Exception While sending GDRAT Allignment to SLDs from PSA_updateGDRATalignment ',ex.getMessage());
            }
            
            //18.10 : FFPSA-558 : create data for the present year for the new regions after allignment.
            //IW_CreateNewDataSet.createRegionRecsPresentYear();
            //19.5 clubed the creation Admin Slots to one method in below class
            IW_CreateNewDataSet.createRegionRecs();
            //IW_CreateNewDataSet.createGeoRecsPresentYear();

            
            //update setAlignmentNotified;
        }
        
    }
}