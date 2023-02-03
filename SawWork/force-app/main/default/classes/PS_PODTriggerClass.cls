/* 
/*********************************************************************************************************************
 * JIRA             : ESESP-5250
 * Author           : Sujay Surendranath
 * Created Date     : 03-23-2022
 * Purpose          : To Handle Delivery POD Process in the system
 
 /************************************************************************************************************************
  * 
  *
*/ 

public without sharing class PS_PODTriggerClass 
{ 

    public static List<cls_WrapperForAccountAndDept> lstAccountOrAccountAndAccountDept              = new List<cls_WrapperForAccountAndDept>();
    public static List<cls_WrapperForAccountAndDept> lstAccountOrAccountAndAccountDeptWithPOD       = new List<cls_WrapperForAccountAndDept>();
    public static List<cls_WrapperForAccountAndDept> lstAccountOrAccountAndAccountDeptWithoutPOD    = new List<cls_WrapperForAccountAndDept>();
    public static List<cls_WrapperForAccountAndDept> lstAccountOrAccountAndAccountDeptAssigedtoPOD  = new List<cls_WrapperForAccountAndDept>();


    public static String status         = 'Success';
    public static String reaonForError  = '';
    public static string updatingObject = '';
    public static Integer eCounter      = 0;
    public static Integer sCounter      = 0;
    
                        

    public static void beforeInsertUpdate(Boolean isInsert, POD_Association__c[] oldPODs, POD_Association__c[] newPODs, Map<Id, POD_Association__c> oldMap, Map<Id, POD_Association__c> newMap) 
    {
        List<POD_Association__c> checkReportList = new List<POD_Association__c>();
        validateReportParams(newPODs, oldMap, isInsert); 
            
    }
    
    
    public static void validateReportParams(List<POD_Association__c> newPODs, Map<Id, POD_Association__c> oldMap, boolean isInsert)
    {
        //Map<String,String> podIdToReportId          = new Map<String,String>();

        for(POD_Association__c ePod : newPODs)
        {
            if(ePod.Report_Link__c != NULL && (isInsert || (!isInsert && ePod.Report_Link__c != oldMap.get(ePod.Id).Report_Link__c)))
            {
                String reportId = getReportID(ePod.Report_Link__c);
                if(reportId != '' && reportId.startsWith('00O'))
                {
                    ePod.ReportId__c = reportId;
                    // can not call below line as its calling report APIs - and its restrited from salesforce through triggers.
                    //podIdToReportId.put(ePod.Id, reportId);
                }
                else
                {
                    ePod.addError('Report Link provided is invalid, please check the link and update.!!');
                }
            }
            
            System.debug('ePod :: ' + ePod);  
        }

        // if(podIdToReportId != NULL && !podIdToReportId.isEmpty())
        // {
        //     // Get the report ID
        //     Map<Id, Report> reportList = new Map<Id, Report>([SELECT Id FROM Report WHERE Id =: podIdToReportId.values()]);
        //     for(POD_Association__c ePod : newPODs)
        //     {
        //         if(podIdToReportId.containsKey(ePod.Id))
        //         { 
        //             // Run a report
        //             Reports.ReportResults results = Reports.ReportManager.runReport(podIdToReportId.get(ePod.Id));
        //             Reports.ReportMetadata rm = results.getReportMetadata();
        //             System.debug('Name: ' + rm.getName());
        //             System.debug('Detail columns: ' + rm.getDetailColumns());
        //             System.debug('Report format: ' + rm.getReportFormat());
        //             System.debug('Report filters: ' + rm.getReportFilters());
        //         }

        //     }
        // }
        
    }


    public static String getReportID(String reportLink)
    {
        List<String> lstUrls    =   new List<String>();
        String reportId         =   '';

        if(UserInfo.getUiThemeDisplayed() == 'Theme3')
        {
            //classic code
            //Classic URL :  https://akamai--ffdec.my.salesforce.com/00O3K000000FpQf

            lstUrls.addAll(reportLink.split('/'));
            System.debug('lstUrls :: '+ lstUrls[3]);
            reportId   = (lstUrls.size() >= 3 &&  lstUrls[3] != NULL) ? lstUrls[3] : '';
            
        }
        else if(UserInfo.getUiThemeDisplayed() == 'Theme4d')
        {
            // LEX code
            //Lightning URL : https://akamai--ffdec.lightning.force.com/lightning/r/Report/00O3K000000FpQf/view
            lstUrls.addAll(reportLink.split('/'));
            //System.debug('lstUrls :: '+ lstUrls[6]);
            reportId   = (lstUrls.size() >= 6 && lstUrls[6] != NULL) ? lstUrls[6] : '';

        }

        return reportId;
    }

    
    @AuraEnabled(cacheable = false)
    public static cls_WrapperForLWC retrieveAccounts(String reportId, String updatingObj, String podId, String podName)
    {
        updatingObject = updatingObj;
        System.debug('reportId to load on screen :: ' + reportId);
        System.debug('updatingObject from screen :: ' + updatingObject);
        // if(reportId == null){
        //    //getReportAsWrapper('00O2D0000018oEW'); 
        // }else{
        // 	//getReportAsWrapper(reportId);    
        // }
        
        getReportAsWrapper(reportId, updatingObj, podId, podName);    
        //getReportAsWrapper('00O2D0000018oEW'); 

        cls_WrapperForLWC payloadForUI = new cls_WrapperForLWC();
        payloadForUI.statusOfAsk    = status;
        payloadForUI.errorTrace     = reaonForError;
        payloadForUI.assignedPODs   = lstAccountOrAccountAndAccountDeptWithPOD;
        payloadForUI.unAssignedPODs = lstAccountOrAccountAndAccountDeptWithoutPOD;

        payloadForUI.assignedToPODs = lstAccountOrAccountAndAccountDeptAssigedtoPOD;

        // this is to ensure the POD is successfully able to load - also make sure someone can use this POD choose at the Lookup level.
        POD_Association__c updatePod = new POD_Association__c();
        updatePod.Id = podId;
        updatePod.POD_Executed__c = payloadForUI.statusOfAsk != 'Success' ? false : true;
        updatePod.Validation_Override__c = true;

        update updatePod;

        return payloadForUI;
    }
    

    @AuraEnabled
    public static POD_Association__c getPODDetail(String podRecordId)
    {
        System.debug('podRecordId: : '+ podRecordId );
        return [SELECT Id, Name, ReportId__c, Report_link__c, Updating_Object__c, Active__c, Batch_Process__c  FROM POD_Association__c WHERE Id =:podRecordId ][0];
    }


    @AuraEnabled(cacheable = false)
    public static void getReportAsWrapper(String reportId, String updatingObj, String podId, String podName)
    {
        //Reports.ReportResults results = Reports.ReportManager.runReport('00O3K000000FpQfUAK', true);
        System.debug('reportId from component : '+ reportId);
        System.debug('updatingObj from POD Record : '+ updatingObj);
        System.debug('podId from POD Record : '+ podId);
        
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
        //JSON.serializePretty(results);

        //Use when needed to traverse over wrapperclass.
        String jsonString = JSON.serialize(results);
        fromJSON reportResponse = new fromJSON(); 
        System.debug('daaata :: ' + (fromJSON) System.JSON.deserialize(jsonString, fromJSON.class));

        reportResponse = (fromJSON) System.JSON.deserialize(jsonString, fromJSON.class);
        System.debug('reportResponse name :: ' + reportResponse.reportMetadata.name);
        System.debug('reportResponse detailColumns:: ' + reportResponse.reportMetadata.detailColumns);
        System.debug('reportResponse standardDateFilter:: ' + reportResponse.reportMetadata.standardDateFilter);
        System.debug('reportResponse reportFilters:: ' + reportResponse.reportMetadata.reportFilters); 
        System.debug('reportResponse reportBooleanFilter:: ' + reportResponse.reportMetadata.reportBooleanFilter); 

        List<String> columnsOnReport = reportResponse.reportMetadata.detailColumns;

        System.debug('columnsOnReport :: ' + columnsOnReport);
        Integer accName, accDeptAccName, accAkamId, accPod, accDeptName, accDeptPod; 
        

        for(String eStr : columnsOnReport)
        {
            System.debug('eStr ::'+ eStr + '::');
        }

        for(Integer i = 0; i < columnsOnReport.size(); i++)
        {
            switch on columnsOnReport[i] 
            {
				
                //AD report : 
                //(Account.Name, Account.POD_Association__c.Name, Account_Department__c.Name, Account.AKAM_Account_ID__c, Account_Department__c.POD_Association__c.Name)
                //Ac report : 
                //Account.AKAM_Account_ID__c, ACCOUNT.NAME, Account.TERR_HIER_1__c, USERS.NAME, INDUSTRY, EMPLOYEES, PHONE1, Account.POD_Association__c
                
                
                when 'Account.AKAM_Account_ID__c'{
                    accAkamId = i;
                }
                //for Account column
                when 'ACCOUNT.NAME'{
                    accName = i;
                }             
                when 'Account.POD_Association__c' {
                    accPod = i;
                }
                when 'Account.Name' {
                    accDeptAccName = i;
                }
                when 'Account.POD_Association__c.Name'{
                    accPod = i;
                }
                when 'Account_Department__c.Name' {
                    accDeptName = i;
                }
                when 'Account_Department__c.POD_Association__c.Name' {
                    accDeptPod = i;
                }
                when else {
                    System.debug('No Entry for this one');
                }
            }
        }


        
        Integer overallRows = 0;
        String akamAccountIDs = 'F-AC';
        List<String> lakamAccountIDs = new List<String>();
        Reports.ReportFactWithDetails factWithDetails = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');

        for(Reports.SummaryValue val : factWithDetails.getAggregates())
        {
            // System.debug('getAggregates :: ' +  val.getLabel()); 
            // System.debug('getAggregates :: ' +  val.getValue()); 
            overallRows = integer.valueOf(val.getValue());
        }

        //Reports.ReportResults firstResults = Reports.ReportManager.runReport(reportId, true);
        // Reports.ReportFactWithDetails firstfactWithDetails = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
        // for (Reports.ReportDetailRow row : firstfactWithDetails.getRows()) 
        // {
        //     System.debug('row :: ' +  row);
        //     System.debug('individual column data :: ' + row.getDataCells()[0]);
            
        //     for (Reports.ReportDataCell cell : row.getDataCells()) 
        //     {
        //         // System.debug('cell :: ' +  cell);
        //         // //System.debug('The cell data:: ' + cell.getLabel());
        //         // System.debug('The cell data:: ' + cell.getValue());
        //         if(cell.getValue() != null && (string.valueOf(cell.getValue()).startsWith('F-AC') || string.valueOf(cell.getValue()).startsWith('1-') || string.valueOf(cell.getValue()).startsWith('AANA-')) )
        //         {
        //             akamAccountIDs += + ',' + string.valueOf(cell.getValue()) ;
        //             lakamAccountIDs.add(string.valueOf(cell.getValue()));
        //         }
        //     }

        // }  




        System.debug('akamAccountIDs :: ' + akamAccountIDs);

        // if(overallRows > 2000)
        // {
        //     for(Integer i = 0; i <= overallRows;)
        //     {
        //         i += 2000;
                
        //         Reports.ReportResults nextResults = Reports.ReportManager.runReport(reportId,true);
        //         // pars the result to recive the first 2000 ids.
        //         Reports.ReportFilter RF = new Reports.ReportFilter('Account.AKAM_Account_ID__c', 'notEqual', akamAccountIDs);
        //         Reports.ReportMetadata RM = nextResults.getReportMetadata();
        //         list<Reports.ReportFilter>allfilters = new list<Reports.ReportFilter> {RF};
        //         allfilters.addAll(RM.getReportFilters());
        //         RM.setReportFilters(allfilters);
        //         nextResults = Reports.ReportManager.runReport(reportId, RM,true);

        //         Reports.ReportFactWithDetails nextfactWithDetails = (Reports.ReportFactWithDetails) nextResults.getFactMap().get('T!T');
        //         for (Reports.ReportDetailRow row : nextfactWithDetails.getRows()) 
        //         {
        //             // System.debug('row :: ' +  row);
        //             // System.debug('individual column data :: ' + row.getDataCells()[0]);
        //             for (Reports.ReportDataCell cell : row.getDataCells()) 
        //             {
        //                 // System.debug('cell :: ' +  cell);
        //                 // //System.debug('The cell data:: ' + cell.getLabel());
        //                 // System.debug('The cell data:: ' + cell.getValue());
        //                 if(cell.getValue() != null && (string.valueOf(cell.getValue()).startsWith('F-AC') || string.valueOf(cell.getValue()).startsWith('1-') || string.valueOf(cell.getValue()).startsWith('AANA-')))
        //                 {
        //                     akamAccountIDs += ',' + string.valueOf(cell.getValue()) ;
        //                     lakamAccountIDs.add(string.valueOf(cell.getValue()));
        //                 }
        //             }
        //         }  

        //     }

        // }

        
        if(reportResponse.reportMetadata.reportFormat == 'TABULAR')
        {
            System.debug('Report is a Tabular report');
            

            if(reportResponse.reportMetadata.reportType.type == 'Accounts_with_Account_Departments__c' || reportResponse.reportMetadata.reportType.type == 'AccountList')
            {
				Map<String, cls_WrapperForAccountAndDept> accOrDepTOWrapper = new Map<String,cls_WrapperForAccountAndDept>();
                System.debug(' reportResponse.reportMetadata.reportType.type ::' + reportResponse.reportMetadata.reportType.type);
                if(reportResponse.reportMetadata.reportType.type == 'Accounts_with_Account_Departments__c' )
                {

                    if(updatingObj.equalsIgnoreCase('Account'))
                    {
                        if(columnsOnReport.contains('Account.AKAM_Account_ID__c') && columnsOnReport.contains('Account.Name') && columnsOnReport.contains('Account.POD_Association__c.Name'))
                        {
                            
                            Reports.ReportFactWithDetails firstfactWithDetails = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
                            for (Reports.ReportDetailRow row : firstfactWithDetails.getRows()) 
                            {
                                //System.debug('row :: ' +  row);
                                System.debug(accName );
                                System.debug(accAkamId );
                                System.debug(accPod );
                                System.debug(accDeptName );
                                System.debug(accDeptPod );
                                System.debug('individual column data :: accName :: ' + row.getDataCells()[0]);
                                System.debug('individual column data :: accName :: ' + row.getDataCells()[accDeptAccName]);
                                System.debug('individual column data ::  accAkamId :: ' + row.getDataCells()[accAkamId]);
                                //System.debug('individual column data :: accPod :: ' + row.getDataCells()[accPod]);
                                System.debug('individual column data :: accDeptName :: ' + row.getDataCells()[accDeptName]);
                                System.debug('individual column data :: accDeptPod :: ' + row.getDataCells()[accDeptPod]);
    
                                cls_WrapperForAccountAndDept wrapAccount = new cls_WrapperForAccountAndDept();
    
                                wrapAccount.accountName = String.valueOf(row.getDataCells()[accDeptAccName].getLabel());
                                wrapAccount.accountId = String.valueOf(row.getDataCells()[accDeptAccName].getValue());
    
                                wrapAccount.akamAccount = String.valueOf(row.getDataCells()[accAkamId].getLabel());
                                wrapAccount.akamAccountId = String.valueOf(row.getDataCells()[accAkamId].getValue());
    
                                wrapAccount.accPod = String.valueOf(row.getDataCells()[accPod].getLabel());
                                wrapAccount.accPodId = String.valueOf(row.getDataCells()[accPod].getValue());
                                
                                
                                //wrapAccount.accDeptPod = String.valueOf(row.getDataCells()[accDeptPod].getLabel());
                                //wrapAccount.accDeptPodId = String.valueOf(row.getDataCells()[accDeptPod].getValue());
    
                                //wrapAccount.accDeptName = String.valueOf(row.getDataCells()[accDeptName].getLabel());
                                //wrapAccount.accDeptId = String.valueOf(row.getDataCells()[accDeptName].getValue());
                                
                                
                                
                                wrapAccount.updateObj 			= updatingObject;
                                
                                wrapAccount.accountLink     	= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accDeptAccName].getValue());
                                wrapAccount.podLink         	= String.valueOf(row.getDataCells()[accPod].getValue()) != 'null' ? String.valueOf(URL.getSalesforceBaseUrl().toExternalForm())+ '/' + String.valueOf(row.getDataCells()[accPod].getValue()) : ''; 

                                wrapAccount.akamAccountIdLink 	= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accDeptAccName].getValue()); 
                                
								//wrapAccount.accDeptPodLink      = String.valueOf(row.getDataCells()[accDeptPod].getValue()) != 'null' ? String.valueOf(URL.getSalesforceBaseUrl().toExternalForm())+ '/' + String.valueOf(row.getDataCells()[accDeptPod].getValue()) : ''; 
                                //wrapAccount.accDeptLink			= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accDeptName].getValue());
                                
                                lstAccountOrAccountAndAccountDept.add(wrapAccount);
                                
                                if(! accOrDepTOWrapper.containsKey(wrapAccount.akamAccountId))
                                {
                                    accOrDepTOWrapper.put(wrapAccount.akamAccountId, wrapAccount);
                                    
                                    if(wrapAccount.accPod != '-')
                                    {
                                        lstAccountOrAccountAndAccountDeptWithPOD.add(wrapAccount);
                                    }
                                    else
                                    {
                                        lstAccountOrAccountAndAccountDeptWithoutPOD.add(wrapAccount);
                                    }

                                    if(wrapAccount.accPod  == podName){
                                        lstAccountOrAccountAndAccountDeptAssigedtoPOD.add(wrapAccount); 
                                    }
                                }
    
                                
    
                            }
                            
                            System.debug('lstAccountOrAccountAndAccountDept :: '+ lstAccountOrAccountAndAccountDept);
                            System.debug('lstAccountOrAccountAndAccountDept :: '+ lstAccountOrAccountAndAccountDept.size());

                                                        
                        }
                        else
                        {
                            status = 'Failure';
                            reaonForError = 'Mandatory columns not found on the Report for Account and Account Dept Type (Account Name, Akam Accont ID, Account POD)';
                            System.debug('Mandatory columns not found on the Report for Account and Account Dept Type (Account Name, Akam Account ID, Account POD)');	
                        }
                    }
                    else if(updatingObj.equalsIgnoreCase('Account & Account Dept'))
                    {
                        if(columnsOnReport.contains('Account.AKAM_Account_ID__c') && columnsOnReport.contains('Account.Name') && columnsOnReport.contains('Account.POD_Association__c.Name') && columnsOnReport.contains('Account_Department__c.Name') && columnsOnReport.contains('Account_Department__c.POD_Association__c.Name'))
                        {
                            Reports.ReportFactWithDetails firstfactWithDetails = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
                            for (Reports.ReportDetailRow row : firstfactWithDetails.getRows()) 
                            {
                                //System.debug('row :: ' +  row);
                                System.debug(accName );
                                System.debug(accAkamId );
                                System.debug(accPod );
                                System.debug(accDeptName );
                                System.debug(accDeptPod );
                                System.debug('individual column data :: accName :: ' + row.getDataCells()[0]);
                                System.debug('individual column data :: accName :: ' + row.getDataCells()[accDeptAccName]);
                                System.debug('individual column data ::  accAkamId :: ' + row.getDataCells()[accAkamId]);
                                //System.debug('individual column data :: accPod :: ' + row.getDataCells()[accPod]);
                                System.debug('individual column data :: accDeptName :: ' + row.getDataCells()[accDeptName]);
                                System.debug('individual column data :: accDeptPod :: ' + row.getDataCells()[accDeptPod]);
    
                                cls_WrapperForAccountAndDept wrapAccount = new cls_WrapperForAccountAndDept();
    
                                wrapAccount.accountName = String.valueOf(row.getDataCells()[accDeptAccName].getLabel());
                                wrapAccount.accountId = String.valueOf(row.getDataCells()[accDeptAccName].getValue());
    
                                wrapAccount.akamAccount = String.valueOf(row.getDataCells()[accAkamId].getLabel());
                                wrapAccount.akamAccountId = String.valueOf(row.getDataCells()[accAkamId].getValue());
    
                                wrapAccount.accPod = String.valueOf(row.getDataCells()[accPod].getLabel());
                                wrapAccount.accPodId = String.valueOf(row.getDataCells()[accPod].getValue());
                                
                                
                                wrapAccount.accDeptPod = String.valueOf(row.getDataCells()[accDeptPod].getLabel());
                                wrapAccount.accDeptPodId = String.valueOf(row.getDataCells()[accDeptPod].getValue());
    
                                wrapAccount.accDeptName = String.valueOf(row.getDataCells()[accDeptName].getLabel());
                                wrapAccount.accDeptId = String.valueOf(row.getDataCells()[accDeptName].getValue());
                                
                                
                                
                                wrapAccount.updateObj 			= updatingObject;
                                
                                wrapAccount.accountLink     	= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accDeptAccName].getValue());
                                wrapAccount.podLink         	= String.valueOf(row.getDataCells()[accPod].getValue()) != 'null' ? String.valueOf(URL.getSalesforceBaseUrl().toExternalForm())+ '/' + String.valueOf(row.getDataCells()[accPod].getValue()) : ''; 

                                wrapAccount.akamAccountIdLink 	= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accDeptAccName].getValue()); 
                                
								wrapAccount.accDeptPodLink      = String.valueOf(row.getDataCells()[accDeptPod].getValue()) != 'null' ? String.valueOf(URL.getSalesforceBaseUrl().toExternalForm())+ '/' + String.valueOf(row.getDataCells()[accDeptPod].getValue()) : ''; 
                                wrapAccount.accDeptLink			= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accDeptName].getValue());
                                wrapAccount.isSelected          = false;
                                
                                lstAccountOrAccountAndAccountDept.add(wrapAccount);
    
                                if(wrapAccount.accDeptPod != '-' && wrapAccount.accPod != '-')
                                {
                                    lstAccountOrAccountAndAccountDeptWithPOD.add(wrapAccount);
                                }
                                else
                                {
                                    lstAccountOrAccountAndAccountDeptWithoutPOD.add(wrapAccount);
                                }

                                if(wrapAccount.accPod  == podName && wrapAccount.accDeptPod  == podName)
                                {
                                    lstAccountOrAccountAndAccountDeptAssigedtoPOD.add(wrapAccount); 
                                }
    
                            }
                            
                            System.debug('lstAccountOrAccountAndAccountDept :: '+ lstAccountOrAccountAndAccountDept);
                            System.debug('lstAccountOrAccountAndAccountDept :: '+ lstAccountOrAccountAndAccountDept.size());

                            
                        }
                        else
                        {
                            status = 'Failure';
                            reaonForError = 'Mandatory columns not found on the Report for Account and Account Dept Type (Account Name, Akam Account ID, Account POD.)';
                            System.debug('Mandatory columns not found on the Report for Account and Account Dept Type (Account Name, Akam Account ID, Account POD.)');	
                        }
                        
                    }
                    else if(updatingObj.equalsIgnoreCase('Account Dept'))
                    {
                        
                        if(columnsOnReport.contains('Account.Name') && columnsOnReport.contains('Account_Department__c.Name') && columnsOnReport.contains('Account_Department__c.POD_Association__c.Name'))
                        {
                           Reports.ReportFactWithDetails firstfactWithDetails = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
						   for (Reports.ReportDetailRow row : firstfactWithDetails.getRows()) 
                            {
                                //System.debug('row :: ' +  row);
                                System.debug(accName );
                                System.debug(accAkamId );
                                System.debug(accPod );
                                System.debug(accDeptName );
                                System.debug(accDeptPod );
                                System.debug('individual column data :: accName :: ' + row.getDataCells()[0]);
                                System.debug('individual column data :: accName :: ' + row.getDataCells()[accDeptAccName]);
                                //System.debug('individual column data ::  accAkamId :: ' + row.getDataCells()[accAkamId]);
                                //System.debug('individual column data :: accPod :: ' + row.getDataCells()[accPod]);
                                System.debug('individual column data :: accDeptName :: ' + row.getDataCells()[accDeptName]);
                                System.debug('individual column data :: accDeptPod :: ' + row.getDataCells()[accDeptPod]);
    
                                cls_WrapperForAccountAndDept wrapAccount = new cls_WrapperForAccountAndDept();
    
                                wrapAccount.accountName = String.valueOf(row.getDataCells()[accDeptAccName].getLabel());
                                wrapAccount.accountId = String.valueOf(row.getDataCells()[accDeptAccName].getValue());
    
                                //wrapAccount.akamAccount = String.valueOf(row.getDataCells()[accAkamId].getLabel());
                                //wrapAccount.akamAccountId = String.valueOf(row.getDataCells()[accAkamId].getValue());
    
                                //wrapAccount.accPod = String.valueOf(row.getDataCells()[accPod].getLabel());
                                //wrapAccount.accPodId = String.valueOf(row.getDataCells()[accPod].getValue());
                                
                                
                                wrapAccount.accDeptPod = String.valueOf(row.getDataCells()[accDeptPod].getLabel());
                                wrapAccount.accDeptPodId = String.valueOf(row.getDataCells()[accDeptPod].getValue());
    
                                wrapAccount.accDeptName = String.valueOf(row.getDataCells()[accDeptName].getLabel());
                                wrapAccount.accDeptId = String.valueOf(row.getDataCells()[accDeptName].getValue());
                                
                                
                                
                                wrapAccount.updateObj 			= updatingObject;
                                
                                wrapAccount.accountLink     	= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accDeptAccName].getValue());
                               // wrapAccount.podLink         	= String.valueOf(row.getDataCells()[accPod].getValue()) != 'null' ? String.valueOf(URL.getSalesforceBaseUrl().toExternalForm())+ '/' + String.valueOf(row.getDataCells()[accPod].getValue()) : ''; 

                                //wrapAccount.akamAccountIdLink 	= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accDeptAccName].getValue()); 
                                
								wrapAccount.accDeptPodLink      = String.valueOf(row.getDataCells()[accDeptPod].getValue()) != 'null' ? String.valueOf(URL.getSalesforceBaseUrl().toExternalForm())+ '/' + String.valueOf(row.getDataCells()[accDeptPod].getValue()) : ''; 
                                wrapAccount.accDeptLink			= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accDeptName].getValue());
                                wrapAccount.isSelected          = false;
                                
                                lstAccountOrAccountAndAccountDept.add(wrapAccount);
                                
                                if(! accOrDepTOWrapper.containsKey(wrapAccount.accDeptId))
                                {
                                    accOrDepTOWrapper.put(wrapAccount.accDeptId, wrapAccount);
                                    
                                    if(wrapAccount.accDeptPod != '-')
                                    {
                                        lstAccountOrAccountAndAccountDeptWithPOD.add(wrapAccount);
                                    }
                                    else
                                    {
                                        lstAccountOrAccountAndAccountDeptWithoutPOD.add(wrapAccount);
                                    }

                                    if(wrapAccount.accDeptPod  == podName)
                                    {
                                        lstAccountOrAccountAndAccountDeptAssigedtoPOD.add(wrapAccount); 
                                    }
                                }
    
                            }
                            
                            System.debug('lstAccountOrAccountAndAccountDept :: '+ lstAccountOrAccountAndAccountDept);
                            System.debug('lstAccountOrAccountAndAccountDept :: '+ lstAccountOrAccountAndAccountDept.size()); 
                        }
                        else
                        {
                            status = 'Failure';
                            reaonForError = 'Mandatory columns not found on the Report for Account and Account Dept Type (Account Name, Akam Accont ID, Account POD)';
                            System.debug('Mandatory columns not found on the Report for Account and Account Dept Type (Account Name, Akam Dept, Dept POD Association)');	

                            System.debug('columnsOnReport :: ' +columnsOnReport );
                        }
                    }
                    else
                    {
                        status = 'Failure';
                        reaonForError = 'The Updating Object Type is not supported to load the report';
                        System.debug('The Updating Object Type is not supported to load the report');	
                    }

                }
                

                System.debug('check condition :: ' + reportResponse.reportMetadata.reportType.type + ' :: ' +(columnsOnReport.contains('Account.AKAM_Account_ID__c') && columnsOnReport.contains('ACCOUNT.NAME') && columnsOnReport.contains('Account.POD_Association__c')) );
                if(reportResponse.reportMetadata.reportType.type == 'AccountList' )
                {
                    
                    if(updatingObj.equalsIgnoreCase('Account'))
                    {
                        if((columnsOnReport.contains('Account.AKAM_Account_ID__c') && columnsOnReport.contains('ACCOUNT.NAME') && columnsOnReport.contains('Account.POD_Association__c')))
                    	{
                            //accName, accAkamId, accPod, accDeptName, accDeptPod; 
                            System.debug('Valid Report Type for Account and Account Dept');
    
                            Reports.ReportFactWithDetails firstfactWithDetails = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
                            for (Reports.ReportDetailRow row : firstfactWithDetails.getRows()) 
                            {
                                //System.debug('row :: ' +  row);
                                System.debug(accName );
                                System.debug(accAkamId );
                                System.debug(accPod );
                                System.debug('individual column data :: accName :: ' + row.getDataCells()[0]);
                                System.debug('individual column data :: accName :: ' + row.getDataCells()[accName]);
                                System.debug('individual column data ::  accAkamId :: ' + row.getDataCells()[accAkamId]);
                                System.debug('individual column data :: accPod :: ' + row.getDataCells()[accPod]);
    
    
                                cls_WrapperForAccountAndDept wrapAccount = new cls_WrapperForAccountAndDept();
    
                                wrapAccount.accountName 		= String.valueOf(row.getDataCells()[accName].getLabel());
                                wrapAccount.accountId 			= String.valueOf(row.getDataCells()[accName].getValue());
    
                                wrapAccount.akamAccount 		= String.valueOf(row.getDataCells()[accAkamId].getLabel());
                                wrapAccount.akamAccountId 		= String.valueOf(row.getDataCells()[accAkamId].getValue());
    
                                wrapAccount.accPod 				= String.valueOf(row.getDataCells()[accPod].getLabel());
                                wrapAccount.accPodId 			= String.valueOf(row.getDataCells()[accPod].getValue());
                                
                                wrapAccount.updateObj 			= updatingObject;
                                
                                wrapAccount.accountLink     	= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accName].getValue());
                                
                                wrapAccount.podLink         	= String.valueOf(row.getDataCells()[accPod].getValue()) != 'null' ? String.valueOf(URL.getSalesforceBaseUrl().toExternalForm())+ '/' + String.valueOf(row.getDataCells()[accPod].getValue()) : ''; 
                                wrapAccount.akamAccountIdLink 	= String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()) + '/' + String.valueOf(row.getDataCells()[accName].getValue()); 

                                wrapAccount.isSelected          = false;
    
    
                                lstAccountOrAccountAndAccountDept.add(wrapAccount);
    
                                
    
                                if(wrapAccount.accPod != '-')
                                {
                                    lstAccountOrAccountAndAccountDeptWithPOD.add(wrapAccount);
                                }
                                else
                                {
                                    lstAccountOrAccountAndAccountDeptWithoutPOD.add(wrapAccount);
                                }

                                if(wrapAccount.accPod  == podName)
                                {
                                    lstAccountOrAccountAndAccountDeptAssigedtoPOD.add(wrapAccount); 
                                }
    
                            }
    
                            System.debug('lstAccountOrAccountAndAccountDept :: '+ lstAccountOrAccountAndAccountDept);
                            System.debug('lstAccountOrAccountAndAccountDept :: '+ lstAccountOrAccountAndAccountDept.size());

                    	}
                    	else
                    	{
                            status = 'Failure';
                            reaonForError = 'Mandatory columns not found on the Report for Account Type (Akam Account Id, Account Name, POD)';
                            System.debug('Mandatory columns not found on the Report for Account Type (Akam Account Id, Account Name, POD)');
                    	}
                        
                    }
                    else if(updatingObj.equalsIgnoreCase('Account Dept') || updatingObj.equalsIgnoreCase('Account & Account Dept'))
                    {
                        status = 'Failure';
                        reaonForError = 'Cant load report as updating object is invalid to Reprt Type linked in the POD details';
                        System.debug('Cant load report as updating object is invalid to Reprt Type linked in the POD details');
                    }
                    else 
                    {
                        status = 'Failure';
                        reaonForError = 'Cant load report as Updating Object is not supported';
                        System.debug('Cant load report as Updating Object is not supported');
                    }
                }                
            }
            else 
            {
                status = 'Failure';
                reaonForError = 'Report linked to POD is not supported for the POD View';
                System.debug('Report linked to POD is not supported for the POD View');
            }

        }
        else
        {
            status = 'Failure';
            reaonForError = 'Reports must be in Tabular format';
            System.debug('Reports must be in Tabular format');
        }

        

        

        
        System.debug('reportResponse detailColumns:: ' + reportResponse.reportMetadata.detailColumns);

        System.debug('akamAccountIDs last :: ' + akamAccountIDs);
        System.debug('lakamAccountIDs last :: ' + lakamAccountIDs.size());

        System.debug('Account fetched ::: ' + [select count(Id) from Account where Akam_Account_Id__c in: lakamAccountIDs]);
        
    }

    @AuraEnabled
    public static String assignPODstoAccOrAccDeptRecords(List<String> Ids , String objName, String podId, String podName)
    {
        Set<String> accOrDepIdds = new Set<String>(Ids);
        String resOverUpdateAccounts = '';
        String resOverUpdateAccountDept = '';

        if(accOrDepIdds.size() > (Integer.valueOf([select Value__c from PSA_Common_Setting__mdt where type__c = 'POD Execute Limit' and DeveloperName = 'POD_Execute_Limit' limit 1 ].value__c)) )
        {
            System.debug('accOrDepIdds for batch class :: ' + accOrDepIdds);
            System.debug('podId for batch class :: ' + podId);

            POD_Association__c lockPod = new POD_Association__c();
            lockPod.Id = podId;
            lockPod.Batch_Process__c = true;
            update lockPod;

            ps_PODAssignmentBatch bacthAssignmentForPOD = new ps_PODAssignmentBatch();
            bacthAssignmentForPOD.accOrDepIds = accOrDepIdds;
            bacthAssignmentForPOD.podRecordId = podId;       

            Database.executeBatch(bacthAssignmentForPOD); 

            return 'Please wait for the email to see success/failures over POD Assignment, a Batch Process is initiated for the same.';
        }
        else
        {
            System.debug('Ids ::: ' +  accOrDepIdds.size());
            System.debug('objName :: ' +  objName);
            System.debug('podId  ::: ' +  podId);
            
            List<Account> 					assignPODsForAcc = new List<Account>();
            List<Account_Department__c> assignPODsForAccDept = new List<Account_Department__c>();
            
            if(objName == 'Account')
            {
                for(Account eAcc : [SELECT Id, POD_Association__c from Account where Id In: accOrDepIdds])
                {
                    Account acc = new Account();
                    acc.POD_Association__c = podId;
                    acc.Id = eAcc.Id;
                    //acc.Name = eAcc.Name;
                    assignPODsForAcc.add(acc);
                    System.debug(acc);
                }
            }
            else if(objName == 'Account Dept') 
            {
                for(Account_Department__c eAccDept : [SELECT Id, POD_Association__c from Account_Department__c where Id In: accOrDepIdds])
                {
                    eAccDept.POD_Association__c = podId;
                    assignPODsForAccDept.add(eAccDept);
                    System.debug(eAccDept);
                }
            }
            else if(objName == 'Account & Account Dept')
            {
                Set<String> accountIds = new Set<String>();
                for(Account_Department__c  eAccDept : [SELECT Id,POD_Association__c, Account_Name__r.POD_Association__c, Account_Name__c, Account_Name__r.AKAM_Account_ID__c  from Account_Department__c  where Id In: accOrDepIdds])
                {
                    eAccDept.POD_Association__c = podId;
                    assignPODsForAccDept.add(eAccDept);
                    System.debug(eAccDept);

                    if(! accountIds.contains(eAccDept.Account_Name__c))
                    {
                        assignPODsForAcc.add(new Account(Id = eAccDept.Account_Name__c, POD_Association__c = podId));
                        accountIds.add(eAccDept.Account_Name__c);
                    }
                }
            }
            else 
            {
                System.debug('objName is out of scope' + objName);
            }
            
            List<sObject> mergeLists = new List<sObject>();

            if(!assignPODsForAcc.isEmpty() )
            {
                // System.debug('assignPODsForAcc :: ' + assignPODsForAcc);
                // Database.SaveResult[] saveResults = Database.update(assignPODsForAcc, false);
                mergeLists.addAll(assignPODsForAcc);
                // populateErrorTableForUpdate(saveResults, assignPODsForAcc, podName, podId);
                
                // if(eCounter > 0)
                // {
                //     resOverUpdateAccounts = 'Success records : ' + sCounter + ' , Failed records : ' + eCounter + ', reason for Failed records is sent over an email' ;
                    
                // }
                // else
                // {
                //     resOverUpdateAccounts = resOverUpdateAccounts = 'Success records : ' + sCounter ;
                // }


            }

            if(!assignPODsForAccDept.isEmpty())
            {
                mergeLists.addAll(assignPODsForAccDept);
                // eCounter = 0;
                // sCounter = 0;
                
                // Database.SaveResult[] saveResults = Database.update(assignPODsForAccDept, false);
                // populateErrorTableForUpdate(saveResults, assignPODsForAccDept, podName, podId);

                // if(eCounter > 0)
                // {
                //     resOverUpdateAccountDept = 'Success records : ' + sCounter + ' , Failed records : ' + eCounter + ', reason for Failed records is sent over an email' ;
                    
                // }
                // else
                // {
                //     resOverUpdateAccountDept = resOverUpdateAccountDept = 'Success records : ' + sCounter ;
                // }

            }

            Database.SaveResult[] saveResults = Database.update(mergeLists, false);
            populateErrorTableForUpdate(saveResults, mergeLists, podName, podId);

            if(eCounter > 0)
            {
                resOverUpdateAccountDept = 'Success records : ' + sCounter + ' , Failed records : ' + eCounter + ', reason for Failed records is sent over an email' ;
                
            }
            else
            {
                resOverUpdateAccountDept = 'Success records : ' + sCounter ;
            }



        }
        
        //return resOverUpdateAccounts + ' ' + resOverUpdateAccountDept;
        return resOverUpdateAccountDept;

    }


    public static void PopulateErrorTableForUpdate(List<Database.SaveResult> results,List<SObject> objectLists, String podName, String podId)
    {
        String Errors = '';            
        String Table = ''; 
        String Subject = 'POD: ('+ podName + ') Update Successfull';

        for(Integer i = 0; results != null && objectLists != null &&  i < results.size(); i++)
        {
            
          Database.SaveResult sr = results.get(i);
            if (!sr.isSuccess()) 
            {
                eCounter ++;
                for(Database.Error err : sr.getErrors()) 
                {
                    System.debug('i in failure count :: ' + i );
                    System.debug('objectLists.get(i).id :: ' + objectLists.get(i).id);
                    System.debug('objectLists.get(i) :: ' + objectLists.get(i));
                    Errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ '<a href="https://' + URL.getSalesforceBaseUrl().getHost() + '/' + objectLists.get(i).id + '">' + objectLists.get(i).id + '</a>' + '</td></tr>';
                }
            }
            else
            {
                sCounter++;
            }

        }
        if(Errors != '')
        {
          
          Table += '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + UserInfo.getName() +',<br/><br/> ' + ' Errors are noticed over POD Execution for '+ eCounter+ ' records <br/><br/>'+ 'Successful records were ' + sCounter +' records. <br/><br/> Please review the POD and its Errors ' + '<br/><br/>';
          Table += 'View POD : <a href="https://' + URL.getSalesforceBaseUrl().getHost() + '/' + podId + '">' + podName + '</a><br/><br/>'   ;
          Table += '<table><tr><th>' + 'The error in Record </th>' + '<th> The Record ID </th></tr>';
          Table += Errors;
          Table += '</table><br/><br/>';  
          Subject = 'POD: ('+ podName + ') Update Failed while assigning POD' + '';
          sendErrorMails(Subject ,Table);
        }
        else // on success 
        {
            Table = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + UserInfo.getName() +',<br/><br/> ' + 'POD Execution is Successfull on Assigning POD to ' + sCounter + ' records, please review the POD for anything' + '<br/><br/>';
            Table += 'View POD : <a href="https://' + URL.getSalesforceBaseUrl().getHost() + '/' + podId + '">' + podName + '</a><br/><br/>' ;
            sendErrorMails(Subject ,Table);

        }

        
    }


    //This takes in the subject and the error message string: sends a mail to the engg team
    public static void sendErrorMails(String Subject, String SuccessOrError)
    {
        System.debug('Host: ' + URL.getSalesforceBaseUrl().getHost()); 

        PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
        String emailAddress = EnggEmail != null ? UserInfo.getUserEmail(): 'services-engg@akamai.com';

        String Body = '';

        if(SuccessOrError == '')
        {
            return;
        }
        Body += SuccessOrError;
        Body += 'Thanks,<br/>GSS Services Team</body></html>';
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail;
        objEmail = new Messaging.Singleemailmessage();
        objEmail.setReplyTo('noreply@akamai.com');
        objEmail.setToAddresses(new list<String>{emailAddress});            
        objEmail.setSubject(Subject);
        objEmail.setHTMLBody( Body );
        mailsToBeSent.add(objEmail);
        Messaging.sendEmail(mailsToBeSent,false);

    }

    
    
    class fromJSON
    {
        public cls_reportMetadata reportMetadata;
    }

    class cls_reportMetadata 
    {
		public cls_standardDateFilter standardDateFilter;
		public cls_reportType reportType;
		public String reportFormat;	//TABULAR
		public cls_reportFilters[] reportFilters;
		public String name;	//POD EMEA Accounts
		public String id;	//00O2D0000018oEWUAY
        public String reportBooleanFilter;
		
		public boolean hasRecordCount;
		public boolean hasDetailRows;
		public String developerName;	//POD_EMEA_Accounts
		public String[] detailColumns;
	}
    
    class cls_standardDateFilter 
    {
		public String startDate;	//2022-01-01
		public String endDate;	//2022-12-31
		public String durationValue;	//THIS_FISCAL_YEAR
		public String column;	//TERR2_LAST_UPDATE
	}

    class cls_reportFilters 
    {
		public String value;	//EMEA
		public String operator;	//equals
		public String filterType;	//fieldValue
		public String column;	//Account.TERR_HIER_1__c
	}

    class cls_reportType 
    {
		public String type;	//AccountList
		public String label;	//Accounts
	}

    class cls_detailColumns 
    {
		public String columnName;
    }



    class cls_WrapperForAccountAndDept
    {

        //Integer accName, accDeptAccName, accAkamId, accPod, accDeptName, accDeptPod; 

        //for Account Fields 
        @AuraEnabled public string accountName;
        @AuraEnabled public string accountId;
        @AuraEnabled public string akamAccount;
        @AuraEnabled public string akamAccountId;        
        @AuraEnabled public string accPod;
        @AuraEnabled public string accPodId;
        
        
        
        @AuraEnabled public string accDeptName;
        @AuraEnabled public string accDeptId;
        @AuraEnabled public string accDeptPod;
        @AuraEnabled public string accDeptPodId;
        
        //for Account Department Account Fields 
        @AuraEnabled public string adAccPod;
        @AuraEnabled public string adAccPodId;
        
        
        @AuraEnabled public string updateObj;
        
        @AuraEnabled public string accountLink;
        @AuraEnabled public string podLink;
        @AuraEnabled public string akamAccountIdLink;
        
        @AuraEnabled public string accDeptLink;
        @AuraEnabled public string accDeptPodLink;

        @AuraEnabled public boolean isSelected; 


    }


    class cls_WrapperForLWC
    {
        @AuraEnabled public String statusOfAsk;
        @AuraEnabled public String errorTrace;
        @AuraEnabled public List<cls_WrapperForAccountAndDept> assignedPODs;
        @AuraEnabled public List<cls_WrapperForAccountAndDept> unAssignedPODs;
        @AuraEnabled public List<cls_WrapperForAccountAndDept> assignedToPODs;

    }
    
}