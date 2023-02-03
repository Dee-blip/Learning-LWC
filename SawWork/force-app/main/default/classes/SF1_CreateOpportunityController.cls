global class SF1_CreateOpportunityController {

    @AuraEnabled
    public static List<Opportunity> getOpportunitiesByContractIds(String accountId, String[] contractIds) { // contract -> mch: merge_contract_header__c

        List<Opportunity> openRenewalOpps = new List<Opportunity>();
        List<Id> opportunityIDs = new List<Id>();
        //Id accId=null;
        System.debug('accid=' + accountId + '; contractIDs='+ contractIds);
        //SFDC-1394
        for(Renewal_Contract_Object__c renewalContract : [Select Opportunity__c,Contract__c, Contract__r.Original_Contract_Id__c from Renewal_Contract_Object__c where Contract__c IN:contractIds and Opportunity__c!=null]) //Contract__r.Original_Contract_Id__c

        {
            opportunityIDs.add(renewalContract.Opportunity__c);
        }
        System.debug('OpptyIds:' + Json.serialize(opportunityIDs));
        for(Opportunity opp: [Select Id,Name,CloseDate,StageName,MRR__c,Primary_Product_Name__c,Opportunity_Type__c from Opportunity Where AccountId =:accountId AND (NOT StageName like '%Closed%')/* AND Contract_Effective_End_Date__c = :mchSelected.Effective_End_Date__c */AND Id IN: opportunityIDs AND Opportunity_Type__c ='Renewal' ])
        {
            openRenewalOpps.add(opp);
        }

        System.debug('openRenewalOpps:' + Json.serialize(openRenewalOpps));
        return openRenewalOpps;

    }

    @AuraEnabled // List<Opportunity>
    public static ResultSetCustom getOpportunitiesByContractIdsPaginated(String accountId, String[] contractIds, Integer lim, Integer currentPage, String sortField, String sortOrder) { // contract -> mch: merge_contract_header__c

        //List<Opportunity> openRenewalOpps = new List<Opportunity>();
        List<Id> opportunityIDs = new List<Id>();
        Map<Id, Renewal_Contract_Object__c> opIDRenewalContractMap = new Map<Id, Renewal_Contract_Object__c>();

        System.debug('accid=' + accountId + '; contractIDs='+ contractIds);

        if (accountId==null || contractIds==null || contractIds.size()<1) {
            System.debug('inside null acc or contractids');
            return (new ResultSetCustom()); //openRenewalOpps;
        }

        sortField = String.isNotBlank(sortField) ? sortField : 'CloseDate';
        sortOrder = String.isNotBlank(sortOrder) ? sortOrder : 'ASC';

        //SFDC-1394
        for(Renewal_Contract_Object__c renewalContract : [Select Opportunity__c,Contract__c, Contract__r.Original_Contract_Id__c, Contract_Type__c
            from Renewal_Contract_Object__c where Contract__c IN:contractIds and Opportunity__c!=null]) //Contract__r.Original_Contract_Id__c
            {
                opportunityIDs.add(renewalContract.Opportunity__c);
                opIDRenewalContractMap.put(renewalContract.Opportunity__c, renewalContract);
            }

        if (opportunityIDs.size()<1)
            return new ResultSetCustom();

        System.debug('OpptyIds:' + Json.serialize(opportunityIDs));

        // soql-builder reference -> http://apex-commons.github.io/query/soql-builder/
        // Oppty query builder...
        Set<String> fieldSet = new Set<String>{'Id', 'Name', 'CloseDate', 'StageName', 'MRR__c', 'CurrencyIsoCode', 'Primary_Product_Name__c', 'Opportunity_Type__c'};
        String objAPIName = 'Opportunity';

        //get total rows
        al.SoqlBuilder soqlA = new al.SoqlBuilder()
        .selectCount()
        .fromx(objAPIName)
        .wherex(new al.AndCondition()
                .add(new al.FieldCondition('AccountId').equals(accountId))
                .add(new al.NotCondition(new al.FieldCondition('StageName').likex('%Closed%')))
                .add(new al.SetCondition('Id',al.Operator.INX,opportunityIDs))
                .add(new al.OrCondition().add(new al.FieldCondition('Opportunity_Type__c').equals('Renewal')).add(new al.FieldCondition('Opportunity_Type__c').equals('Auto-Renewal'))));
                String soqlCount = soqlA.toSoql();
        //System.assertEquals('expected', soqlCount);
        Integer totalRows = Database.countQuery(soqlCount + ' LIMIT 50000');
        //System.assertEquals(0, totalRows);

        // get records
        al.SoqlBuilder soqlB = new al.SoqlBuilder()
            .selectx(fieldSet)
            .selectx('id')
            .fromx(objAPIName)
            .wherex(new al.AndCondition()
                .add(new al.FieldCondition('AccountId').equals(accountId))
                .add(new al.NotCondition(new al.FieldCondition('StageName').likex('%Closed%')))
                .add(new al.SetCondition('Id',al.Operator.INX,opportunityIDs))
                .add(new al.FieldCondition('Opportunity_Type__c').equals('Renewal')));
        String soql = soqlB.toSoql();
        soql += ' order by '+sortField+' '+sortOrder+' LIMIT '+lim +' Offset '+ currentPage;
        //--- --- ---
        System.debug('Query String=' + soql);

        //return Database.query(soql);
        return new ResultSetCustom(Database.query(soql), totalRows, opIDRenewalContractMap);
        //return new ResultSetCustom(getAllOpportunitiesByContractIds(accountId, contractIds, sortField, sortOrder, String.valueOf(lim), String.valueOf(currentPage)), totalRows, opIDRenewalContractMap);

    }

    @AuraEnabled
    public static List<Opportunity> getOpportunitiesByAccountId(String accountId) {
        List<Opportunity> openOpps = new List<Opportunity>();
        String soql = 'select Id,name,CloseDate,StageName,MRR__c,Primary_Product_Name__c,Opportunity_Type__c from Opportunity';
                soql += ' where Opportunity.AccountId=\''+ accountId + '\' and (not StageName like \'%Closed%\') ORDER BY CloseDate DESC LIMIT 20';
        System.debug('soql:' + soql);
        return database.query(soql);

        //openOpps.addAll(database.query(soql));
        //System.debug('openOpps:' + Json.serialize(openOpps));
        //return openOpps;

    }

    @AuraEnabled
    public static ResultSetCustom getOpportunitiesByAccountIdPaginated(String accountId, Integer lim, Integer currentPage, String sortField, String sortOrder) {

        sortField = String.isNotBlank(sortField) ? sortField : 'CloseDate';
        sortOrder = String.isNotBlank(sortOrder) ? sortOrder : 'ASC';

        // Oppty query builder...
        // Reference -> http://apex-commons.github.io/query/soql-builder
        Set<String> fieldSet = new Set<String>{'Id', 'Name', 'CloseDate', 'StageName', 'MRR__c', 'CurrencyIsoCode', 'Primary_Product_Name__c', 'Opportunity_Type__c'};
        String objAPIName = 'Opportunity';

        // get total rows
        al.SoqlBuilder soqlA = new al.SoqlBuilder()
        .selectCount()
        .fromx(objAPIName)
        .wherex(new al.AndCondition()
                .add(new al.FieldCondition('AccountId').equals(accountId))
                .add(new al.NotCondition(new al.FieldCondition('StageName').likex('%Closed%'))));
        String soqlCount = soqlA.toSoql();
        //System.assertEquals('expected', soqlCount);
        Integer totalRows = Database.countQuery(soqlCount + ' LIMIT 50000');
        //System.assertEquals(0, totalRows);

        // get records
        al.SoqlBuilder soqlB = new al.SoqlBuilder()
            .selectx(fieldSet)
            .fromx(objAPIName)
            .wherex(new al.AndCondition()
                .add(new al.FieldCondition('AccountId').equals(accountId))
                .add(new al.NotCondition(new al.FieldCondition('StageName').likex('%Closed%'))));
        String soql = soqlB.toSoql();
        soql += ' order by '+sortField+' '+sortOrder+' LIMIT '+lim +' Offset '+ currentPage;
        //--- --- ---
        System.debug('Query String=' + soql);

        //return Database.query(soql);
        return new ResultSetCustom(Database.query(soql), totalRows);

    }

    @AuraEnabled
    public static List<Opportunity> getOpportunities() { // contract -> mch: merge_contract_header__c

        List<Opportunity> openRenewalOpps = new List<Opportunity>();
        for(Opportunity opp: [Select Id,Name,CloseDate,StageName,MRR__c,Primary_Product_Name__c,Opportunity_Type__c from Opportunity Where (NOT StageName like '%Closed%') AND Opportunity_Type__c ='Renewal' LIMIT 10000 ])
        {
            openRenewalOpps.add(opp);
        }

        System.debug('openRenewalOpps:' + Json.serialize(openRenewalOpps));
        return openRenewalOpps;

    }

    @AuraEnabled
    public static List<Renewal_Contract_Object__c> getRenewalContractsByOpttyId(String opptyId) {

        //List<Renewal_Contract_Object__c> renewalOpptyList = new List<Renewal_Contract_Object__c>();
        return [Select Contract__c,Contract_Effective_End_Date__c,Contract_Id_Text__c,Parent_Contract__c,
                       Parent_Contract__r.Name,Order_Id__c,Contract_Type__c,Parent_Account_Name__c, Parent_Account_Name__r.Name
                FROM Renewal_Contract_Object__c WHERE Opportunity__c =:opptyId];
        // Parent_Contract__r.Name,
    }

    public class ResultSetCustom {
        @AuraEnabled public List<sObject> rows {get; set;}
        @AuraEnabled public Integer size {get; set;}
        @AuraEnabled public Map<Id, sObject> rowsMap {get; set;}
        //@AuraEnabled public List<Cell> columnHeader {get; set;}
        public ResultSetCustom(){}

        public ResultSetCustom(List<sObject> rw, Integer siz) {
            this.rows = rw;
            this.size = siz;
        }

        public ResultSetCustom(List<sObject> rw, Integer siz, Map<Id, sObject> rwMap) {
            this.rows = rw;
            this.size = siz;
            this.rowsMap = rwMap;
        }
    }


}