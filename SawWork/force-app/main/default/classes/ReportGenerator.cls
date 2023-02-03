/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    012/02/2018     Created this Class for SFDC-2315
    
*/
public class ReportGenerator {
		
	@future
	public static void generateReport(String reportId,String reportName,String distributionList){
		// Run a report synchronously
		Reports.reportResults results = Reports.ReportManager.runReport(reportId, true);
		// Get Report labels
		List<String> labelList = getreportLabels(results);
		//get Report Data
		Map<Integer,List<String>> rowToData =getReportData(results);
	    //get Report Filters
	    String filters= getReportFilters(results);
		sendMail(labelList,rowToData,filters,distributionList,reportName);
	}

	public static String getReportFilters(Reports.reportResults results){
			Reports.ReportMetadata rm = results.getReportMetadata();
		  	String filters='';
			for(Reports.ReportFilter rf : rm.getreportFilters()){
			      filters = filters+rf.getcolumn()+' '+rf.getOperator()+' '+rf.getValue()+'<br/>';
			}
		System.debug(LoggingLevel.ERROR,'filters:: '+filters);
		return filters;
	}
	//Get Reports Data
	public static Map<Integer,List<String>> getReportData(Reports.reportResults results){
		Map<Integer,List<String>> rowToData = new Map<Integer,List<String>>();
			  Reports.ReportFactWithDetails factWithDetails =
			           (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
			system.debug(LoggingLevel.ERROR,'getKey():: '+factWithDetails.getRows().size());
			Integer count=0;
			    for (Reports.ReportDetailRow row : factWithDetails.getRows()) {
			    	count ++;
			    	List<String> columnData = new List<String>();
			    	
			        for (Reports.ReportDataCell cell : row.getDataCells()) {
			            columnData.add(cell.getLabel());
			        }
			        rowToData.put(count,columnData);
			    }
	    System.debug(LoggingLevel.ERROR,'rowToData: '+rowToData);
	    return rowToData;
	}
	// Get Report labels
	public static List<String> getreportLabels(Reports.reportResults results){
		MAP<String,Reports.DetailColumn> colDetails = (MAP<String,Reports.DetailColumn>)results.getReportExtendedMetadata().getDetailColumnInfo();

		// Get the first summary amount from the fact map
		//Reports.SummaryValue sumVal = factDetails.getAggregates()[0];
		List<String> labelList = new List<String>();
		for(Reports.DetailColumn col: colDetails.values()){
			System.debug(LoggingLevel.ERROR,'colDetails: ' + col.getLabel());
			//String label = ;
			labelList.add(col.getLabel());
		}	
		return labelList;
	}
	//formulate email body
	public static string getTableEmailBody(List<String> labelList,Map<Integer,List<String>> rowToData,String filters, String formattedDate, String reportName){
              String htmlBody = '';
              htmlBody = '<b><u>' +reportName+ '</u></b><br/><br/>';

             filters = filters.replace('notEqual', 'not equals to');
              filters = filters.replace('__c', '');
              filters = filters.replace('__r', '');
              filters = filters.replace('_', ' ');
              filters = filters.replace('Activity.', '');
              
              //SFDC-2421
              htmlBody += 'Run as : System<br/>';
              htmlBody += 'Run at : '+ formattedDate + ' GMT<br/><br/>';
              htmlBody += 'Filtered By:<br/>' + filters + '<br/><br/>';
           
         
              //open table..
              htmlBody += '<table border="0" cellpadding="8">';
              
              htmlBody += '<tr>';

              //formulate table column labels
              for(String colLabel: labelList)
	              htmlBody += '<th bgcolor="#E6E6FA" style="FONT-FAMILY: arial; FONT-SIZE: 10px;"><font size=+1 align="center">' + colLabel + '</font></th>';

              htmlBody += '</tr>';

              //iterate over list and output columns/data into table rows...
              for(Integer key : rowToData.keySet()){
                  htmlBody += '<tr style="FONT-FAMILY: arial; FONT-SIZE: 11px;">';

                  for(String rowData : rowToData.get(key)){
                    htmlBody += '<td align="center">' + rowData + '</td>';
                  }
                  htmlBody += '</tr>';

              }
              //close table...
              htmlBody += '</table>';
              return htmlBody;

          }
          //send email
		public static void sendMail( List<String> labelList,Map<Integer,List<String>> rowToData,String filters, String distributionList, String reportName){
                
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
                email.setHtmlBody(getTableEmailBody(labelList,rowToData, filters, formattedDate, reportName));
                Messaging.SendEmailResult [] rms = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

            }
}