public class L2Q_GridRecordList {

    public class FieldArray {
        public String fieldapiName;
		public String fieldapiValue;
		public String fieldType;
		public Boolean isrequired;
    }

    public String recordId;
    public String uniqueKey;
    public string requestedcapacity; //Rajesh  SFDC-7368
    public string approvedcapacity ; //Rajesh SFDC-7368
    public List<FieldArray> fieldArray;
    public L2Q_GridRecordList(){}

}