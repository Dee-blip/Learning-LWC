/***
    PACE_ContingencyPageController
    @version 1.0
    @author Hitesh Chawda <hchawda@akamai.com>
    @Description : This Class is used for fetching all the Contingencies for the Phases and Concepts under a Review Calendar Record.
    @History
    --Developer           --Date            --Change
    Hitesh Chawda          28-09-2012       1879057
*/
public class PACE_ContingencyPageController {
    public List<PACE_Phase__c> phaseRecordList; 
  //  public List<PACE_Concept__c> conceptRecordList;
    public List<Contingency__c> contingencyRecordList{get; set;}
    public Boolean isListNull{get; set;}

    private ApexPages.StandardController stdCtrl {get; set;}
    public Set<Id> phaseIdList = new Set<Id>();
    public Set<Id> conceptIdList = new Set<Id>();
    public Id phaseRecord;
    //public String baseURL {get; set;}
    
    public  PACE_ContingencyPageController(ApexPages.StandardController stndCtrl) {
    stdCtrl = stndCtrl;
    phaseRecordList =  new List<PACE_Phase__c>();
    //conceptRecordList = new List<PACE_Concept__c>();
    contingencyRecordList = new List<Contingency__c>();
    isListNull=false;
    getContingencyRecords();
    }
    
  public void getContingencyRecords(){
        
        //PACECustomSettings__c currenturl = PACECustomSettings__c.getValues('currentInstanceURL');
        //baseURL = currenturl.Value__c;
        for(PACE_Phase__c phaseRecord : [SELECT Id,Contingency__c,Exception_Review_Date__c,PRB_Review_Date__c FROM PACE_Phase__c WHERE Exception_Review_Date__c = :stdCtrl.getId() OR PRB_Review_Date__c = :stdCtrl.getId()])
            {
                phaseRecordList.add(phaseRecord);
                phaseIdList.add(phaseRecord.Id);
            }
      /*  for(PACE_Concept__c conceptRecord : [SELECT Id,Contingency__c,Concept_PRB_Review_Date__c FROM PACE_Concept__c WHERE Concept_PRB_Review_Date__c = :stdCtrl.getId()])
            {
                conceptRecordList.add(conceptRecord);
                conceptIdList.add(conceptRecord.Id);
            }
            */
        for(Contingency__c conRecord : [SELECT Id,Name,Closed_Date__c,Due_Date__c,OwnerId,Phase__c,Phase__r.Name,Priority__c,Status__c FROM Contingency__c where Phase__r.Id IN :phaseIdList ORDER BY Status__c ASC ])
            {        
                contingencyRecordList.add(conRecord);
            }
            if(contingencyRecordList.size()==0)
            {
                isListNull=true;
            }

    }

}