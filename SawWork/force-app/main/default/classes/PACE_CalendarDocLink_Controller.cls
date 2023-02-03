/***
    PACE_CalendarDocLink_Controller
    @version 1.0
    @author Hitesh Chawda <hchawda@akamai.com>
    @Description : This Class is used for fetching the Package Design and Package Deployment Documents links fro Program Phhsase to the Catalog Updates.
    @History
    --Developer           --Date            --Change
    Hitesh Chawda          08-09-2013       2221076
*/
public with sharing class PACE_CalendarDocLink_Controller {
            
            private ApexPages.StandardController stdCtrl {get; set;}
            public List<PACE_Phase__c> phaseList {get; set;}
            public Set<Id> phaseIdList = new Set<Id>();
            public Set<Id> stepRecordIdList = new Set<Id>();
            public List<PACE_Step__c> stepRecordList;
            public List<PACE_Step__c> packageDesignList;
            public List<PACE_Document_Link__c> packageDesignDocRecordList{get; set;}
            public List<PACE_Document_Link__c> stepDocRecordList{get; set;}
            public Boolean isPkgDesListNull{get; set;}
           
            
public PACE_CalendarDocLink_Controller(ApexPages.StandardController stndCtrl) {
            stdCtrl = stndCtrl;
            phaseList = new List<PACE_Phase__c>();
            stepRecordList = new List<PACE_Step__c>();
            packageDesignList = new List<PACE_Step__c>();
            packageDesignDocRecordList = new List<PACE_Document_Link__c>();
            stepDocRecordList = new List<PACE_Document_Link__c>();
             isPkgDesListNull=false;
             
            getStepRecordList();
    }
    
    
public void getStepRecordList()
{
    PACECustomSettings__c packageDesignDocName = PACECustomSettings__c.getValues('Package Design');
    // Get all the Phases for the SIR date
    
    for(PACE_Phase__c  phaseRecord : [SELECT Id,Name,SIR_Meeting_Date__c FROM PACE_Phase__c where SIR_Meeting_Date__c =: stdCtrl.getId()])
    {
      phaseList.add(phaseRecord);
    }
    //Get all the Steps for all the Phases lying under the SIR date
    if(phaseList.size()>0)
    {
        for(PACE_Phase__c phaseRecord : phaseList)
        {
           phaseIdList.add(phaseRecord.Id);
        }
        
        stepRecordList = [Select Name,Id,Phase__r.Id,Position__c From PACE_Step__c WHERE Phase__r.Id IN :phaseIdList ];
    }
    //Get all the Package Design steps first and based on these IDs get Document Links 
    if(stepRecordList.size()>0)
    {
        for(PACE_Step__c stepItem : stepRecordList)
        {
            if(stepItem.Name == packageDesignDocName.Value__c)
            {
                stepRecordIdList.add(stepItem.Id);
            }
            
        }
        stepDocRecordList = [SELECT Id,Name,Step__r.Id,Document_Address__c,Document_URL__c  FROM PACE_Document_Link__c WHERE Step__r.Id IN :stepRecordIdList ];
    }
    if(stepDocRecordList.size()>0)
    {
        for(PACE_Document_Link__c stepDocItem : stepDocRecordList)
        {
                packageDesignDocRecordList.add(stepDocItem);
        }
    }
    
    if(packageDesignDocRecordList.size()==0)
    {
        isPkgDesListNull=true;
    }
    
    
 }
}