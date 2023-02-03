global class  CIResponseWrapperClass {
    webservice List<Sobject> objectRecords{get;set;}
	webservice String objectName{get;set;}
	webservice String status{get;set;}
	webservice String errorMessage{get;set;}
	webservice DateTime pollStartTime{get;set;}
	webservice DateTime pollEndTime{get;set;}
	webservice Boolean isCompleted{get;set;}
		
		public CIResponseWrapperClass()
		{
			
		}
		public CIResponseWrapperClass(String objectName,List<Sobject> objectRecords,String status, String errorMessage,DateTime pollStartTime, DateTime pollEndTime,Boolean isCompleted)
		{
			this.objectName=objectName;
			this.objectRecords=objectRecords;
			this.status=status;
			this.errorMessage=errorMessage;
			this.pollStartTime=pollStartTime;
			this.pollEndTime=pollEndTime;
			this.isCompleted=isCompleted;
		}
}