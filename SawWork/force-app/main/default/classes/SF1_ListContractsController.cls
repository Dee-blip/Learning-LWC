global class SF1_ListContractsController {

        @AuraEnabled
        public static List<Merge_Contract_Header__c> getActiveContractsWithProductsByAccId(Account acc) {

                return [SELECT Id, name, Contract_Type__c, Parent_Contract__c, Parent_Contract__r.Name, Order_Id__c, Parent_Account_Name__c, Currency__c,
                        Solution_Set__c,Effective_Start_Date__c, CurrencyIsoCode, Account_Name__c, Account_Name__r.Id, Account_Name__r.Name, Active__c,
                        Effective_End_Date__c, Original_Contract_Id__c, Opportunity_Name__r.currencyIsoCode, Opportunity_Name__r.Deal_Type__c,
                        Opportunity_Name__r.Partner_Involved__c, Contract_Product_Count__c, (SELECT Id, CurrencyIsoCode, Average_Renewal_Commit_MRR__c,
                                                                                             Average_Renewal_Usage_MRR__c, Forecast_Product_Id__c FROM Contract_Products__r) FROM Merge_Contract_Header__c
                        WHERE Account_Name__c =: acc.Id AND Active__c = true AND Effective_End_Date__c >= LAST_N_MONTHS : 2
                                                                        AND Contract_Product_Count__c > 0 ORDER BY Effective_End_Date__c ASC];

        }

        public class ResultSetCustom {
                @AuraEnabled public List<sObject> rows {get; set;}
                @AuraEnabled public Integer size {get; set;}
                //@AuraEnabled public List<Cell> columnHeader {get; set;}

                public ResultSetCustom(List<sObject> rw, Integer siz) {
                        this.rows = rw;
                        this.size = siz;
                }
        }

        @AuraEnabled
        public static ResultSetCustom getActiveContractsByAccIdPagination(Account acc, Integer lim, Integer currentPage, String sortField, String sortOrder) {

                //get total rows
                String countQuery = 'Select count()'+' FROM ';
                countQuery += 'Merge_Contract_Header__c WHERE Account_Name__c =\'' + acc.Id + '\'';
                countQuery += ' AND Active__c = true AND Effective_End_Date__c >= LAST_N_MONTHS:2 AND Contract_Product_Count__c > 0';
                System.debug(Logginglevel.info, 'countQuery ===== '+countQuery);
                Integer totalRows = Database.countQuery(countQuery+ ' LIMIT 50000');
                //get records

                sortField = String.isNotBlank(sortField) ? sortField : 'Effective_End_Date__c';
                sortOrder = String.isNotBlank(sortOrder) ? sortOrder : 'ASC';
                String query = 'SELECT Id, name, Contract_Type__c, Parent_Contract__c, Parent_Contract__r.Name, Order_Id__c, Parent_Account_Name__c, Parent_Account_Name__r.Name,';
                query += 'Currency__c, Solution_Set__c,Effective_Start_Date__c, Is_Auto_Renew__c ,CurrencyIsoCode, Account_Name__c, Account_Name__r.Id, ';
                query += 'Account_Name__r.Name , Active__c,Effective_End_Date__c , Original_Contract_Id__c, Opportunity_Name__r.currencyIsoCode, ';
                query += 'Opportunity_Name__r.Deal_Type__c, Opportunity_Name__r.Partner_Involved__c, Contract_Product_Count__c, (SELECT Id, ';
                query += 'CurrencyIsoCode, Average_Renewal_Commit_MRR__c, Average_Renewal_Usage_MRR__c, Forecast_Product_Id__c FROM Contract_Products__r) ';
                query += 'FROM Merge_Contract_Header__c WHERE Account_Name__c =\'' + acc.Id + '\'';
                query += ' AND Active__c = true AND Effective_End_Date__c >= LAST_N_MONTHS:2 AND Contract_Product_Count__c > 0'; // ORDER BY Effective_End_Date__c ASC]';
                query += ' order by '+sortField+' '+sortOrder+' LIMIT '+lim +' Offset '+ currentPage;
                System.debug(Logginglevel.info, 'Full Query ===== '+query);

                Map<String, Product2> productAkamIdMap = new Map<String, Product2>();
                for (product2 pr : [Select Id, Name, Akam_Product_Id__c from Product2 limit 50000]) {
                        productAkamIdMap.put(pr.Akam_Product_Id__c, pr);
                }

                System.debug('productAkamIdMap.size=' + productAkamIdMap.size());

                //return (List<Merge_Contract_Header__c>) Database.query(query);
                List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
                Set<String> akamProdId = new Set<String>();
                for (Merge_Contract_Header__c mch : Database.query(query)) {

                        system.debug('mch.OCID=' + mch.Original_Contract_Id__c + 'contractProducts=' + mch.Contract_Products__r.size());

                        // if (mch.Contract_Products__r.size()>0) {
                        // Replace the
                        for (Contract_Product__c cpr : mch.Contract_Products__r) {
                                if(productAkamIdMap.size()<1)
                                        break;
                                if(productAkamIdMap.get(cpr.Forecast_Product_Id__c)==null)
                                        continue;

                                System.debug('Forecast_Product_Id__c before=' + cpr.Forecast_Product_Id__c);
                                cpr.Forecast_Product_Id__c = productAkamIdMap.get(cpr.Forecast_Product_Id__c).Name;
                                System.debug('cpr.Forecast_Product_Id__c after=' + cpr.Forecast_Product_Id__c);
                        }
                        mchList.add(mch);

                }

                //List<Merge_Contract_Header__c> mchList = getActiveContractsByAccId(acc.Id, sortField, sortOrder, String.valueOf(lim), String.valueOf(currentPage));

                //return new ResultSetCustom(Database.query(query), totalRows);
                return new ResultSetCustom(mchList, totalRows);
        }
}