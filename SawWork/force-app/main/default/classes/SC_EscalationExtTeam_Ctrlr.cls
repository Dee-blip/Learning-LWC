/* 
Description: Extension class for Escalation(previously Engagament Request) Creation,Edit and Clone page for External Team
Test Class: SC_EscalationExtTeam_Ctrlr_Test

Date                  Developer            		JIRA #                 	Description                                                       
------------------------------------------------------------------------------------------------------------------
17 May 2018      Vandhana Krishnamurthy        ESESP-319      		OLAs for Escalation
*/

public with sharing class SC_EscalationExtTeam_Ctrlr
{
	// variable declaration
    public Engagement_Request__c escalation {get;set;}
    private Boolean error;
    
    public String escalationQuery;
    
    public List<System_to_Area_Mapping__c> sys2AreaMapping;
    public Map<String,String> sys2AreaMapList;
    public Map<String,String> sys2URLMap;
    
    // CONSTRUCTORS
    public SC_EscalationExtTeam_Ctrlr()
    {}
    
    public SC_EscalationExtTeam_Ctrlr(ApexPages.StandardController controller)
    {
        escalation = (Engagement_Request__c) controller.getRecord();
        
        initialize();
        
        if(String.isNotBlank(escalation.Id))
        {
            escalation = Database.query(escalationQuery);
        }
        else
        {
            escalation = new Engagement_Request__c();
            escalation.OwnerId = UserInfo.getUserId();
        }
        
        //if (ApexPages.currentPage().getParameters().get('RecordType') != null)
        if (ApexPages.currentPage().getParameters().get('RecordType') != null)
            escalation.RecordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
        
        //This parameter is set when case creation happens from the case related list on account detail page
        if (ApexPages.currentPage().getParameters().get('CF00NG000000A1cSF_lkid') != null)
        {
        	Id caseId = ApexPages.currentPage().getParameters().get('CF00NG000000A1cSF_lkid');
            escalation.Case__c = caseId;
        }    
        
        if (ApexPages.currentPage().getParameters().get('clone') != null)
        {
            escalation.AKAM_Engagement_Request_ID__c = NULL;
            escalation.Id = NULL;
        }
    }
    
    public void clearValues()
    {
        escalation.Subject__c = '';
        escalation.Description__c = '';
        escalation.ER_Severity__c = '';
        escalation.Request_Status__c = '';
        escalation.URL__c = '';
        escalation.Accepted_Date__c = NULL;
        escalation.Escalation_Closed_Date__c = NULL;
    }
    
    public PageReference Redirect()
    {
        PageReference ref;
        //Navigate user to override page if override is true
        if(escalation.RecordTypeId == Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('External Team').getRecordTypeId())
        {
            ref = Page.SC_EscalationExtTeam;
        } 
        //Navigate user to default Escalation Edit page if Escalation already exists and is not External Team rec type
        else if(escalation.Id != null) 
        {
            ref = new PageReference('/' + escalation.Id + '/e?nooverride=1');
        } 
        //Navigate user to default new Escalation creation page
        else 
        {
            ref = new PageReference('/' + Schema.Sobjecttype.Engagement_Request__c.getKeyPrefix() + '/e?nooverride=1');
        }
        
        //fetch all parameters and pass to the redirected URL
        Map<String, String> parameters = ApexPages.currentPage().getParameters(); 

        for(String s: parameters.keySet())
        {
            //exclude sfdc.override and save_new as these cannot be used for overriden functionalities
            if(s != 'sfdc.override' && s != 'save_new')
                ref.getParameters().put(s,parameters.get(s));
        }
        ref.setRedirect(true);
        return ref;
    }  
    
    public void initialize()
    {
        if(escalation.Id != NULL)
        {
            escalationQuery = 'Select Id,Name,Owner.Name,ID__c,RecordTypeId,CreatedDate,Accepted_Date__c,ER_Severity__c,Subject__c,Escalation_Owner__c,' +
                			  'Escalation_Created_By__c,Time_To_Accept__c ,Escalation_Created_Date__c,Request_Status__c,URL__c,System__c,Area__c,Escalation_TTR__c,Description__c,OwnerId,Case__c,Escalation_Closed_Date__c' ;
            
            escalationQuery += ' FROM Engagement_Request__c where Id = \'' + escalation.Id + '\'';
        }
        
        sys2AreaMapping = new List<System_to_Area_Mapping__c>();
        sys2AreaMapList = new Map<String,String>();
        sys2URLMap = new Map<String,String>();
        
        sys2AreaMapping = [SELECT System__c, Area__c, System_URL__c 
                           FROM System_to_Area_Mapping__c
                           ORDER BY System__c
                          ];
        
        for(System_to_Area_Mapping__c eachRec : sys2AreaMapping)
        {
            sys2AreaMapList.put(eachRec.System__c,eachRec.Area__c);
            sys2URLMap.put(eachRec.System__c,eachRec.System_URL__c);
        }
    }
    
    public List<SelectOption> getsystem()
    {
        List<SelectOption> lstOptions = new List<SelectOption>();
		Set<String> systemOptions = new set<String>();
        
        if(String.isNotBlank(escalation.System__c))
        {
            systemOptions.add(escalation.System__c);
        }
        
        //Add current Service value to the drop down on loading case for editing
        if(!sys2AreaMapping.isEmpty())
        {    
            for(System_to_Area_Mapping__c eachRec : sys2AreaMapping)
            {
                systemOptions.add(eachRec.System__c.trim());
            }
        }
        
        // populate Service Picklist with value,name
        for(String s : systemOptions)
        {
            lstOptions.add(new SelectOption(s,s));
        }    
        
        // sort Service options alphabetically
        lstOptions.sort();
        
        // add --None-- as the 1st option
        if(lstOptions.size() > 0)
            lstOptions.add(0,new SelectOption('--None--','--None--'));
        else
            lstOptions.add(new SelectOption('--None--','--None--'));
        
        return lstOptions;
    }
    
    public List<SelectOption> getarea()
    {
        List<SelectOption>lstOptions = new List<SelectOption>();
        
        //Add current Service value to the drop down on loading case for editing
        if(String.isBlank(escalation.System__c) || String.isBlank(escalation.Area__c) || escalation.System__c.equals('--None--') )
        {    
            escalation.Area__c = '--None--';
            lstOptions.add(new SelectOption('--None--','--None--'));
        }
        else
        {
            if(sys2AreaMapList.containsKey(escalation.System__c))
            {
                List<String> areaVal = sys2AreaMapList.get(escalation.System__c).split('[;\n\r]');
                Set<String> a = new Set<String>(areaVal);
                for(String eachArea : a)
                {
                    if(String.isNotBlank(eachArea))
                    	lstOptions.add(new SelectOption(eachArea.trim(),eachArea.trim()));
                }
                // sort Service options alphabetically
                lstOptions.sort();
            	lstOptions.add(0,new SelectOption('--None--','--None--'));
            }
            else
            {
                lstOptions.add(new SelectOption(escalation.Area__c,escalation.Area__c));
                lstOptions.add(0,new SelectOption('--None--','--None--'));
            }
        }
        return lstOptions;
    }
    
    public PageReference Save()
    {
        try
        {
            error = false;
            
            if(escalation.System__c.contains('None'))
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'System' + ': You must enter a value'));
                error = true;
            }
                
            if(escalation.Area__c.contains('None'))
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Area' + ': You must enter a value'));
                error = true;
            }
            
            if(//String.isBlank(escalation.URL__c) && 
               String.isNotBlank(sys2URLMap.get(escalation.System__c)))
            {
                escalation.URL__c = sys2URLMap.get(escalation.System__c) + escalation.ID__c;
            }
            
            //if no error proceed to save
            if(!error)
            {
                //save the data and redirect user to the case detail page
                upsert escalation;
                PageReference ref = new PageReference('/' + escalation.Id);
                ref.setRedirect(true);
                return ref;
            }
        } 
        catch (Exception ex) 
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,CommonUtilClass.ExtractValidationExMsg(ex)));
        }
        return null;
    }
}