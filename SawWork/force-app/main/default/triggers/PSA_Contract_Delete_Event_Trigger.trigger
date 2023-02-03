trigger PSA_Contract_Delete_Event_Trigger on PSA_Contract_Detail_Delete__e (after insert) {
    List<PCLI_Association_History__c> pcliAH = new List<PCLI_Association_History__c>();
    List<Project_Contract_Line_Item__c> pclis = new List<Project_Contract_Line_Item__c>();
    System.debug('con det deleted');
    List<String> cliId = new List<String>();
    for (PSA_Contract_Detail_Delete__e cde : Trigger.new) {
        cliId.add(cde.Contract_Detail_ID__c);
        System.debug('all eee ' + cde);
        
    }

    try {
        
        pclis = [select id,Project__c, Merge_Contract_Detail_Id__c from Project_Contract_Line_Item__c where lastmodifieddate = LAST_N_DAYS:1];
        System.debug('all pclis ' +pclis );

        for (Project_Contract_Line_Item__c eachPcli : pclis) {
            System.debug(' details :' + cliId );
            System.debug(' all dets : ' + cliId.contains(eachPcli.Merge_Contract_Detail_Id__c)  );
            if ( eachPcli.Merge_Contract_Detail_Id__c != null && cliId.contains(eachPcli.Merge_Contract_Detail_Id__c) ) {
                PCLI_Association_History__c newpcliah = new PCLI_Association_History__c();
                newpcliah.Contract_Detail_ID__c = eachPcli.Merge_Contract_Detail_Id__c;
                newpcliah.Project_Disassociation_Date__c = Datetime.now();
                newpcliah.Project__c = eachPcli.Project__c;
                pcliAH.add(newpcliah);
            }
        }

        if (pcliAH != null && pcliAH.Size()> 0) {
            insert pcliAH;
        }

        
    } catch (Exception e) {
        PSA_AutoCreateProjectUtil.sendErrorMails('Error in creating pcli ah',e.getMessage());
    }


    


    


}