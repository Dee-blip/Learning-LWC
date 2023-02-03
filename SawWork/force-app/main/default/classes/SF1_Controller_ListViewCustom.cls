/**
*  SF1_Controller_ListViewCustom
*
 --Developer         --Date          --Description
   Sausharm           27/03/2017      Initial version for SF1 Custom List View Implmentation
   Sausharm           04/04/2017      Added queries for Activty and Task as it is not supported by StandardSetCOntroller
   Raashok            26/04/2017      Added Filter for 'My Accounts' List view
**/

public class SF1_Controller_ListViewCustom {

private static ApexPages.StandardSetController getSControllerForSObjectType(String objectType)
    {
        if( objectType == 'Fund Request')
        {
            objectType = 'SFDC_MDF__c';
        }
        String query;

        query = 'SELECT Id, Name, OwnerId FROM '+objectType+' limit 1';
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
         query));
        return setCon;
    }
    
    

    @AuraEnabled
    public static List<String> getListViewLabels(String objectType, boolean useFilter)
    {
        List<String> listViewNamesList = new List<String>();

        if( objectType == 'Activity')
        {
            listViewNamesList = getActivityListViews();
        }
        else
        {
        
            ApexPages.StandardSetController setCon = getSControllerForSObjectType(objectType);

            for( SelectOption so :setcon.getListViewOptions())
            {    
                if(useFilter == true)
                {

                    if( getAvailableListViews().contains(so.getValue()))
                    {   
                        listViewNamesList.add(so.getLabel());
                    }  
                }
                else
                {
                    listViewNamesList.add(so.getLabel());
                }
            }
        }

        return listViewNamesList;
    }




    @AuraEnabled
    public static List<SObject> getDetails(String userSelection, String objectType, String startValue, String pageSize) 
    {
         
        List<SObject> opplist = new List<SObject>();
        if (objectType == 'Activity')
        {
            opplist = getDetailsActivity(userSelection, Integer.valueof(startValue), Integer.valueof(pageSize));
        }
         else
         {
        
            ApexPages.StandardSetController setCon = getSControllerForSObjectType(objectType);

            Map<String,Id> listViewNameToIdMap = new Map<String,Id>();
            List<String> listViewNamesList = new List<String>();

            for( SelectOption so :setcon.getListViewOptions())
            {
            
                listViewNameToIdMap.put(so.getLabel(),so.getValue());
                listViewNamesList.add(so.getLabel());

            }
            if(userSelection == null)
            {
                userSelection = listViewNamesList.get(0);
            }
        
            Id listViewFilterId = listViewNameToIdMap.get(userSelection);
            System.debug('Raashok--->'+listViewFilterId);
            System.debug('Raashok--->'+userSelection);
            if(listViewFilterId != null)
            {
                setCon.setFilterId(listViewFilterId);
            
                setCon.setPageSize(Integer.valueof(pageSize));
                Integer pg = 1;
                if(startValue!= '0')
                {   
                    pg = Integer.valueof(startValue)/Integer.valueof(pageSize) + 1;
                }
                setCon.setPageNumber(1);
                List<SObject> page1Records = new  List<SObject>();
                page1Records.addAll(setcon.getRecords());

                setCon.setPageNumber(pg);
                List<SObject> pageNRecords = new  List<SObject>();
                pageNRecords.addAll(setcon.getRecords());
                if(!page1Records.equals(pageNRecords))
                {
                    opplist.addAll(pageNRecords);
                }
                else if(pg == 1)
                {
                    opplist.addAll(page1Records);
                }
               
                
            }

        }
        return opplist;

    }

   @TestVisible private static Set<String> getAvailableListViews()
    {
        
        Set<String> allowedListViews = new Set<String>();
        List<String> lvSetting = new List<String>();
        if(SF1_Enabled_ListViews__c.getInstance() != null && SF1_Enabled_ListViews__c.getInstance().Enabled_LV_Ids_1__c != null && SF1_Enabled_ListViews__c.getInstance().Enabled_LV_Ids_1__c != '')
        {
            lvSetting.addAll(SF1_Enabled_ListViews__c.getInstance().Enabled_LV_Ids_1__c.split(','));
        }
        if(SF1_Enabled_ListViews__c.getInstance() != null && SF1_Enabled_ListViews__c.getInstance().Enabled_LV_Ids_2__c != null && SF1_Enabled_ListViews__c.getInstance().Enabled_LV_Ids_2__c != '')
        {
            lvSetting.addAll(SF1_Enabled_ListViews__c.getInstance().Enabled_LV_Ids_2__c.split(','));
        }

        for( String idrec : lvSetting)
        {
            allowedListViews.add(idrec);
        }
        
        return allowedListViews;

    }


    @TestVisible
    public static List<String> getActivityListViews()
    {
        Profile p = [Select Name from Profile where Id =: userinfo.getProfileid()];
        String pname = p.name;
        List<String> li = new List<String>();

        if(pname == 'CMG' || pname == 'Business Operations' || pname == 'System Administrator' || pname == 'Engineering' )
        {
            li.add('CMG Contracts Not Started');
        }
        if(pname == 'Collections' || pname == 'Business Operations' || pname == 'System Administrator' || pname == 'Engineering' )
        {
            li.add('Credit Check Activities');
        }
        if(pname == 'Deal Desk' || pname == 'Business Operations' || pname == 'System Administrator' || pname == 'Engineering' )
        {
            li.add('DD Activities');
        }
        if(pname == 'Legal' || pname == 'Business Operations' || pname == 'System Administrator' || pname == 'Engineering' )
        {
            li.add('Legal Activities');
        }

        return li;
    }
 
    @TestVisible
    private static List<SObject> getDetailsActivity(String userSelection, Integer startValue, Integer pageSize)
    {
       
        List<SObject> activityList = new List<SObject>();
         if(userSelection == 'CMG Contracts Not Started')
        {
            for( Task t : [select id,subject from task where status = 'Not Started' AND Subject = 'Request for Contract Entry' order by AKAM_Created_Date__c DESC  limit :pageSize offset :startValue])
            {
                activityList.add(t);
            }
        }
        else  if(userSelection == 'Credit Check Activities')
        {
            Date dayminus60 = System.Today().addDays(-60);
           
            for( Task t : [select id,subject from task where Owner.Alias = 'collqueu' AND Status != 'Completed' AND AKAM_Created_Date__c >:dayminus60 order by AKAM_Created_Date__c DESC  limit :pageSize offset :startValue])
            {
                activityList.add(t);
            }
        }
        else  if(userSelection == 'DD Activities')
        {
            for( Task t : [select id,subject from task where Task_Type__c = 'Deal Desk' AND status != 'Completed' AND What.Name like 'OA%' order by AKAM_Created_Date__c DESC  limit :pageSize offset :startValue])
            {
                activityList.add(t);
            }
        }
        else  if(userSelection == 'Legal Activities')
        {
           
            for( Task t : [select id,subject from task where Task_Type__c = 'Legal' AND
                                                             Status != 'Completed' AND
                                                             (Owner.alias = 'RSTEVENS' OR Owner.Alias = 'MANDESHA' OR Owner.Alias = 'CMCSWEEN' OR Owner.Alias = 'CDOHERTY' OR Owner.Alias = 'AGERNHAR' OR Owner.Alias = 'ABALAZIN' OR Owner.Alias = 'TPELC' OR Owner.Alias = 'ABUZONNO' OR Owner.Alias = 'TSINGHVO' OR Owner.Alias = 'AGIBEK') AND
                                                             What.Name like 'OA-%'
                                                             order by AKAM_Created_Date__c DESC  limit :pageSize offset :startValue])
            {
                activityList.add(t);
            }
        }
        return activityList;
    }

}