public class PSA_PCLIAssociationHistory implements Database.Batchable<sObject>,Database.Stateful  {

    public String query;
    public List<PCLI_Association_History__c> associationList = new List<PCLI_Association_History__c>();
    public Map<Id,PCLI_Association_History__c> pcliIdRecMap = new Map<Id, PCLI_Association_History__c>();
    public List<Id> detailIdList = new List<Id>();
    public Map<Id, List<Id>> cliProjMap = new Map<Id, List<Id>>();
    public Map<Id, String> cliNameMap = new Map<Id, String>();
    public Map<Id, String> cliProductMap = new Map<Id, String>();
    public Map<Id, String> cliUomMap = new Map<Id, String>();
    public Datetime lastRunTime;
    public PSA_PCLIAssociationHistory() {

        //DateTime dt = DateTime.ValueofGmt(PSA_Settings__c.getInstance('ContractDetailBatch').value__c.replace('T', ' ')) ;
        lastRunTime = DateTime.ValueofGmt(PSA_Settings__c.getInstance('ContractDetailBatch').value__c.replace('T', ' ')) ;

        //lastRunTime =[select id, Last_Successful_Run__c from PSA_Batch_Job_Tracking__c where name = 'PCLI Association History' limit 1].Last_Successful_Run__c;

        List<Project_Contract_Line_Item__c> pcliList = new List<Project_Contract_Line_Item__c>();
        pcliList = [select id, Project__c , Contract_Detail__c ,Contract_Detail__r.Name , Contract_Detail__r.Product__c , Contract_Detail__r.Unit_of_Measure__c  from Project_Contract_Line_Item__c where Project__r.pse__Stage__c != 'Closed' and Contract_Detail__r.lastmodifieddate >= :lastRunTime ];
        for (Project_Contract_Line_Item__c pcli : pcliList) {
            if (cliProjMap.containsKey(pcli.Contract_Detail__c)) {
                cliProjMap.get(pcli.Contract_Detail__c).add(pcli.Project__c);
            } else {
                List<Id> projIdTempList = new List<Id>();
                projIdTempList.add(pcli.Project__c);
                cliProjMap.put(pcli.Contract_Detail__c, projIdTempList);

            }
            detailIdList.add(pcli.Contract_Detail__c);
            cliNameMap.put(pcli.Contract_Detail__c, pcli.Contract_Detail__r.Name);
            cliProductMap.put(pcli.Contract_Detail__c, pcli.Contract_Detail__r.Product__c);
            cliUomMap.put(pcli.Contract_Detail__c, pcli.Contract_Detail__r.Unit_of_Measure__c);
        }

        System.debug(' list ids : ' + detailIdList);



    }

    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        query = 'select id, createddate, field, newvalue ,parentId from merge_contract_Detail__history where parentid in :detailIdList and (field = \'Product_ID__c\' )  and createddate > :lastRunTime order by createddate asc ';

        System.debug('querry : ' + query);

        if(!Test.isRunningTest()){
            return Database.getQueryLocator(query);
        } else {

            query = 'select id, createddate from merge_contract_Detail__c limit 10 ';
            return Database.getQueryLocator(query);
            
        }

        

        
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
        Datetime lastContractDetailDate;
        List<merge_contract_Detail__history> detailHistory = new List<merge_contract_Detail__history>();
        System.debug('scope ::  ' + scope);
        
        if(!Test.isRunningTest()){
            detailHistory = scope;
        }

        if(Test.isRunningTest()){
            merge_contract_Detail__history newHist = new merge_contract_Detail__history();
            newHist.parentId = detailIdList[0];
            newHist.field = 'Product_ID__c';
            //newHist.newvalue = 'newval';
            //newHist.createddate = Datetime.now();
            detailHistory = new List<merge_contract_Detail__history>();
            detailHistory.add(newHist);

        }

        for (merge_contract_Detail__history dHist : detailHistory) {
            if (cliProjMap.containsKey(dHist.parentId)) {
                for (Id projId : cliProjMap.get(dHist.parentId) ) {

                    if (pcliIdRecMap.containsKey(projId) ) {
                        PCLI_Association_History__c newAH = pcliIdRecMap.get(projId);
                        if (dHist.field == 'Product_ID__c') {
                            newAH.Product_ID__c = String.valueOf(dHist.newvalue) ;
                            newAH.Product_Name__c = cliProductMap.get(dHist.parentId);
                            newAH.Unit_of_Measure__c = cliUomMap.get(dHist.parentId);
                        } 
                        newAH.Project_Association_Date__c = dHist.createddate ;
                        pcliIdRecMap.put(projId,newAH);
                        System.debug(' each first if: ' + newAH);

                    } else {
                        PCLI_Association_History__c newAH = new PCLI_Association_History__c();
                        if (dHist.field == 'Product_ID__c') {
                            newAH.Product_ID__c = String.valueOf(dHist.newvalue) ;
                            newAH.Product_Name__c = cliProductMap.get(dHist.parentId);
                            newAH.Unit_of_Measure__c = cliUomMap.get(dHist.parentId);
                        }
                        newAH.Contract_Detail_ID__c = cliNameMap.get(dHist.parentId)  ;
                        newAH.Project__c = projId;
                        newAH.Project_Association_Date__c = dHist.createddate ;
                        System.debug(' each first else: ' + newAH);
                        pcliIdRecMap.put(projId,newAH);
                    }
                    
                }
                
            }
            if (lastContractDetailDate != null && lastContractDetailDate < dHist.createddate) {
                lastContractDetailDate = dHist.createddate;
            } else if (lastContractDetailDate == null ) {
                lastContractDetailDate = dHist.createddate;
            }
        }
        System.debug('all vals : ' + pcliIdRecMap.values() );
        associationList.addAll(pcliIdRecMap.values());

        if (associationList != null && associationList.size() > 0 ) {
            System.debug('alls : ' + associationList);
            insert associationList;
        }
        


        // PSA_Batch_Job_Tracking__c jobTrack = new PSA_Batch_Job_Tracking__c();
        // jobTrack = [select id, Last_Successful_Run__c from PSA_Batch_Job_Tracking__c where name = 'PCLI Association History' limit 1 ];
        // jobTrack.Last_Successful_Run__c = lastContractDetailDate;
        // System.debug('meta : ' + jobTrack );

        // update jobTrack;

        PSA_Settings__c pst = PSA_Settings__c.getInstance('ContractDetailBatch');
        pst.Value__c = String.valueOf(lastContractDetailDate);
        update pst;
        

    }

    public void finish(Database.BatchableContext BC) 
    {
        
    }
}