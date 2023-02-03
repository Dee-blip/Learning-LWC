/***
    PACE_LaunchItemStep_Controller
    @version 1.0
    @author Hitesh Chawda <hchawda@akamai.com>
    @Description : This Class is used for fetching the Package Design and Package Deployment Documents links fro Program Phhsase to the Catalog Updates.
    @History
    --Developer           --Date            --Change
    Hitesh Chawda          28-09-2012       1881694
*/
public with sharing class PACE_LaunchItemStep_Controller {
            private ApexPages.StandardController stdCtrl {get; set;}
            public PACE_StepDefinition__c packeageDesignstep {get; set;}
            public PACE_StepDefinition__c packeageDeploymentstep {get; set;}
            
            public List<PACE_Phase__c> definitionList {get; set;}
            public Id definitionId{get;set;}
            public Id developmentId{get;set;}
            public Id packageDesignRecordId{get; set;}
            public Id packageDeploymentRecordId{get; set;}
            public List<PACE_Step__c> stepRecordList;
            public List<PACE_Step__c> packageDesignList;
            public List<PACE_Step__c> packageDeplList;
            public List<PACE_Document_Link__c> packageDesignDocRecordList{get; set;}
            public List<PACE_Document_Link__c> packageDeploymentDocRecordList{get; set;}
            public List<PACE_Document_Link__c> stepDocRecordList{get; set;}
            public Boolean isPkgDesListNull{get; set;}
            public Boolean isListNull{get; set;}
            public Boolean isPkgDepListNull{get; set;}
            
public PACE_LaunchItemStep_Controller(ApexPages.StandardController stndCtrl) {
            stdCtrl = stndCtrl;
            stepRecordList = new List<PACE_Step__c>();
            packageDesignList = new List<PACE_Step__c>();
            packageDeplList = new List<PACE_Step__c>();
            packageDesignDocRecordList = new List<PACE_Document_Link__c>();
            packageDeploymentDocRecordList = new List<PACE_Document_Link__c>();
            stepDocRecordList = new List<PACE_Document_Link__c>();
             isPkgDesListNull=false;
             isPkgDepListNull=false;
             isListNull=false;
            getStepRecordList();
    }
    
    
public void getStepRecordList()
{
    PACECustomSettings__c defPahseRecordType = PACECustomSettings__c.getValues('DefinitionPhaseRecordTypeName');
    PACECustomSettings__c devPahseRecordType = PACECustomSettings__c.getValues('DevelopmentPhaseRecordTypeName');
    PACECustomSettings__c launchPahseRecordType = PACECustomSettings__c.getValues('LaunchPhaseRecordTypeName');
    PACECustomSettings__c packageDesignDocName = PACECustomSettings__c.getValues('Package Design');
    PACECustomSettings__c packageDeploymentDocName = PACECustomSettings__c.getValues('Package Deployment');
    Id prgmId;
    
    
    for(Launch_Item__c li : [SELECT Id,Program__c FROM Launch_Item__c where Id =: stdCtrl.getId()])
    {
        prgmId = li.Program__c;
    }
    
    
    for(PACE_Phase__c phaseRecord : [Select Id, Name,RecordType.Name From PACE_Phase__c where PACE_Program__c =:prgmId])
    {
        if(phaseRecord.RecordType.Name== defPahseRecordType.Value__c)
        {
            //definitionList.add(phaseRecord);
            definitionId = phaseRecord.Id;
        }
        else if(phaseRecord.RecordType.Name== devPahseRecordType.Value__c)
        {
            //developmentList.add(phaseRecord);
            developmentId = phaseRecord.Id;
        }
    }
    stepRecordList = [Select Name,Id,Phase__r.Id,Position__c From PACE_Step__c Where Phase__r.Id = :definitionId OR Phase__r.Id = :developmentId ];
    
    if(stepRecordList.size()>0)
    {
        for(PACE_Step__c stepItem : stepRecordList)
        {
            if(stepItem.Name == packageDesignDocName.Value__c)
            {
                packageDesignRecordId = stepItem.Id;
            }
            else if(stepItem.Name == packageDeploymentDocName.Value__c)
            {
                packageDeploymentRecordId = stepItem.Id;
            }
        }
    }
    stepDocRecordList = [SELECT Id,Name,Step__r.Id,Document_URL__c  FROM PACE_Document_Link__c WHERE Step__r.Id = :packageDesignRecordId OR Step__r.Id = :packageDeploymentRecordId ];
    
    if(stepDocRecordList.size()>0)
    {
        for(PACE_Document_Link__c stepDocItem : stepDocRecordList)
        {
            if(stepDocItem.Step__r.Id == packageDesignRecordId)
            {
                packageDesignDocRecordList.add(stepDocItem);
            }
            else if(stepDocItem.Step__r.Id == packageDeploymentRecordId)
            {
                packageDeploymentDocRecordList.add(stepDocItem);
            }
        }
    }
    
    if(packageDesignDocRecordList.size()==0)
    {
        isPkgDesListNull=true;
    
    }
    if(packageDeploymentDocRecordList.size()==0)
    {
            isPkgDepListNull=true;
    }
    
    if(isPkgDepListNull==true && isPkgDesListNull==true){
            isListNull=true;
    
    }
    
 }
}