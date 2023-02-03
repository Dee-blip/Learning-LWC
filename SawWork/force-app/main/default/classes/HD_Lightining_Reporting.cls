/*
	 *
	 *Template: Apex Class
	 *Version: 1.0
	 *@author: Nikhil Karn @ Akamai Technologies Ltd.
	 *Created Date : 30th May, 2018
	 *Purpose : This is apex class holds all the backend logic for HD Lightining Reporting App.
	 *Name Of methods: getQuery,sendMails,getContent,genrateFileReport,validateUser
	 *Number Of methods: 5
	 *Test Class Associated : HD_Test_Lightining_Reporting
	 *Controller (Boolean): False
	 *Page Used/Associated (default -> NONE) : NONE
	 *Trigger Associated : [  ]
	 *Class used : 
	 *@Last Modified By: shashank hegade
	 * Modification Log ===============================================================
	 * Date               Author               Modification
	 * Nov 29th, 2021     Aneesh Budnar        PRTORES-2358 - HD Code Scanner 1 fixes
	 */

public with sharing class HD_Lightining_Reporting {


	static String fromAddress;
	static String fromName;
	static String subject;
	static String serviceRequestTitle;
	static List<BMCServiceDesk__SRM_RequestDetailInputs__c> requestDetailInputs = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
	static String fileData='';
	static Set<String> notAllowedcategoriesSet=new Set<String>();
	static String errorMessage;
	static boolean hasError;
	static String coulmn;
	static List<String> reportList=new List<String>();
	static Integer coulmnValueLength=25;



	static String requestDefinationQuery='SELECT Id,Name,BMCServiceDesk__Description__c,BMCServiceDesk__serviceRequestTitle__c,BMCServiceDesk__FKCategory__r.name,BMCServiceDesk__Inactive__c from BMCServiceDesk__SRM_RequestDefinition__c WHERE BMCServiceDesk__Online__c =true ORDER BY Name'; 
	static String statusQuery='select Id,Name from BMCserviceDesk__status__c WHERE BMCServiceDesk__appliesToIncident__c = true ORDER BY Name';
	static List<BMCServiceDesk__SRM_RequestDefinition__c>  serviceRequestsList;


	@AuraEnabled
	public static List<BMCServiceDesk__SRM_RequestDefinition__c> getListOfActiveServiceRequest(){
		serviceRequestsList=database.query(requestDefinationQuery);
		return serviceRequestsList;
	}

	@AuraEnabled
	public static List<BMCserviceDesk__status__c> getListOfStatus(){
		List<BMCserviceDesk__status__c>  statusList=database.query(statusQuery);
		return statusList;
	}


	/*
	 *@author:Nikhil Karn
	 *@created date: 30th May, 2018
	 *@details: implemented method for interface Messaging.InboundEmailHandler
	 *@Last Modified By:
	 *@Last Modified Date:
	 *@Last Modified Reason:
	 *
	 */

	@AuraEnabled
	public static List<String> getServiceRequestReport(List<Id> requestDefinationsList, List<Id> selectedStatus, String fromDate, String toDate){

		String whereClause='BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKRequestDefinition__r.Id IN :requestDefinationsList';
		if(selectedStatus==null||selectedStatus.isEmpty()){

		}else{
			whereClause+=' AND BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKStatus__r.Id IN :selectedStatus' ;
		}

		String query= getQuery(whereClause,fromDate,toDate);
		requestDetailInputs=Database.query(query);
		System.debug('INDISDE getServiceRequestReport requestDetailInputs:'+requestDetailInputs);
		//getApprovalStatus();
		if(!requestDetailInputs.isEmpty()){
			return getContent();
		}else{
			//HANDLE ERROR HERE
			return new List<String>();
		}
	}


	/*
	 *@author:Nikhil Karn
	 *@created date: 30th May, 2018
	 *@details: resposible to genrate dynamic query
	 *@Last Modified By:
	 *@Last Modified Date:
	 *@Last Modified Reason:
	 *
	 */
	@TestVisible private static String getQuery(String whereClause, String fromDate,String toDate){

		/*String customQuery='';

		try{
			HD_Reporting_Fields__mdt  customFields = [SELECT Id,Query__c FROM HD_Reporting_Fields__mdt LIMIT 1];
			if(customFields!=null){
				customQuery=customFields.Query__c;
			}
		}catch(Exception e){

		}
		String query=null;
		Integer finalLimit=200;
		fromDate+='T00:00:00.000+0000';
		toDate+='T00:00:00.000+0000';
		query='SELECT '+customQuery+', BMCServiceDesk__Input__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Name,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Owner_user_queue__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Opened_Date_For__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKRequestDefinition__r.BMCServiceDesk__serviceRequestTitle__c, BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Category_ID__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.SI_Created_Date_International_format__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKStatus__r.name,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Client_Name__c, BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Launch_Console__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Approval_Status__c, BMCServiceDesk__Response__c, HD_Incident_id__c FROM BMCServiceDesk__SRM_RequestDetailInputs__c WHERE  '+whereClause+' AND CreatedDate <='+toDate+' AND CreatedDate >='+fromDate+' ORDER BY HD_Incident_id__c LIMIT 30000';// added a new column, shashank hegade, 16-11-2018*/
		string query = generateTheQuery(whereClause,fromDate,toDate);
		System.debug(query);
		return query;
	}

    /*
    *@author: Shashank hegade
    */

    @TestVisible private static string generateTheQuery(string whereClause, string fromDate,string toDate){
    	string customQuery = 'SELECT ';

    	List<Schema.FieldSetMember> reportingFields = SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_Reporting_app_fields.getFields();
        System.debug(reportingFields);

        for (Schema.FieldSetMember field: reportingFields){
        	customQuery += 'BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.' + String.escapeSingleQuotes(field.getFieldPath()) + ', ';  //cs-fix PRTORES-1581 shegade

        }

        fromDate+='T00:00:00.000+0000';
		toDate+='T00:00:00.000+0000';
        customQuery += 'BMCServiceDesk__Input__c,BMCServiceDesk__Response__c,HD_Incident_id__c FROM BMCServiceDesk__SRM_RequestDetailInputs__c WHERE ' + whereClause + ' AND CreatedDate <='+ toDate +' AND CreatedDate >='+ fromDate +' ORDER BY HD_Incident_id__c LIMIT 30000';
        return customQuery;

    }
	/*@TestVisible private static void getApprovalStatus () {
      
      Set<Id> serviceIncidentsList = new Set<Id>();
      for ( BMCServiceDesk__SRM_RequestDetailInputs__c reqDetail: requestDetailInputs){ //
      	serviceIncidentsList.add(reqDetail.HD_Incident_id__c);
      }
      system.debug('serviceIncidentsList >>>' + serviceIncidentsList);
      List<ProcessInstance> approvalStatusList = new List<ProcessInstance>();
      approvalStatusList = [ SELECT Id, Status, TargetObjectId FROM ProcessInstance WHERE TargetObjectId IN :serviceIncidentsList ];
      System.debug('object >>> ' + approvalStatusList); //debug
      
      Map<Id,string> idToStatusMap = new Map<Id,string>();
      for( ProcessInstance procInst: approvalStatusList ){
      	if(procInst.Status != null){
      	idToStatusMap.put(procInst.TargetObjectId,procInst.Status);
      }
      }

      for ( BMCServiceDesk__SRM_RequestDetailInputs__c reqDetail : requestDetailInputs ){
      		if(reqDetail.HD_Incident_id__c != null){
      		reqDetail.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Approval_Status__c = idToStatusMap.get(reqDetail.HD_Incident_id__c);
      	}
      }
      System.debug('getApprovalStatus');
	}*/

	/*
	 *@author:Nikhil Karn
	 *@created date: 30th May, 2018
	 *@details: This method is responsible to create email body content for report as well as create csv file with detailed data
	 *@Last Modified By:
	 *@Last Modified Date:
	 *@Last Modified Reason:
	 *
	 */
	@TestVisible private static List<String> getContent(){

		String parsedLaunchConsole=null;
		Integer counter=1;
		Set<String> inputPromptSet=new Set<String>();
		inputPromptSet.add('HD_Incident_id__c');
		String[] inputPromptList=new String[100];
		Set<String> incidentId=new Set<String>();
		String inputName;

		String tempContent = '<table class="slds-table slds-table_bordered slds-table_cell-buffer slds-table_striped">';
		tempContent+='<thead>';
		tempContent+='<tr class="slds-text-heading--label">';

		tempContent+='<th class="{!col.cssClass}" title="S. No.">S. No.</th>';
		tempContent+='<th class="{!col.cssClass}" title="Service Request">Service Request</th>';
		tempContent+='<th class="{!col.cssClass}" title="Status">Status</th>';
		tempContent+='<th class="{!col.cssClass}" title="Created Date">Created Date</th>';
		tempContent+='<th class="{!col.cssClass}" title="Category">Category</th>';
		tempContent+='<th class="{!col.cssClass}" title="Approval Status">Approval Status</th>'; //shashank hegade
		tempContent+='<th class="{!col.cssClass}" title="Client Name">Client Name</th>';
		tempContent+='<th class="{!col.cssClass}" title="Launch Console">Launch Console</th>';

		fileData='S. No.,Service Request,Incident Number,Owner,Opened Date,Status,Created Date,Category,Approval Status,Client Name';
		Integer tempCounter=0;

		for(BMCServiceDesk__SRM_RequestDetailInputs__c requestDetailInput:requestDetailInputs){
			if(inputPromptSet.contains(requestDetailInput.BMCServiceDesk__Input__c) || requestDetailInput.BMCServiceDesk__Response__c=='header section' ){
				continue;
			}else{
				String title=requestDetailInput.BMCServiceDesk__Input__c;
				String displayValue=title.abbreviate(coulmnValueLength);
				tempContent +='<th class="{!col.cssClass}" title="'+title+'">'+displayValue+'</th>';
				fileData+=','+requestDetailInput.BMCServiceDesk__Input__c.replace(',',' ');
				inputPromptList[tempCounter]=requestDetailInput.BMCServiceDesk__Input__c;
				tempCounter++;
				inputPromptSet.add(requestDetailInput.BMCServiceDesk__Input__c);
			}
		}

		String incId='test';
		String inputPrompt;
		Integer temp;
		String[] tempInputPromptResponseList;
		List<String> responseList=new List<String>();
		List<String> responseListCSV=new List<String>();
		Integer tempCounter1=0;

		for(BMCServiceDesk__SRM_RequestDetailInputs__c requestDetailInput:requestDetailInputs){//for each requestDetailInputs

			if(requestDetailInput.BMCServiceDesk__Response__c=='header section'){
				continue;
			}
			if(requestDetailInput.HD_Incident_id__c!=incId){//first check if in

				if(tempInputPromptResponseList!=null){

					String tempVal='';
					String tempValCsv='';
					for(Integer i=0;i<inputPromptSet.size()-1;i++){
						if(tempInputPromptResponseList[i]==null){
							tempInputPromptResponseList[i]='-';
						}
						tempInputPromptResponseList[i]=tempInputPromptResponseList[i].replace(',',' ');
						tempInputPromptResponseList[i]=tempInputPromptResponseList[i].replace('\n',' ');
						tempValCsv+=','+tempInputPromptResponseList[i];

						String title=tempInputPromptResponseList[i];
						String displayValue=title.abbreviate(coulmnValueLength);
						tempVal +='<td class="{!col.cssClass}" title="'+title+'">'+displayValue+'</td>';					

						tempCounter1++;
					}
					responseListCSV.add(tempValCsv);
					responseList.add(tempVal);
				}
				incId=requestDetailInput.HD_Incident_id__c;
				tempInputPromptResponseList=new String[100];
				inputPrompt=requestDetailInput.BMCServiceDesk__Input__c;
				temp=inputPromptList.indexOf(inputPrompt);
				tempInputPromptResponseList[temp]=requestDetailInput.BMCServiceDesk__Response__c;

			}else{
				inputPrompt=requestDetailInput.BMCServiceDesk__Input__c;
				temp=inputPromptList.indexOf(inputPrompt);
				tempInputPromptResponseList[temp]=requestDetailInput.BMCServiceDesk__Response__c;
			}
		}
		if(tempInputPromptResponseList!=null){
			String tempVal='';
			String tempValCsv='';

			for(Integer i=0;i<inputPromptSet.size()-1;i++){
				if(tempInputPromptResponseList[i]==null){
					tempInputPromptResponseList[i]='-';
				}
				tempValCsv+=','+tempInputPromptResponseList[i];
				String title=tempInputPromptResponseList[i];
				String displayValue=title.abbreviate(coulmnValueLength);
				tempVal +='<td class="{!col.cssClass}" title="'+title+'">'+displayValue+'</td>';									
			}

			responseListCSV.add(tempValCsv);
			responseList.add(tempVal);

		}
		tempContent+='</tr></thead><tbody>';
		fileData+=' \n';
		Integer tempCount=0;
		Set<String> tempSet=new Set<String>();

		for(BMCServiceDesk__SRM_RequestDetailInputs__c requestDetailInput:requestDetailInputs){
			String tempVariable='';
			if(tempSet.contains(requestDetailInput.HD_Incident_id__c) || requestDetailInput.BMCServiceDesk__Response__c=='header section' ){
				continue;
			}else{
				tempSet.add(requestDetailInput.HD_Incident_id__c);
				try{
					parsedLaunchConsole=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Launch_Console__c.replace('<a href="','<a href="'+URL.getSalesforceBaseURL().toExternalForm());
				}catch(Exception e){
					parsedLaunchConsole='-';
				}

				tempContent+='<tr class="slds-hint-parent">';
				tempContent+='<td class="{!col.cssClass}" title="'+counter+'">'+counter+'</td>';


				//String title=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKRequestDefinition__r.BMCServiceDesk__serviceRequestTitle__c;
				String title=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Service_Request_Title__c;

				String displayValue=(title!=null?title.abbreviate(coulmnValueLength):'-');
				tempContent +='<td class="{!col.cssClass}" title="'+title+'">'+displayValue+'</td>';					

				//title=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKStatus__r.name; //shashank hegade
				title=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Status_ID__c;
				displayValue=(title!=null?title.abbreviate(coulmnValueLength):'-');
				tempContent +='<td class="{!col.cssClass}" title="'+title+'">'+displayValue+'</td>';

				title=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.SI_Created_Date_International_format__c;
				displayValue=(title!=null?title.abbreviate(coulmnValueLength):'-');
				tempContent +='<td class="{!col.cssClass}" title="'+title+'">'+displayValue+'</td>';

				title=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Category_ID__c;
				displayValue=(title!=null?title.abbreviate(coulmnValueLength):'-');
				tempContent +='<td class="{!col.cssClass}" title="'+title+'">'+displayValue+'</td>';

				title=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Approval_Status__c;
				displayValue=(title!=null?title.abbreviate(coulmnValueLength):'-');
				tempContent +='<td class="{!col.cssClass}" title="'+title+'">'+displayValue+'</td>';

				title=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Client_Name__c;
				displayValue=(title!=null?title.abbreviate(coulmnValueLength):'-');
				tempContent +='<td class="{!col.cssClass}" title="'+title+'">'+displayValue+'</td>';

				title=parsedLaunchConsole;
				tempContent +='<td class="{!col.cssClass}">'+title+'</td>';

				tempContent+=responseList[tempCount];
				tempContent+='</tr>';


				//tempVariable=counter+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKRequestDefinition__r.BMCServiceDesk__serviceRequestTitle__c+','; //shashank hegade
				tempVariable=counter+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Service_Request_Title__c+',';
				//fileData+=counter+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKRequestDefinition__r.BMCServiceDesk__serviceRequestTitle__c+',';
				fileData+=counter+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Service_Request_Title__c+',';

				tempVariable+=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Name+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Owner_user_queue__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Opened_Date_For__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Status_ID__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.SI_Created_Date_International_format__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Category_ID__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Approval_Status__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Client_Name__c; // changed the status ID @shashank hegade
				fileData+=requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Name+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Owner_user_queue__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Opened_Date_For__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Status_ID__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.SI_Created_Date_International_format__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Category_ID__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Approval_Status__c+','+requestDetailInput.BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Client_Name__c;

				tempVariable+=responseListCSV[tempCount];
				fileData+=responseListCSV[tempCount];

				fileData+='\n';
				tempCount++;

				counter++;
			}
		}
		tempContent += '</tbody></table>';
		fileData+='\n';
		fileData = fileData.replace('null','-'); // to eliminate the null valuse in the report @shahsank hegade
		reportList.add(tempContent);
		reportList.add(fileData);
		return reportList;
	}

	/*
	 *@author:Nikhil Karn
	 *@created date: 30th May, 2018
	 *@details: This method is responsible to convert json data to csv file and attach it into the email
	 *@Last Modified By:
	 *@Last Modified Date:
	 *@Last Modified Reason:
	 *
	 */
	@TestVisible private static Messaging.EmailFileAttachment genrateFileReport(){

		Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
		fileData = fileData.replace('null','-');
		System.debug('fileData');
		blob csvBlob = Blob.valueOf(fileData);
		string csvname= 'ServiceRequestReport.csv';
		csvAttc.setFileName(csvname);
		csvAttc.setBody(csvBlob);
		return csvAttc;
	}
	/*
	 *@author:Nikhil Karn
	 *@created date: 30th May, 2018
	 *@details: This method is to test all the above Methods
	 *@Last Modified By:
	 *@Last Modified Date:
	 *@Last Modified Reason:
	 *
	 */
	@TestVisible private static void testHelp(List<BMCServiceDesk__SRM_RequestDetailInputs__c> reqDetailInputs){
		requestDetailInputs=reqDetailInputs;
		getContent();
		genrateFileReport();
	}
}