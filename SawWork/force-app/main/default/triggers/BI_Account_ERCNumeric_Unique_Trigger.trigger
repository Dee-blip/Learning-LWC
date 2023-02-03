trigger BI_Account_ERCNumeric_Unique_Trigger on Account (before insert, before update) {

        if(Trigger.isBefore && Trigger.isInsert){
            Set<String> ercNumericIds = new Set<String>();
            for(List<Account> accs : [SELECT ERC_Numeric__c from Account where AKERC__c != NULL and ERC_Numeric__c != NULL]){
                for(Account acc: accs){
                    ercNumericIds.add(acc.ERC_Numeric__c);
                }
            }
            for (Account acc : Trigger.new){
                if(acc.AKERC__c != null && !acc.AKERC__c.equals(' ')){
                    String AKERCValue = acc.AKERC__c;
                    String ERCNumericValue = SupportTeamMgmt_Utility.getERCNumeric(AKERCValue);
                    if(!ercNumericIds.isEmpty() && ercNumericIds.contains(ERCNumericValue)){
                        acc.addError('ERCNumeric value is not unique, please provide a different AKERC value');
                       }
                    else{
                      ercNumericIds.add(ERCNumericValue);
                    }
                }
            }
        }

        else if (Trigger.isBefore && Trigger.isUpdate){
            Set<String> ercNumericIds = new Set<String>();
            for(List<Account> accs : [SELECT ERC_Numeric__c from Account where AKERC__c != NULL and ERC_Numeric__c != NULL]){
                for(Account acc: accs){
                    ercNumericIds.add(acc.ERC_Numeric__c);
                }
            }
            for (Account acc : Trigger.new){
                Account oldAccount = Trigger.oldMap.get(acc.ID);
                if(acc.AKERC__c != null && !acc.AKERC__c.equals(' ') && (acc.AKERC__c != oldAccount.AKERC__c)){
                    String AKERCValue = acc.AKERC__c;
                    String ERCNumericValue = SupportTeamMgmt_Utility.getERCNumeric(AKERCValue);
                   if(!ercNumericIds.isEmpty() && ercNumericIds.contains(ERCNumericValue)){
                       acc.addError('ERCNumeric value is not unique, please provide a different AKERC value');
                      }
                   else{
                      ercNumericIds.add(ERCNumericValue);
                    }
                }
            }
        }
}