public class PSA_CLIProjectReportCls {
    public PSA_CLIProjectReportCls() {
      
    }
    @AuraEnabled(cacheable=true)
    public static list<CLIProjectsWrapper> getfetchResults(date enddate1, date enddate2){

    list<CLIProjectsWrapper> finalWrp =  new list<CLIProjectsWrapper>();
    Map<Id,list<PS_Approved_Hours__c>> resultWrp = new Map<Id,list<PS_Approved_Hours__c>>();
    Map<Id,PS_Overage_Hours__c> overageMap = new Map<Id,PS_Overage_Hours__c>();
    set<Id> arIdset = new set<Id>();
    Map<Id,decimal> cliUnitlowMap = new Map<Id,decimal>();
    Map<Id,string> cliIdNameMap = new Map<Id,string>();
    try{
        list<PS_Approved_Hours__c> appHrsList = [select 
                                                 	Id,Units_Low__c,Contract_Detail__r.Name,Contract_Detail__c, Account__r.name, 
            										Approved_Hours__c, Project__r.Name, Billing_Period_Start_Date__c, Billing_Period_End_Date__c, 
            										Overage_Hours__c, Project__r.pse__Project_Id__c, Project__r.pse__Stage__c, Project__r.close_code__c   
                                                 from 
                                                 	PS_Approved_Hours__c 
                                                 where 
                                                 	Contract_Detail__r.Name != null 
                                                 and (Billing_Period_End_Date__c >=: enddate1 AND Billing_Period_End_Date__c <=: enddate2) 
                                                 limit 50000];
        
        system.debug('appHrsList' + appHrsList.size());
        
        if(!appHrsList.isEmpty()){
            for(PS_Approved_Hours__c ps : appHrsList){
                arIdset.add(ps.Id);
                cliUnitlowMap.put(ps.Contract_Detail__c, ps.Units_Low__c);
                cliIdNameMap.put(ps.Contract_Detail__c,ps.Contract_Detail__r.Name);
            }
        }
        
        if(!arIdset.isEmpty()){
            for(PS_Overage_Hours__c oh : [select 
                                          	Id, Name, Overage_Hours__c, PS_Approved_Hours__c, PS_Approved_Hours__r.Units_Low__c 
                                          from 
                                          	PS_Overage_Hours__c 
                                          where 
                                          	PS_Approved_Hours__c IN:arIdset 
                                          limit 50000]){
                overageMap.put(oh.PS_Approved_Hours__c,oh);
            }
        }

        if(!appHrsList.isEmpty()){
            for(PS_Approved_Hours__c ar : appHrsList){
                if(resultWrp.containskey(ar.Contract_Detail__c)){
                    resultWrp.get(ar.Contract_Detail__c).add(ar);
                }
                else {
                    resultWrp.put(ar.Contract_Detail__c, new list<PS_Approved_Hours__c> {ar});

                }
            }
        }
        system.debug('resultWrp **'+resultWrp);
        system.debug('resultWrp **'+resultWrp.keyset().size());


        for(string s : resultWrp.keyset()){
            
            if(resultWrp.get(s).size() > 1){    
                string contrName = s;
                system.debug('mapKey **'+contrName);
                list <ApproverHoursWrapper> arrhrList = new list<ApproverHoursWrapper>();
                decimal TotalApprovedHours = 0;
                decimal TotaloverageHrs = 0;
                
                for(PS_Approved_Hours__c ps : resultWrp.get(s)){
                    Id overagerecId = null;
                    string overageName = '';
                    decimal overagerechour = 0;
                    decimal recunitLow = 0;
                    //overageHrs = 0;
                    
                    if(overageMap.containskey(ps.Id)){
                        overagerecId = overageMap.get(ps.Id).Id;
                        overageName = overageMap.get(ps.Id).Name;
                        overagerechour = overageMap.get(ps.Id).Overage_Hours__c;
                        recunitLow = overageMap.get(ps.Id).PS_Approved_Hours__r.Units_Low__c;
                    }

                    if(ps.Overage_Hours__c == null){
                        ps.Overage_Hours__c = 0;
                    }

                    TotalApprovedHours = (TotalApprovedHours + ps.Approved_Hours__c);
                    TotaloverageHrs = TotalApprovedHours - cliUnitlowMap.get(ps.Contract_Detail__c);
                    if(TotaloverageHrs < 0){
                        TotaloverageHrs = 0;
                    }
                    arrhrList.add(new ApproverHoursWrapper(ps.Account__r.name,ps.Project__r.Name,ps.Project__r.pse__Project_Id__c,ps.Project__r.pse__Stage__c,ps.Project__r.close_code__c,ps.Units_Low__c,ps.Approved_Hours__c,overagerechour,ps.Billing_Period_Start_Date__c,ps.Billing_Period_End_Date__c, overagerecId, overageName));
                }
                system.debug('mapValues **'+arrhrList);
                system.debug('mapValuesSize **'+arrhrList.size()); 
                string cliName = cliIdNameMap.get(s);
                
                finalWrp.add(new CLIProjectsWrapper(cliName, arrhrList, arrhrList.size(),TotaloverageHrs));
            }
        }
        system.debug('finalWrp ***'+finalWrp);
        return finalWrp;
        }
        catch (Exception ex){
            system.debug(ex);
            return null;
        } 
    }

    public class CLIProjectsWrapper { 
        @AuraEnabled public string contractName;
        @AuraEnabled public list <ApproverHoursWrapper> approverHoursList; 
        @AuraEnabled public integer rowSpan;  
        @AuraEnabled public decimal overageHrs; 
        
        public CLIProjectsWrapper (string contractName, list<ApproverHoursWrapper> approverHoursList, integer size, decimal overageHrs){
            this.ContractName = ContractName;
            this.ApproverHoursList = ApproverHoursList;
            this.rowSpan = size;
            this.overageHrs = overageHrs.setscale(2);
        }
    }
    
    public class ApproverHoursWrapper {
        @AuraEnabled public string AccountName;
        @AuraEnabled public string ProjectName;
        @AuraEnabled public decimal UnitsLow;
        @AuraEnabled public string ProjectID ;
        @AuraEnabled public string CloseCode;
        @AuraEnabled public string ProjectStage;
        @AuraEnabled public decimal ApprovedHours;
        @AuraEnabled public decimal OverageHours;
        @AuraEnabled public date BillingStartDate;
        @AuraEnabled public date BillingEndDate;
        @AuraEnabled public Id recId;
        @AuraEnabled public string Name;

        public ApproverHoursWrapper(string AccountName, string ProjectName,string ProjectID,string ProjectStage,string CloseCode, decimal UnitsLow, decimal ApprovedHours, decimal OverageHours, date BillingStartDate, date BillingEndDate, Id recId, string Name){
            this.AccountName = AccountName;
            this.ProjectName = ProjectName;
            this.ProjectID = ProjectID;
            this.CloseCode = CloseCode;
            this.ProjectStage = ProjectStage;
            this.UnitsLow = UnitsLow.setscale(2);
            this.ApprovedHours = ApprovedHours.setscale(2);
            this.OverageHours = OverageHours.setscale(2);
            this.BillingStartDate = BillingStartDate;
            this.BillingEndDate = BillingEndDate;
            this.recId = recId;
            this.Name = Name;
        }
    }  
}