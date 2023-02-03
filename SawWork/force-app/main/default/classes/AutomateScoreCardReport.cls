// File added as part of SFDC-2201 by Mayank Bansal
  public class AutomateScoreCardReport {

              public static List<Order_Approval_Reports_Metadata__mdt> reports_MetaData;

              public void fetchrecords(){

                AutomateScoreCardReport ascr = new AutomateScoreCardReport();

                    Map<String, AutomateScoreCardReportWrapper> mapOfAutomateScoreCardReportWrapper = new Map<String, AutomateScoreCardReportWrapper>();

                    Map<String, String> mapOfTaskIDAndOAID = new Map<String, String>();

                  reports_MetaData = [SELECT DeveloperName, MasterLabel, Distribution_List__c, Columns_Name__c, Filters__c, Start_Date__c, End_Date__c, Date_Range_Field_API__c, Date_Range__c, Related_Object_Name__c, Related_Object_Fields__c FROM Order_Approval_Reports_Metadata__mdt];
                  
                  String objectName = 'Task';
                  for(Order_Approval_Reports_Metadata__mdt report: reports_MetaData){
                      //Clear existing data
                      mapOfAutomateScoreCardReportWrapper.clear();
                      mapOfTaskIDAndOAID.clear();

                      String dateRangeCond = null;
                      String sql = null;
                      // Logic for task object
                      dateRangeCond = ascr.dateRangeCondCreation(report.Date_Range_Field_API__c, objectName, report.Date_Range__c, report.Start_Date__c, report.End_Date__c);
                      String columnStr = ascr.createColumnStrFromFieldAndSeq(report.Columns_Name__c);

                    if(dateRangeCond != null){
                          sql = 'Select ' + columnStr + ' from ' + objectName + ' where (' + report.Filters__c + ') and (' + dateRangeCond + ')';
                      } else {
                          sql = 'Select ' + columnStr + ' from ' + objectName + ' where ' + report.Filters__c;
                      }
                    
                    
                        List<Task> sobj = Database.query(sql);

                        for(Task taskObj : sobj){
                            AutomateScoreCardReportWrapper ascrw = mapOfAutomateScoreCardReportWrapper.get(taskObj.id);
                            mapOfTaskIDAndOAID.put(taskObj.id, taskObj.WhatId);
                            ascrw = ascr.updateAutomateScoreCardReportWrapperInstace(report.Columns_Name__c, ascrw, taskObj);
                            mapOfAutomateScoreCardReportWrapper.put(taskObj.id, ascrw);
                        }
                 
                      // Logic for related objects
                      if(report.Related_Object_Name__c != null  && report.Related_Object_Fields__c != null){
                        String relationshipIds = null;
                        for(String key : mapOfTaskIDAndOAID.keySet()){
                            if(relationshipIds == null){
                              relationshipIds = '\'' + mapOfTaskIDAndOAID.get(key) + '\'';
                            }
                            else{
                              relationshipIds = relationshipIds + ',\'' + mapOfTaskIDAndOAID.get(key) + '\'';
                            }
                        }
                        columnStr = ascr.createColumnStrFromFieldAndSeq(report.Related_Object_Fields__c);
                        sql = 'Select ' + columnStr + ' from ' + report.Related_Object_Name__c + ' where id in (' + relationshipIds + ')';
                        List<sObject> relatedObjectList = Database.query(sql);

                    for(sObject oaObj : relatedObjectList){
                          String taskID = null;
                            for(String key: mapOfTaskIDAndOAID.keySet()){
                              if(oaObj.get('id') == mapOfTaskIDAndOAID.get(key)){
                                taskID = key;
                                AutomateScoreCardReportWrapper ascrw = mapOfAutomateScoreCardReportWrapper.get(taskID);
                            
                             ascrw = ascr.updateAutomateScoreCardReportWrapperInstace(report.Related_Object_Fields__c, ascrw, oaObj);
                             mapOfAutomateScoreCardReportWrapper.put(taskID, ascrw);
                              }
                            }                
                        }
                    }

                  ascr.sendMail(mapOfAutomateScoreCardReportWrapper, report.Filters__c, report.Distribution_List__c, report.MasterLabel);
                  }
              }

        public String createColumnStrFromFieldAndSeq(String columnStr){
          
                      List<String> listOfRelatedFields = new List<String>();

                      columnStr = columnStr.replace(' ', '');
                      //use trim logic
                      listOfRelatedFields = columnStr.split(',');
                      columnStr = null;

                      for (String fieldName : listOfRelatedFields){
                        if(columnStr == null){
                        columnStr = fieldName.substringBefore(':');
                        } else {
                          columnStr = columnStr + ',' + fieldName.substringBefore(':');
                        }
                      }

            return columnStr;
        }

            // Logic to get label name of Object fields
       public String getLabelFromFieldAPI(String objName, String fieldName){
            
            String fieldLabel = null;
            String[] types = new String[]{objName};
          Schema.DescribeSObjectResult[] results = Schema.describeSObjects(types);
          for(Schema.DescribeSobjectResult res : results){
            Map<String, Schema.SObjectField> FsMap = res.fields.getMap();
             
                    if(fieldName.contains('.')){
                      fieldLabel = fieldName;
                    } 
                    else {
                      fieldLabel = FsMap.get(fieldName).getDescribe().getLabel();
                    }
          }
          return fieldLabel;
       }

            public AutomateScoreCardReportWrapper updateAutomateScoreCardReportWrapperInstace(String columnStr, AutomateScoreCardReportWrapper ascrw, sObject obj){
              
              String fieldValue = null;
              List<String> listOfRelatedFields = new List<String>();

              columnStr = columnStr.replace(' ', '');
              //use trim logic
              listOfRelatedFields = columnStr.split(',');
              
              AutomateScoreCardReport ascr = new AutomateScoreCardReport();
              String objType = String.valueOf(obj.getSobjectType());
              
              if(ascrw == null) {
                  ascrw = new AutomateScoreCardReportWrapper();
              }

              for (String fieldName : listOfRelatedFields){
                
                Integer seq = Integer.valueOf(fieldName.substringAfter(':'));   
                fieldName = fieldName.substringBefore(':');

                Integer count  = fieldName.countMatches('.');
                  if(count == 2){
                    if(obj.getSObject(fieldName.substringBefore('.')) != null && obj.getSObject(fieldName.substringBefore('.')).getSObject(fieldName.substringBetween('.', '.')) != null)
                    fieldValue = String.valueOf(obj.getSObject(fieldName.substringBefore('.')).getSObject(fieldName.substringBetween('.', '.')).get(fieldName.substringAfterLast('.')));
                  } else if(count == 1){
                      if(obj.getSObject(fieldName.substringBefore('.')) != null)
                      fieldValue = String.valueOf(obj.getSObject(fieldName.substringBefore('.')).get(fieldName.substringAfterLast('.')));
                  } else {
                    fieldValue = String.valueOf(obj.get(fieldName));
                  }
                  String fieldLabel = ascr.getLabelFromFieldAPI(objType, fieldName);
                      ascrw = ascrw.addField(ascrw, fieldName, fieldValue, fieldLabel, seq);
              }
              return ascrw;
            }

            public String dateRangeCondCreation(String dateRangeFieldAPI, String objectName, String dateRange, DateTime startDate, DateTime endDate){
              String dateRangeCond = null;
              String fieldAPI = '';
              DateTime dt = DateTime.now();
              String dtStr = dt.format('YYYY-MM-dd');
              if(dateRangeFieldAPI != null){

                      // Know the date range field API is of Date or DateTime type
                        String[] types = new String[]{objectName};
                        Schema.DescribeSObjectResult[] results = Schema.describeSObjects(types);
                        Map<String, Schema.SObjectField> M = results[0] .fields.getMap();
                        Schema.SObjectField field = M.get(dateRangeFieldAPI);
                        Schema.DisplayType fldType = field.getDescribe().getType();
                        
                        if(fldType == Schema.DisplayType.DATE){
                          // Date type field 
                          fieldAPI = dateRangeFieldAPI;
                        } else if(fldType == Schema.DisplayType.DATETIME){
                          fieldAPI = 'DAY_ONLY(' + dateRangeFieldAPI + ')';
                        }

                        
                        
                          if(dateRange == 'Specific Date Range'){
                                if(startDate != null && endDate != null){
                                    dateRangeCond = fieldAPI + ' >= ' + startDate.format('YYYY-MM-dd') + ' and ' + fieldAPI + ' < ' + endDate.format('YYYY-MM-dd');
                                }
                          } else if(dateRange == 'Today'){
                                DateTime nextDay = dt.addDays(1);
                                dateRangeCond = fieldAPI + ' >= ' + dtStr + ' and ' + fieldAPI + ' < ' + nextDay.format('YYYY-MM-dd');
                          } else if(dateRange == 'Every Week'){
                                DateTime lastWeek = dt.addDays(-7);
                                dateRangeCond = fieldAPI + ' >= ' + lastWeek.format('YYYY-MM-dd') + ' and ' + fieldAPI + ' < ' + dtStr;
                          } else if(dateRange == 'Every Month'){
                                DateTime lastMonth = dt.addMonths(-1);
                                dateRangeCond = fieldAPI + ' >= ' + lastMonth.format('YYYY-MM-dd') + ' and ' + fieldAPI + ' < ' + dtStr;
                          } else if(dateRange == 'Every Year'){
                                DateTime lastYear = dt.addYears(-1);
                                dateRangeCond = fieldAPI+ ' >= ' + lastYear.format('YYYY-MM-dd') + ' and ' + fieldAPI + ' < ' + dtStr;
                          }
                    }
                  return dateRangeCond;
            }

              // Mailing functionality
             public void sendMail(Map<String, AutomateScoreCardReportWrapper> mapOfAutomateScoreCardReportWrapper, String filters, String distributionList, String reportName){
                
                AutomateScoreCardReport ascr = new AutomateScoreCardReport();
                Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
                distributionList = distributionList.replace(' ', '');
                List<String> toAddress = distributionList.split(',');
                Datetime dt = DateTime.now();
                String formattedDate = dt.format('MM/dd/YYYY hh:mm a');
                String subject =' Report: ' +reportName+' run at ' + formattedDate;
                email.setSubject(subject);
                email.setToAddresses( toAddress );
                email.setHtmlBody(ascr.getTableEmailBody(mapOfAutomateScoreCardReportWrapper, filters, formattedDate, reportName));
                Messaging.SendEmailResult [] rms = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

             }

             public string getTableEmailBody(Map<String, AutomateScoreCardReportWrapper> mapOfAutomateScoreCardReportWrapper, String filters, String formattedDate, String reportName){
              String htmlBody = '';
              htmlBody = '<b><u>' +reportName+ '</u></b><br/><br/>';

              filters = filters.replace('!=', ' not equals to ');
              filters = filters.replace('<>', ' not equals to ');
              filters = filters.replace('=', ' equals to ');
              filters = filters.replace('>', ' greater than ');
              filters = filters.replace('<', ' less than ');
              filters = filters.replace('>=', ' greater than or equal to ');
              filters = filters.replace('<=', ' less than or equal to ');
              filters = filters.replace('\'', '');
              filters = filters.replace('__c', '');
              filters = filters.replace('__C', '');
              filters = filters.replace('__r', '');
              filters = filters.replace('__R', '');
              filters = filters.replace('_', ' ');
              filters = filters.replace('And', '<br/> &emsp;And');
              filters = filters.replace('and', '<br/> &emsp;And');
              String filterToPrint = null;
              if(filters.containsIgnoreCase('What.Type')){
                List<String> filterList = filters.split('And');
                
                 for(string filter: filterList){
                    if(!filter.contains('What.Type')){
                      if(filterToPrint == null){
                        filterToPrint = filter;
                      } else {
                        filterToPrint = filterToPrint + 'And' + filter;
                      }
                    }
                  }
              } else {
                filterToPrint = filters;
              }

              
              htmlBody += 'Run as : System<br/>';
              htmlBody += 'Run at : '+ formattedDate + '<br/><br/>';
              htmlBody += 'Filtered By:<br/>&emsp;' + filterToPrint + '<br/><br/>';
           
         
              //open table..
              htmlBody += '<table border="0" cellpadding="8">';

              htmlBody += '<tr>';

              List<Integer> keyList = new List<Integer>();

              for(String key : mapOfAutomateScoreCardReportWrapper.keySet()){
                  
                  AutomateScoreCardReportWrapper o = mapOfAutomateScoreCardReportWrapper.get(key);

                  keyList.addAll(o.fieldList.keySet());
                  keyList.sort();

                  for(Integer key1 : keyList){

                    AutomateScoreCardReportWrapper.FieldWrapper fw = o.fieldList.get(key1);
                    if(fw.fieldAPI == 'ActivityDate' ){
                      fw.fieldLabel = 'Due Time';
                    }
                    if(fw.fieldAPI == 'WhatId'){
                      continue;
                    }
                    String field = fw.fieldLabel;
                    field = field.replace('__c', '');
                    field = field.replace('__C', '');
                    field = field.replace('__r', '');
                    field = field.replace('__R', '');
                    field = field.replace('_', ' ');
                    field = field.replace('.', ':');

                    if(field.equalsIgnoreCase('Associated Opportunity:associated account target category')){
                      field  = 'Associated Opportunity:Historical CAT';
                    }

                    if(field.equalsIgnoreCase('Associated Opportunity:StageName')){
                      field  = 'Associated Opportunity:Sales Stage';
                    }

                    if(field.equalsIgnoreCase('Owner:Name')){
                      field  = 'Assigned To: Full Name';
                    }

                    htmlBody += '<th bgcolor="#E6E6FA" style="FONT-FAMILY: arial; FONT-SIZE: 10px;"><font size=+1 align="center">' + field + '</font></th>';
                  }
                  break;
              }

              htmlBody += '</tr>';

              //iterate over list and output columns/data into table rows...
              for(String key : mapOfAutomateScoreCardReportWrapper.keySet()){
                  
                  AutomateScoreCardReportWrapper o = mapOfAutomateScoreCardReportWrapper.get(key);

                  htmlBody += '<tr tyle="FONT-FAMILY: arial; FONT-SIZE: 11px;">';

                  for(Integer key1 : keyList){
                    AutomateScoreCardReportWrapper.FieldWrapper fw = o.fieldList.get(key1);
                    if(fw.fieldAPI == 'ActivityDate'){
                      String strDate = String.valueOf(fw.fieldValue);
                      if(strDate != null){
                        DateTime dt = Datetime.valueOf(strDate);
                        formattedDate = dt.format('hh:mm a');
                        fw.fieldValue = formattedDate;
                      } else {
                        fw.fieldValue = '--';
                      }
                    }

                    if(fw.fieldAPI == 'WhatId'){
                      continue;
                    }
                  //  String fieldVal = fw.fieldValue;
                    htmlBody += '<td align="center">' + fw.fieldValue + '</td>';
                  }
                  htmlBody += '</tr>';

              }
              //close table...
              htmlBody += '</table>';
              return htmlBody;

          }

            }