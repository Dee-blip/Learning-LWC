// Created by Mayank Bansal as part of SFDC-3447
// Test Class: ChannelMappingCronJobTest
public class ChannelMappingCronJob {

  public Map<String,String> mdtRecordMap = new Map<String,String>();

  public ChannelMappingCronJob(){
    System.debug('Mayank, ChannelMappingCronJob execution started.');
    mdtRecordMap = GSMUtilClass.getGSMSettingValuePartialMatchMap('ChannelMappingCronJob');
  }

  public Integer executeCronJob(){

    String innerQuery = null;
    String outerQuery = null;
    string emailList = null;
    Map<String,String> fieldApiToLabel = new Map<String,String>();
    List<Sobject> accList = new List<Sobject>();
    For(String key: mdtRecordMap.keySet()){
      if(key.contains('ChannelMappingCronJobInnerQuery')){
        innerQuery = mdtRecordMap.get(key);
      } else if(key.contains('ChannelMappingCronJobEmailList')){
        emailList = mdtRecordMap.get(key);
      } else if(key.contains('ChannelMappingCronJobOuterQuery')){
        outerQuery = mdtRecordMap.get(key);
      }
    }
    if(innerQuery != null && outerQuery != null){
      outerQuery = outerQuery + ' (' + innerQuery + ')';
    }
    if(outerQuery != null){
      accList = Database.query(outerQuery);
      if(accList.size() > 0){
        String fields = outerQuery.substringBefore(' where');
        List<String> splitList = fields.split(' from ');
        fields = splitList.get(0);
        String objType = splitList.get(1);
        objType = objType.replaceAll(' ', '');
        fields = fields.removeStartIgnoreCase('Select');
        fields = fields.replace(' ', '');
        List<String> fieldList = fields.split(',');
        for(String field : fieldList){
          fieldApiToLabel.put(field, null);
        }
       fieldApiToLabel = getLabelBasedOnFieldApi(fieldApiToLabel, objType);
      
        Integer count=0;
        Map<Integer,List<String>> rowToData = new Map<Integer,List<String>>();
        List<String> labelList = new List<String>();
        List<String> columnData = new List<String>();
        Boolean check =false;
        for(Sobject acc: accList){
          count ++;
          columnData = new List<String>();
          for(String key : fieldApiToLabel.keySet()){
              columnData.add((String) acc.get(key));
            if(!check){
              labelList.add(fieldApiToLabel.get(key));
            }
          }
          check = true;
          rowToData.put(count, columnData);
        }
        sendMail(labelList,rowToData,emailList,'Channel Mapping Report');
        }
    }
    System.debug('Mayank, ChannelMappingCronJob execution ended.');
    return accList.size();
  }

  public static Map<string, String> getLabelBasedOnFieldApi(Map<String,String> fieldApiToLabel, String objType){
    
    String type=objType;
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType leadSchema = schemaMap.get(type);
    Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

    for (String fieldName: fieldMap.keySet()) {
      if(fieldApiToLabel.containsKey(fieldName)){
        fieldApiToLabel.put(fieldName, fieldMap.get(fieldName).getDescribe().getLabel());
      }
    }
    return fieldApiToLabel;
  }

  //formulate email body
  public static string getTableEmailBody(List<String> labelList,Map<Integer,List<String>> rowToData, String formattedDate, String reportName){
              String htmlBody = '';
              htmlBody = '<b><u>' +reportName+ '</u></b><br/><br/>';

              htmlBody += 'Run as : System<br/>';
              htmlBody += 'Run at : '+ formattedDate + ' GMT<br/><br/>';           
         
              //open table..
              htmlBody += '<table border="0" cellpadding="8">';
              
              htmlBody += '<tr>';

              //formulate table column labels
              for(String colLabel: labelList){
                if(colLabel.contains(' ID')){
                  colLabel = colLabel.replace('ID', 'URL');
                }
                htmlBody += '<th bgcolor="#E6E6FA" style="FONT-FAMILY: arial; FONT-SIZE: 10px;"><font size=+1 align="center">' + colLabel + '</font></th>';
              }

              htmlBody += '</tr>';

              //iterate over list and output columns/data into table rows...
              for(Integer key : rowToData.keySet()){
                  htmlBody += '<tr style="FONT-FAMILY: arial; FONT-SIZE: 11px;">';

                  for(String rowData : rowToData.get(key)){
                    if(rowData.startsWith('001')){
                      String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
                      baseUrl += '/'+rowData;
                      rowData = baseUrl;
                    }
                    htmlBody += '<td align="center">' + rowData + '</td>';
                  }
                  htmlBody += '</tr>';

              }
              //close table...
              htmlBody += '</table>';
              return htmlBody;

          }
    //send email
  public static void sendMail( List<String> labelList,Map<Integer,List<String>> rowToData, String distributionList, String reportName){
            
            //AutomateScoreCardReport ascr = new AutomateScoreCardReport();
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            distributionList = distributionList.replace(' ', '');
            List<String> toAddress = distributionList.split(',');
            Datetime dt = DateTime.now();
            String formattedDate = dt.format('MM/dd/YYYY hh:mm a');
            //SFDC-2421
            String subject =' Report: ' +reportName+' run at ' + formattedDate+' GMT';
            email.setSubject(subject);
            email.setToAddresses( toAddress );
            email.setHtmlBody(getTableEmailBody(labelList,rowToData, formattedDate, reportName));
            Messaging.SendEmailResult [] rms = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

     }
}